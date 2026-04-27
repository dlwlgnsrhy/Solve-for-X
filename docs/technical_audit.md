# SFX Apps Technical Audit Report

**Date:** 2026-04-27
**Scope:** Complete source code review of all 53 Dart files across 3 Flutter apps
**Framework:** Flutter 3.29.3, Dart 3.7.2, Riverpod, Clean Architecture, Dark Mode + Neon Theme

---

## App A: SFX Imjong Care (Digital Will Card Generator)

**Total files:** 20 Dart files
**File structure:**
```
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart          (EULA text, 5KB - massive inline legal text)
│   ├── services/app_storage.dart             (SharedPreferences wrapper, 110 lines)
│   └── theme/
│       ├── neon_colors.dart                  (Color constants, 53 lines)
│       ├── app_typography.dart               (16 TextStyle presets, 175 lines)
│       └── card_template.dart                (Enum extension: neon/sunset/ocean/aurora, 84 lines)
├── features/
│   ├── onboarding/presentation/screens/onboarding_screen.dart  (319 lines, sample cards carousel)
│   ├── will_input/
│   │   ├── domain/entities/will_card.dart              (Entity with ==/hashCode, 58 lines)
│   │   ├── domain/providers/will_form_provider.dart    (StateNotifier, 95 lines)
│   │   ├── domain/providers/card_template_provider.dart (StateNotifier, 69 lines - DUPLICATE)
│   │   ├── data/models/will_card_model.dart            (Model extends Entity, 31 lines - USELESS)
│   │   ├── data/repositories/will_card_storage.dart    (SharedPreferences repo, 58 lines)
│   │   └── presentation/
│   │       ├── screens/will_input_screen.dart          (618 lines - largest file)
│   │       └── widgets/
│   │           ├── value_input_field.dart              (NeonTextField, 149 lines)
│   │           └── eula_checkbox.dart                  (110 lines)
│   ├── will_card/
│   │   └── presentation/
│   │       ├── screens/will_card_screen.dart           (310 lines, 3D card + template switcher)
│   │       └── widgets/
│   │           ├── neon_3d_card.dart                   (325 lines, Matrix4 perspective)
│   │           ├── share_card_content.dart             (399 lines, 420x780px share image)
│   │           └── card_share_button.dart              (270 lines, screenshot + share)
│   └── card_history/
│       └── presentation/widgets/card_history_section.dart (429 lines, DismissList)
```

### Architecture: 6.5/10 - Clean Architecture naming but shallow implementation
- Follows feature-based folder structure (features/onboarding, features/will_input, features/will_card, features/card_history) with core/ for shared utilities
- Domain/data/presentation layering exists but is thin - there is no actual repository abstraction; `WillCardStorage` directly uses SharedPreferences
- `WillCardModel extends WillCard` is a pointless subclass - it adds zero persistence-specific logic (no JSON serialization, no additional fields). The `fromEntity()`/`toEntity()` methods just copy the same three fields. This is a **DRY violation** disguised as Clean Architecture
- `card_template_provider.dart` is a **complete duplicate** of `will_form_provider.dart` logic - `CardTemplateController` has `updateName`, `updateValue`, `updateWill`, `reset`, `isValid` - identical to `WillFormController`. But it's NEVER used in the actual `WillInputScreen` which uses `willFormControllerProvider` instead. **Dead code**
- `AppConstants` contains the entire EULA as a 57-line multi-line string constant. This should be a separate file or fetched remotely
- No error types, no use-case layer, no dependency injection framework (relies on constructor defaults)
- `SharedPreferences.getInstance()` is called on every single method in `AppStorage` and `WillCardStorage` - no singleton caching. At 110+ calls across app lifetime, this is wasteful

### Code Quality: 5.5/10 - Several DRY violations and code duplication
- **Critical DRY violation:** `card_template_provider.dart` duplicates 90% of `will_form_provider.dart` (`WillFormController` vs `CardTemplateController`). Both have `updateName`, `updateValue(int, String)`, `updateWill`, `reset`, `isValid`. The CardTemplateController is **never referenced** in the input screen
- **CRITICAL BUG - `_deleteCard` clears ALL history:**
  ```dart
  // card_history_section.dart:95
  void _deleteCard(int index) {
      AppStorage.clearCardHistory();  // DELETES EVERYTHING, index is ignored!
  }
  ```
  User swipes to delete ONE card and loses their entire history
- **`WillCard.fromMap` crash risk:**
  ```dart
  factory WillCard.fromMap(Map<String, dynamic> map) {
      return WillCard(
        name: map['name'] as String,       // Crashes if 'name' is null
        values: List<String>.from(map['values'] as List), // Crashes if 'values' missing
        will: map['will'] as String,       // Crashes if 'will' is null
      );
  }
  ```
  Used in `card_history_section.dart:76-79` - any corrupted JSON entry crashes the app
- Hardcoded magic values: `NeonTextField` has 3 fixed values (VALUE 1/2/3) but the card supports exactly 3. The number `3` is hardcoded throughout but not parameterized
- `_NeonTextFieldState` maintains `_currentLength` state AND the parent controller tracks text - redundant state management causing double `setState` calls on every keystroke
- `EulaCheckbox` uses local `setState` state instead of Riverpod - breaks state management consistency
- `app_storage.dart:76` does `template.name.split('/')[0].trim()` to extract enum name from display string - fragile string parsing instead of storing the enum value directly

### UX/UI: 8/10 - Polished neon aesthetic, good flow
- 4 template styles (Neon, Sunset, Ocean, Aurora) with unique color schemes, gradients, and shadow effects
- Onboarding screen has staggered fade-in animations with animated sample card carousel
- 3D perspective card using `Matrix4.identity()..setEntry(3, 2, 0.004)..rotateX(-0.08)..rotateY(0.08)`
- Share image is 420x780px at 3x pixel ratio (1260x2340) - Instagram-optimized
- Card history with DismissList swipe-to-delete (visual feedback) and mini thumbnail previews
- `NeonTextField` has animated border glow with `BoxShadow` per template color
- Generate button has gradient transition from green to grey based on form validity
- **Missing:** No pull-to-refresh on history, no haptic feedback on card generation, no loading skeleton for history, card text overflow not handled on the 3D card (long names/values overflow the 310px card)
- **Issue:** The share card uses fixed 420x780 dimensions but the on-screen card is 310x520 - users see different sizes

### State Management: 6/10 - Riverpod used correctly in some places, inconsistently in others
- `WillFormController` uses `StateNotifierProvider` correctly with auto-save on every field change
- **Performance issue:** `_autoSave()` fires on EVERY keystroke, calling `SharedPreferences.setInt`/`setString` - this is a synchronous disk write throttled by async. Users typing fast trigger a cascade of disk I/O operations:
  ```dart
  void updateName(String value) {
    state = state.copyWith(name: value);
    _autoSave();  // Fires on every character typed
  }
  ```
- `CardTemplateControllerProvider` exists but is a separate provider duplicating form state - the `WillInputScreen` reads from BOTH `willFormControllerProvider` (for values) and `cardTemplateControllerProvider` (for template selection). These two providers are **never synchronized**, meaning the form data exists in two disconnected state trees
- `EulaCheckbox` uses local `setState` instead of Riverpod, breaking the reactive chain
- `_AppRoot` uses `FutureBuilder` instead of Riverpod for onboarding check - inconsistent
- `CardHistorySection` uses `FutureBuilder` to load history - correct but refreshes only on rebuild, not reactively

### Performance: 5/10 - Multiple widget rebuild issues and excessive I/O
- **SharedPreferences I/O storm:** `WillFormController._autoSave()` triggers on every keystroke. With name (up to 20 chars) + 3 values (up to 30 chars each) + will (up to 80 chars), a single card creation can trigger 140+ disk writes. `AppStorage.addToCardHistory` does 2 more. Total: 150+ SharedPreferences writes per card
- **Memory leak risk:** `_SampleCardState` creates `AnimationController` that `repeat(reverse: true)` forever. These run on the onboarding screen and are properly disposed, but if the user navigates away and back, new controllers are created
- `Neon3DWillCard` rebuilds on every template change - the entire card content is a widget tree with 20+ `flutter_animate` chains. The animations play on every rebuild
- `CardHistorySection` fetches history on every `build()` via `FutureBuilder` - no caching. Every screen repaint re-fetches from SharedPreferences
- `_CardHistoryThumbnailState` creates `AnimationController` with `repeat(reverse: true)` for hover effect on each thumbnail. With up to 10 history items, that's 10 continuous animation loops
- The share flow creates a `ScreenshotController`, renders `ShareCardContent` off-screen, captures at 3x, writes to temp file, then shares - memory intensive for lower-end devices

### Security: 7/10 - Local-only app, reasonable data handling
- No network calls, no server, no data exfiltration - user data stays on device
- SharedPreferences stores card history in plain text (name, values, will) - not encrypted. On a rooted device, this data is trivially extractable
- No biometric authentication for sensitive data
- EULA checkbox is not persisted - user can navigate away and EULA agreement is lost (it's only in local widget state, not saved to prefs)
- No rate limiting on card generation - could be abused for spam sharing
- `getTemporaryDirectory()` used for share files - these persist until app is closed or system cleans up. Sensitive card content could be recovered from temp storage

### i18n Readiness: 1/10 - Zero internationalization
- Every single UI string is hardcoded in Korean and English as compound strings like `'CARD GENERATE / 카드 생성'`
- EULA is 57 lines of Korean legal text embedded in `app_constants.dart` - impossible to translate without rewriting
- Template names are `'NEON / 네온'`, `'SUNSET / 석양'` etc. - bilingual strings hardcoded throughout
- No `intl` dependency, no `arb` files, no `GeneratedAppLocalization`
- `_formatDate` in `card_history_section.dart` formats dates in Korean: `'방금 전'`, `'${diff.inMinutes}분 전'` - language-specific
- **For global launch:** Every text widget, every SnackBar, every dialog, every label needs to be extracted to arb files. Estimated effort: 2-3 days per language

### 10M Scale Readiness: 9/10 - Fully offline, trivially scalable
- No server infrastructure needed - everything is client-side SharedPreferences
- 10M users = 10M devices running independently. Zero backend costs
- **Limitation:** SharedPreferences has a ~1MB limit. With 10 history items per user (each ~500 bytes JSON), that's ~5KB per user. Well within limits even with 1000 cards
- **Risk:** No crash reporting, no analytics, no remote config. At 10M scale, you need Firebase Crashlytics, Analytics, and Remote Config for EULA updates
- **Risk:** No version migration strategy for SharedPreferences data. If card history format changes in a future update, old data could corrupt (the `try-catch` in `getCardHistory` handles this gracefully, returning `[]`)

### Critical Issues:
1. **`_deleteCard(index)` calls `clearCardHistory()`** - deleting one card wipes the entire history. The `index` parameter is completely ignored
2. **`CardTemplateControllerProvider` is dead code** - duplicates `WillFormController` with identical methods, never used in the app
3. **`WillCardModel` is a pointless subclass** - zero additional logic over `WillCard`
4. **`WillCard.fromMap` crashes on null/missing fields** - no defensive null handling
5. **SharedPreferences I/O storm** - auto-save on every keystroke, no debouncing
6. **EULA agreement not persisted** - lost on app restart, only tracked in widget state
7. **Share files written to temp directory** persist on disk containing user's personal data

### Recommendations:
1. Fix `_deleteCard` to remove only the specific index from history, not clear all
2. Delete `card_template_provider.dart` entirely - merge template state into `will_form_provider.dart`
3. Delete `WillCardModel` - `WillCard` already has `toMap()`/`fromMap()`
4. Add null safety to `WillCard.fromMap`: `name: (map['name'] as String?) ?? ''`
5. Debounce `_autoSave()` to 500ms using `Future.delayed` or a timer
6. Persist EULA acceptance to SharedPreferences alongside onboarding flag
7. Cache `SharedPreferences.getInstance()` as a singleton with lazy initialization
8. Add `intl` package and extract all hardcoded strings to `.arb` files
9. Add text overflow handling on `Neon3DWillCard` for long names/values
10. Add Firebase Crashlytics and Analytics for production monitoring
11. Add haptic feedback on card generation and history delete
12. Delete temp files after sharing completes

---

## App B: SFX Memento Mori (Life Week Grid Visualizer)

**Total files:** 14 Dart files
**File structure:**
```
lib/
├── main.dart                                    (61 lines, PreferenceService init + routing)
├── core/
│   ├── theme/
│   │   ├── app_theme.dart                       (86 lines, complete ThemeData)
│   │   └── neon_colors.dart                     (20 lines, color constants)
│   ├── utils/
│   │   ├── life_calculator.dart                 (120 lines, pure functions + LifeStats)
│   │   └── life_quotes.dart                     (93 lines, time-of-day quotes)
│   ├── services/review_service.dart             (45 lines, InAppReview wrapper)
│   └── storage/preference_service.dart          (92 lines, SharedPreferences wrapper)
├── features/
│   ├── onboarding/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── welcome_page.dart            (486 lines, particles + animated counter)
│   │   │   │   └── onboarding_page.dart         (669 lines, birth date + target age + EULA)
│   │   │   └── providers/onboarding_provider.dart (86 lines, StateNotifier + provider)
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── pages/home_page.dart             (985 lines - largest file, share + grid)
│   │   │   ├── widgets/week_grid.dart           (527 lines, CustomPaint + ListView)
│   │   │   └── providers/life_provider.dart     (16 lines, computed LifeStats)
│   └── settings/presentation/pages/settings_page.dart (656 lines)
```

### Architecture: 7.5/10 - Well-organized, separation of concerns maintained
- Clean separation: core/ for utilities (LifeCalculator, LifeQuotes, ReviewService), features/ for UI
- `LifeCalculator` is a pure utility class with `const LifeCalculator._()` - no state, no side effects. Excellent
- `LifeStats` is a plain data class with computed `completionPercentage` - immutable, testable
- `PreferenceService` is initialized in `main()` and injected via `ProviderScope.overrides` - proper DI pattern
- `life_provider.dart` is a computed provider that derives `LifeStats` from preferences - reactive and efficient
- `LifeQuotes` is a pure lookup class with no dependencies - easily testable
- `ReviewService` depends on `PreferenceService` and `InAppReview` - clear dependency chain
- **Issue:** `HomePage` at 985 lines is a massive file combining: share logic (Canvas API drawing, 300+ lines), UI rendering, animated counter, and navigation. Should be split into share service + home page widget
- **Issue:** `onboarding_page.dart` at 669 lines includes the full EULA dialog with 7 collapsible sections - should be extracted to a separate widget
- `PreferenceService` is a singleton accessed via provider but also has `init()` async method - if called before `init()`, all getters return null (guarded by `?`)

### Code Quality: 7/10 - Good patterns with some duplication
- `LifeCalculator` methods are well-named and self-documenting: `calculateTotalWeeks`, `calculateWeeksElapsed`, `calculateDaysRemaining`, `getElapsedYearsAndMonths`
- `getElapsedYearsAndMonths` correctly handles edge cases: `now.day < birthDate.day` adjusts months down, clamps to 0
- `_WeekCell` is smart: only the "today" cell creates an active `AnimationController`, others use `AlwaysStoppedAnimation(1.0)` - good optimization
- **Duplication:** `_formatNumber(int number)` with comma regex formatting appears in BOTH `home_page.dart:811` AND `week_grid.dart:280`. Should be extracted to `core/utils/format_utils.dart`
- **Issue:** `life_provider.dart` creates a new `LifeCalculator.getLifeStats()` on every preference change. This is computationally cheap but the provider doesn't cache - every widget watching this recomputes
- **Issue:** `PreferenceService` uses `_prefs?` throughout (nullable). If `init()` hasn't completed, ALL getters silently return false/null instead of throwing. This is safe but can mask bugs
- `ReviewService` has a clean interface but `promptReview()` marks as prompted before confirming the review was actually shown
- `_CircularProgressIndicator` / `_ProgressPainter` is well-implemented with `shouldRepaint` checking only progress value - efficient
- `YearMarkerPainter` has `shouldRepaint => false` - correct, it never changes

### UX/UI: 8.5/10 - Most visually impressive app of the three
- Welcome page has 30 floating particles with randomized positions, sizes, speeds, and opacities
- Animated counter on welcome page uses eased cubic curve (`1 - pow(1 - progress, 3)`) for natural counting feel
- Mini grid preview on welcome page (20 cols x 416 cells) gives immediate visual context
- Main week grid uses `RepaintBoundary` per row to isolate repaints - good for performance
- `YearMarkerPainter` draws decade lines and milestone labels in CustomPaint under the grid
- Circular progress indicator on home screen shows life completion percentage
- Time-of-day quotes change based on hour (morning/afternoon/evening/night)
- Settings page has pulsing lock icon with concentric glow rings
- **Missing:** No accessibility labels on the grid cells (screen reader unfriendly)
- **Issue:** Grid year marker positioning uses `MediaQuery.of(context).size.width` in `_buildYearMarkers` - breaks if screen size changes (rotation)
- **Issue:** The share image is generated using Canvas API manually drawing text with `TextPainter`. This does NOT respect device font size preferences and may render differently on different devices
- **Issue:** `onboarding_page.dart` EULA dialog has hardcoded Korean text for 7 legal sections

### State Management: 7/10 - Provider pattern used well, some edge cases
- `preferenceServiceProvider` is overridden in `main()` with the initialized instance - proper singleton pattern
- `onboardingProvider` uses `StateNotifierProvider` with `loadFromPrefs()` in constructor - loads previous data on init
- `life_provider` is a computed `Provider` that derives from `preferenceServiceProvider` - reactive, no manual subscriptions
- `main.dart` routing reads `prefs.isOnboarded && prefs.birthDate != null && prefs.targetAge != null` - checks multiple conditions for navigation
- **Issue:** `onboarding_page.dart:352` navigates using `Navigator.of(context).pushReplacement` AFTER calling `completeOnboarding()` which is async. The `context.mounted` check guards against stale context, but `context` may be stale if the user navigates away during the save
- **Issue:** `SettingsPage._showChangeTargetAgeDialog()` calls `navigator.pop()` then `ScaffoldMessenger.of(context)` - the context may be the dialog's context, not the settings page's context. Should use a separate context reference
- `lifeProvider` returns `null` when birth date or target age is missing - home page handles this with a loading state, but the null check is in every calling widget

### Performance: 6.5/10 - Week grid is the bottleneck
- **Week grid renders up to 4,160 cells** (80 years * 52 weeks). Optimized with:
  - `ListView.builder` with `itemExtent` for row virtualization
  - `RepaintBoundary` per row
  - Only first 100 cells get staggered entrance animations
  - `_WeekCell` only animates the "today" cell
  - `YearMarkerPainter` uses `shouldRepaint => false`
- **Issue:** `_WeekCell` is a `StatefulWidget` even though 99% of cells are static. The non-today, non-past cells could be `StatelessWidget`s. Each StatefulWidget adds ~200 bytes of state overhead. 4,160 cells * 200 bytes = ~800KB of state objects
- **Issue:** The `AnimatedBuilder` for particles on welcome page rebuilds all 30 particles on every animation tick (every frame for 8 seconds). This is fine for a one-time welcome screen but wasteful
- **Issue:** `_animateRemainingWeeks` in `HomePage` uses a manual `Future.delayed(16ms)` tick loop instead of an `AnimationController`. This fires a microtask every frame regardless of visibility
- **Critical:** The share function in `home_page.dart` draws a Canvas image with `TextPainter` for each text element. It creates 6+ `TextPainter` instances, lays them out, and paints them. This is done on every share attempt and could take 100-200ms on lower-end devices
- `_ProgressPainter` creates new `Paint` objects on every `paint()` call instead of caching them as class fields

### Security: 8/10 - Local-only, minimal attack surface
- No network calls, no server, all data in SharedPreferences
- Birth date is sensitive data stored in plain text - extractable on rooted devices
- No biometric protection
- Share images written to `getApplicationDocumentsDirectory()` - these persist and could contain personal information (age, life progress)
- Privacy policy dialog states "no analytics, no tracking" - should be verified in pubspec.yaml and reviewed for any third-party SDKs
- **Issue:** `SettingsPage` reset function calls `prefs.resetAll()` which deletes ALL preferences including `firstLaunchDate`. This could cause the app to show the welcome screen again on next launch, which is the intended behavior but resets review tracking too

### i18n Readiness: 1/10 - Zero internationalization
- ALL text is hardcoded in Korean: `'오늘의 주'`, `'남은 시간'`, `'인생 진행률'`, `'지난 주'`, `'남은 일수'`, `'지금까지 산 시간'`, `'현재 나이'`
- `LifeQuotes` has all Korean quotes organized by progress percentage and time of day
- Date formatting in `_koreanLastPing` is Korean-specific: `'마지막 Ping: 방금 전'`
- Welcome counter shows `80년 = 4,160주` - Korean-specific number formatting
- Settings page has Korean section titles: `'인생 설정'`, `'데이터 관리'`
- EULA is 7 collapsible sections of Korean legal text
- No `intl` package dependency, no `.arb` files
- **For global launch:** All ~150 unique strings need extraction. Quotes alone are 28 unique strings. Estimated effort: 3-4 days per language

### 10M Scale Readiness: 9/10 - Fully offline, trivially scalable
- Zero backend dependency - 100% client-side computation
- `LifeCalculator.getLifeStats` is O(1) - instant calculation regardless of user count
- **Risk:** No analytics to understand user engagement, retention, or feature usage at scale
- **Risk:** No crash reporting - if the week grid crashes on certain devices (e.g., very old phones), you won't know until user reviews
- **Risk:** No remote config for adjusting default values (e.g., target age range 70-90 could be adjusted per market)
- **Limitation:** The `80년 = 4,160주` welcome counter is hardcoded - different cultures expect different life expectancies (Japan: 84, India: 70, etc.)

### Critical Issues:
1. **`_WeekCell` is StatefulWidget for all 4,160 cells** - 99% of cells never animate. Should be StatelessWidget or use `const` widgets for past/future cells
2. **`_formatNumber` duplicated** in home_page.dart and week_grid.dart
3. **`_ProgressPainter` creates Paint objects on every paint()** - should cache as class fields
4. **Share Canvas text rendering uses TextPainter** without font fallback - may render differently on different devices
5. **`_animateRemainingWeeks` uses manual Future.delayed tick** instead of AnimationController
6. **Year marker positioning uses MediaQuery.width** - breaks on screen rotation
7. **No accessibility support** for the week grid

### Recommendations:
1. Convert `_WeekCell` past/future cells to `const` StatelessWidget variants, keep StatefulWidget only for "today" cell
2. Extract `_formatNumber` to `core/utils/format_utils.dart`
3. Cache `Paint` objects in `_ProgressPainter` as late final fields
4. Use a pre-rendered image or Widget-based share capture instead of manual Canvas drawing
5. Replace `_animateRemainingWeeks` manual tick with `AnimationController` and `.addListener`
6. Fix year marker positioning to use `LayoutBuilder` constraints instead of `MediaQuery`
7. Add `Semantics` labels to week grid for accessibility
8. Extract all Korean strings to `.arb` files with `flutter_intl`
9. Add Firebase Analytics and Crashlytics
10. Make welcome counter's `4,160` configurable based on target age
11. Add haptic feedback when selecting birth date or changing target age
12. Add pull-to-refresh on home page to recalculate life stats

---

## App C: SFX Legacy Vault (Dead Man's Switch / Encrypted Vault)

**Total files:** 19 Dart files
**File structure:**
```
lib/
├── main.dart                                    (167 lines, Firebase init + routing + demo mode)
├── core/
│   ├── theme/app_theme.dart                     (141 lines, complete ThemeData with error borders)
│   ├── constants/app_colors.dart                (17 lines, color constants)
│   ├── config/firebase_options.dart             (Generated Firebase config - not readable)
│   ├── utils/date_utils.dart                    (71 lines, deadline + countdown calculations)
│   └── services/
│       ├── encryption_service.dart              (93 lines, AES-256-CBC with XOR KDF)
│       └── review_service.dart                  (69 lines, ping-based review prompt)
├── features/
│   ├── onboarding/presentation/
│   │   ├── screens/
│   │   │   ├── welcome_screen.dart              (431 lines, trust badges + security messaging)
│   │   │   ├── eula_screen.dart                 (622 lines, collapsible EULA/Privacy/Security)
│   │   │   └── setup_required_screen.dart       (405 lines, Firebase config failure screen)
│   │   └── providers/onboarding_provider.dart   (62 lines, WelcomeAccepted + EULA Notifiers)
│   ├── auth/
│   │   ├── data/firebase_auth_service.dart      (49 lines, email + Apple auth)
│   │   ├── presentation/
│   │   │   ├── screens/login_screen.dart        (794 lines, login/signup + Apple sign-in)
│   │   │   └── providers/auth_provider.dart     (17 lines, Firebase auth providers)
│   └── vault/
│       ├── domain/models/vault_model.dart       (121 lines, VaultModel + VaultStatus enum)
│       ├── data/vault_repository.dart           (123 lines, Firestore CRUD + ping)
│       └── presentation/
│           ├── screens/
│           │   ├── home_screen.dart             (2,177 lines - largest file!)
│           │   └── vault_setup_screen.dart      (1,538 lines - second largest)
│           └── providers/vault_provider.dart    (145 lines, VaultsNotifier + StreamProvider)
```

### Architecture: 5/10 - Firebase integration adds complexity, some anti-patterns
- Follows Clean Architecture pattern but home_screen.dart (2,177 lines) and vault_setup_screen.dart (1,538 lines) are massive violations of SRP (Single Responsibility Principle)
- `home_screen.dart` contains: authentication state management, vault dashboard, vault card widgets, swipeable card wrapper, security banner, trust footer, vault summary, swipeable card, countdown timer management, security tips dialog - over 2,100 lines of code in a single file. This should be split into 8+ files
- **Dual state management anti-pattern:** `vaultsStreamProvider` (StreamProvider.family) and `vaultNotifierProvider` (NotifierProvider) both manage vault list state. The StreamProvider listens to Firestore real-time updates, while the NotifierProvider manages optimistic updates. These can conflict - the stream can overwrite the notifier's optimistic state
- **`FirebaseAuthService.signInWithApple()` uses `signInWithPopup()`** which is a web-only API. This will crash on iOS/Android. Should use `OAuthProvider` with `signInWithProvider` for mobile
- `DateUtils` is well-designed as a pure utility with `abstract final class` - no instantiation possible
- `VaultRepository` directly accesses `FirebaseFirestore.instance` - no interface abstraction, making testing difficult
- `main.dart` has a complex initialization flow: Firebase init -> check onboarding -> check EULA -> check auth -> navigate. The `FirebaseConfigNotifier` uses `AsyncValue` pattern correctly
- **`main.dart:54-58`** `retryInitialization()` calls `Firebase.initializeApp(name: 'retry_init')` with a different app name - this creates a SECOND Firebase app instance which can cause memory leaks and unexpected behavior

### Code Quality: 5/10 - Critical security issues in encryption, code too large
- **CRITICAL SECURITY: `_deriveKey` uses XOR-based key derivation, NOT PBKDF2:**
  ```dart
  // encryption_service.dart:68-87
  static encrypt_lib.Key _deriveKey(String passphrase, List<int> saltBytes) {
      final combined = <int>[...utf8.encode(passphrase), ...saltBytes];
      final bytes = <int>[];
      for (int i = 0; i < 32; i++) {
          int b = 0;
          for (int j = 0; j < combined.length; j++) {
              b ^= combined[j] ^ (i + j * 31);  // XOR-based, NOT a real KDF!
          }
          bytes.add(b & 0xFF);
      }
      return encrypt_lib.Key(Uint8List.fromList(bytes));
  }
  ```
  The comment even admits: "In production, consider using a proper KDF like PBKDF2". This XOR loop provides virtually no protection against brute force attacks. A GPU can try billions of passphrases per second against this derivation
- **CRITICAL SECURITY: Passphrase stored in plain text SharedPreferences:**
  ```dart
  // vault_setup_screen.dart:108-109
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('encryption_passphrase', passphrase);
  ```
  The entire security model claims "Zero-Knowledge, Client-Side Only, Keys stay on device" but the key is stored as plaintext in SharedPreferences. On a rooted/jailbroken device, this is trivially extractable. The app might as well store data unencrypted
- **CRITICAL BUG: `_nextStep()` has fall-through cases:**
  ```dart
  void _nextStep() {
      switch (_currentStep) {
          case 0:  // Validates name
          case 1:  // Validates data - NO BREAK! Falls through from case 0!
          case 2:  // Validates email - NO BREAK! Falls through from case 1!
          case 3:  // Deadline
          case 4:  // Encryption key
          }
  }
  ```
  The switch statement has NO break/return between cases. In Dart, switch cases don't fall through, BUT the validation logic means if you're on step 1, it validates step 0 AND step 1. This is intentional but confusing without comments. However, if the user navigates to step 2, it validates steps 0, 1, AND 2 - this is actually correct behavior for a wizard but should be documented
- **`VaultRepository` swallows all errors:**
  ```dart
  Future<List<VaultModel>> getVaults(String userId) async {
      try {
          // ...
      } catch (e) {
          return [];  // Silently returns empty on ANY error
      }
  }
  ```
  Network errors, permission errors, and data corruption all return the same empty list - no error propagation
- **`VaultModel.fromFirestore` crashes on missing Timestamp fields:**
  ```dart
  lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),  // Crashes if null
  createdAt: (data['createdAt'] as Timestamp).toDate(),         // Crashes if null
  ```
  If a document is created with an older schema (before these fields existed), the app crashes
- `_VaultCard` swipe actions return `false` from `confirmDismiss` but the swipe background shows "Ping" and "Edit" - the actions never trigger. Dead UI
- `home_screen.dart` at 2,177 lines: contains `_VaultDashboard`, `_SwipeableVaultCard`, `_SecurityBanner`, `_VaultSummary`, `_VaultCard`, `_TrustFooter`, `_SetupPrompt`, `_LoadingState`, `_ErrorState`, `_EmptyState`, `_SecurityTipsDialog`, `_PingConfirmationDialog`, `_CountdownCard`, `_VaultTypeSelector`, `_VaultDetailsEditor`, `_VaultDecryptDialog` - at least 15 widgets in one file
- `vault_setup_screen.dart` at 1,538 lines: 5-step wizard with validation, encryption, passphrase management - should be split into step widgets

### UX/UI: 7/10 - Polished security-focused design, but overbuilt files
- 5-step vault setup wizard with progress indicator, step icons, and animated transitions
- Trust badges throughout: "AES-256 · Zero-Knowledge · Client-Side Only", "CERTIFIED" badge
- Pulsing security icon with concentric glow rings on login screen
- Swipeable vault cards with gradient borders per vault type (crypto=orange, passwords=blue, letter=green)
- Countdown timer updates every second via `Timer.periodic` - shows days/hours/minutes/seconds remaining
- Vault status colors: active (green), warning (orange, <3 days), expired (red), paused (grey)
- Apple Sign-In button with proper styling
- Security tips dialog with trust signals
- **Issue:** The swipe actions on vault cards are non-functional - background shows "Ping" and "Edit" but `confirmDismiss` returns `false` and no actions fire
- **Issue:** `_VaultDecryptDialog` requires the user to re-enter their passphrase to read their own data - if they forgot it (and it's stored in SharedPreferences anyway), this is confusing
- **Issue:** Login screen has Korean text for account recovery links ('계정 찾기', '비밀번호 재설정') with `TODO` comments - not implemented
- **Issue:** `_buildGlowingFAB` uses `TweenAnimationBuilder` with continuous animation - runs even when FAB is off-screen

### State Management: 5.5/10 - Dual-state conflict risk, race conditions
- **Dual state anti-pattern:** `vaultsStreamProvider` (StreamProvider) and `vaultNotifierProvider` (NotifierProvider) both track vault lists. `home_screen.dart` uses `vaultNotifierProvider` but the StreamProvider exists and is never consumed. If both are watched, optimistic updates from the notifier can be overwritten by stream updates
- **Race condition in `main.dart:82-84`:**
  ```dart
  ref.read(welcomeAcceptedProvider.notifier).init();  // async, fires and forgets
  ref.read(onboardingProvider.notifier).init();       // async, fires and forgets
  ```
  These async init calls fire without await. The `build()` method below reads their state immediately, which may return `false` (default) before the async load completes. This causes flicker: welcome screen -> welcome screen again after prefs load
- **`_HomeScreenState._autoPing()` in initState:** Pings all vaults on every screen open. Combined with `Timer.periodic` countdown, this means the app is constantly making Firestore writes
- **Countdown timer rebuilds the entire widget tree every second:**
  ```dart
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) { setState(() {}); }  // Rebuilds entire HomeScreen!
  });
  ```
  This rebuilds the app bar, all vault cards, security banner, FAB - for a countdown timer
- `auth_stateProvider` is a StreamProvider that listens to `authStateChanges` - correct pattern
- `FirebaseConfigNotifier` uses `AsyncValue` pattern from Riverpod correctly

### Performance: 4/10 - Multiple serious issues
- **Timer.periodic rebuilds entire HomeScreen every second** - the `setState(() {})` in the countdown timer rebuilds ALL children including vault cards, app bar, FAB. Should isolate countdown to a small widget
- **home_screen.dart at 2,177 lines** - the entire dashboard including 15+ private widgets in one file. Every rebuild recompiles this massive build method
- **`_autoPing()` fires on every screen open** - writes to Firestore for every active vault on every navigation
- **`VaultsNotifier.pingVault()` does optimistic update AND Firestore write** - if the Firestore write fails, the local state is already updated. The error is silently swallowed
- **`vault_repository.dart:77-80`** `pingVault` updates `lastActiveAt` AND `status: 'active'` in one operation - unnecessary status update if already active
- **`_VaultCard` creates a separate widget per vault** with pulse animation controllers. With 5+ vaults, that's 5+ continuous animations
- **`vault_setup_screen.dart` at 1,538 lines** - the 5-step wizard with animated transitions. `AnimatedSwitcher` rebuilds on every step change
- Firestore `vaultsStream` keeps a persistent WebSocket connection open - at scale, each user maintains an open stream

### Security: 2/10 - CRITICAL VULNERABILITIES
1. **XOR-based key derivation instead of PBKDF2/Argon2:** The `_deriveKey` method uses a simple XOR loop that provides virtually zero resistance to brute force attacks. Modern GPUs can crack this in hours. The code comment even acknowledges this: "In production, consider using a proper KDF like PBKDF2"
2. **Passphrase stored in plaintext SharedPreferences:** `prefs.setString('encryption_passphrase', passphrase)` completely defeats the zero-knowledge architecture. The entire marketing of "Zero-Knowledge, Client-Side Only, Keys stay on device" is a lie if the key is stored as plaintext accessible to any app with device access
3. **`signInWithPopup()` for Apple Sign-In on mobile:** This crashes on iOS/Android as it's a web-only API. Users on mobile cannot use Apple Sign-In
4. **`Firebase.initializeApp(name: 'retry_init')`** creates a second Firebase instance on retry - memory leak
5. **Firestore stores `encryptedData` as a string field** - the encrypted blob is stored server-side. While the server can't read it (with proper KDF), the XOR KDF makes this moot
6. **No password strength validation on sign-up** - only checks `length >= 6`. No complexity requirements for a security app
7. **No rate limiting on authentication** - brute force login attacks possible
8. **`_deriveKey` comment is a security red flag in shipped code:** "In production, consider using a proper KDF like PBKDF2" - this is a TODO in security-critical code
9. **Passphrase displayed in a TextField** that can be shown/hidden - if shown on screen, screenshots could capture it
10. **No biometric authentication** - the entire security model relies on a passphrase that's stored in plaintext

### i18n Readiness: 2/10 - Mix of English and Korean, no system
- Most UI text is in English: "Set Up Your Vault", "Welcome Back", "Your Digital Legacy, Securely Protected"
- Korean strings scattered: '계정 찾기', '비밀번호 재설정', '암호화된 보호', '데드맨스위치 디지털 유산 보관'
- EULA, Privacy Policy, and Data Security texts are in English (good for global)
- Date formatting in `DateUtils` uses English: 'Just now', '5m ago', '2h ago', '3d ago'
- Vault type labels are English: 'crypto', 'passwords', 'letter', 'custom', 'legal'
- No `intl` package, no `.arb` files
- `_koreanLastPing` function in home_screen.dart hardcodes Korean format
- **Slightly better than Apps A/B** because the primary UI is English, but still no i18n infrastructure

### 10M Scale Readiness: 3/10 - Firebase costs and Firestore limitations
- **Firestore cost analysis at 10M users:**
  - Each user has a persistent `vaultsStream` WebSocket - Firestore charges per document read per stream update. At 10M users, even with 1 vault each, this is 10M concurrent streams
  - `_autoPing()` on every screen open writes to Firestore - at 10M users opening the app 5 times/day, that's 50M writes/day. Firestore charges $0.000050 per write = $2,500/day just for pings
  - Each ping updates `lastActiveAt` AND `status` - 2 field updates per vault
  - `vaultsStream` delivers a document read every time ANY vault changes - at scale, this is expensive
- **No Firestore security rules visible in code** - the repository assumes all access control is client-side. If security rules aren't configured, any user can read any other user's vaults
- **No pagination** on vault list - `vaultsStream` loads ALL vaults. If a user somehow has 1000 vaults (unlikely but possible), the entire list loads at once
- **No offline persistence strategy** - Firestore has offline persistence but the app doesn't handle the offline/online transition
- **`Firebase.initializeApp` in `main()` is a blocking async call** - if Firebase is slow to initialize, users see a blank screen
- **Demo mode allows the app to run without Firebase** - good for development, but the `acceptDemoMode()` path has no clear indication of which features are disabled

### Critical Issues:
1. **CRITICAL: XOR-based key derivation** - `_deriveKey` is not a real KDF. Replace with `pointycastle` PBKDF2 or `bcrypt` immediately
2. **CRITICAL: Passphrase stored as plaintext in SharedPreferences** - use Android Keystore / iOS Keychain via `flutter_secure_storage`
3. **CRITICAL: `signInWithPopup()` for Apple on mobile** - crashes on iOS/Android. Use `signInWithProvider()`
4. **CRITICAL: `Firebase.initializeApp(name: 'retry_init')`** creates duplicate Firebase instances
5. **CRITICAL: `home_screen.dart` is 2,177 lines** - must be split into 8+ files
6. **CRITICAL: `vault_setup_screen.dart` is 1,538 lines** - must be split into step components
7. **CRITICAL: Dual state management** (`vaultsStreamProvider` + `vaultNotifierProvider`) can cause state conflicts
8. **`VaultModel.fromFirestore` crashes on null Timestamp** - schema migration risk
9. **Countdown timer rebuilds entire HomeScreen every second** - massive performance waste
10. **Firebase costs at 10M scale** - stream reads + ping writes will cost $50K+/month
11. **No Firestore security rules in code** - data leak risk if rules aren't configured
12. **`_autoPing()` fires on every screen open** - unnecessary Firestore writes
13. **`_nextStep()` switch fall-through logic is confusing** - needs documentation
14. **Swipe actions on vault cards are non-functional** - shows "Ping" and "Edit" but does nothing
15. **Password validation only checks `>= 6 characters`** - too weak for a security app
16. **`VaultRepository` swallows all errors** - silent failures mask real issues

### Recommendations:
1. **REPLACE XOR KDF immediately** with `package:pointycastle` PBKDF2 (100,000+ iterations) or Argon2
2. **Use `flutter_secure_storage`** instead of SharedPreferences for passphrase - stores in Android Keystore / iOS Keychain
3. **Fix Apple Sign-In** to use `signInWithProvider()` for mobile, keep `signInWithPopup()` only for web
4. **Remove `Firebase.initializeApp(name: 'retry_init')`** - use the same app instance or call `Firebase.apps` to reuse
5. **Split `home_screen.dart`** into: `vault_dashboard.dart`, `vault_card.dart`, `vault_summary.dart`, `security_banner.dart`, `countdown_timer.dart`, `setup_prompt.dart`, `error_states.dart`, `security_tips_dialog.dart`
6. **Split `vault_setup_screen.dart`** into: `wizard_stepper.dart` + 5 step widgets
7. **Choose ONE state management approach** for vaults - either StreamProvider OR NotifierProvider, not both
8. **Isolate countdown timer** to a small widget with its own state, don't rebuild entire HomeScreen
9. **Add Firestore security rules** to the repository and verify they're deployed
10. **Add error propagation** to `VaultRepository` - return `AsyncValue` or throw typed errors
11. **Add Firestore pagination** or limit queries to prevent loading thousands of vaults
12. **Add password complexity requirements** (min 8 chars, uppercase, lowercase, number, special char)
13. **Add rate limiting** to authentication (max 5 attempts per minute)
14. **Add biometric authentication** as an alternative to passphrase entry
15. **Add offline mode handling** with Firestore persistence configuration
16. **Remove `signInWithPopup`** entirely for mobile - use platform-specific OAuth flows
17. **Add Firebase cost monitoring** - set budget alerts for Firestore reads/writes
18. **Add `intl` package and extract all Korean strings**
19. **Add Firestore `ServerTimestamp`** instead of `Timestamp.now()` for consistent timestamps
20. **Document the `_nextStep()` switch fall-through pattern** or rewrite with explicit validation per step

---

## Overall Summary

### Strengths Across All Apps
1. **Consistent neon dark theme** - `NeonColors` class provides unified color system across all 3 apps
2. **Riverpod state management** used correctly for reactive UI updates
3. **flutter_animate** provides polished staggered animations onboarding
4. **Local-first architecture** for Apps A and B means zero backend costs
5. **Clean folder structure** with feature-based organization
6. **EULA compliance** with proper consent flows on all apps

### Weaknesses Across All Apps
1. **Zero i18n** - All 3 apps have hardcoded strings. None are ready for global launch
2. **No analytics or crash reporting** - Blind at scale
3. **SharedPreferences overused** - Every app calls `getInstance()` repeatedly instead of caching
4. **No testing files found** - No `test/` directories in the audit scope
5. **Large monolithic files** - Multiple files exceed 600+ lines

### Critical Cross-Cutting Issues
1. **App C encryption is fundamentally broken** - XOR KDF + plaintext passphrase storage makes the entire security model worthless. This must be fixed before any user data touches production
2. **App A history delete bug** - Deleting one card wipes all history
3. **No CI/CD pipeline visible** - No GitHub Actions, Codemagic, or Firebase App Distribution configuration in the source
4. **No `analysis_options.yaml` custom rules** - Apps pass `flutter analyze` but that's the baseline
5. **Memory management** - Multiple `AnimationController` instances with `repeat()` that run continuously

### Priority Action Items (Ordered by Severity)

| Priority | App | Issue | Effort |
|----------|-----|-------|--------|
| P0 | C | Replace XOR KDF with PBKDF2 | 1 day |
| P0 | C | Move passphrase to flutter_secure_storage | 1 day |
| P0 | C | Fix Apple Sign-In for mobile | 2 hours |
| P0 | A | Fix `_deleteCard` to remove single item | 1 hour |
| P1 | C | Remove duplicate Firebase app on retry | 1 hour |
| P1 | C | Split home_screen.dart (2,177 lines) | 3 days |
| P1 | C | Split vault_setup_screen.dart (1,538 lines) | 2 days |
| P1 | C | Choose single state management for vaults | 1 day |
| P1 | A | Delete dead code: card_template_provider.dart | 30 min |
| P1 | A | Delete dead code: WillCardModel | 30 min |
| P1 | B | Convert _WeekCell to StatelessWidget | 1 day |
| P1 | All | Add flutter_secure_storage for sensitive data | 2 days |
| P2 | C | Isolate countdown timer rebuild | 2 hours |
| P2 | C | Add Firestore security rules | 1 day |
| P2 | C | Add password complexity validation | 2 hours |
| P2 | B | Extract _formatNumber to shared utils | 30 min |
| P2 | B | Cache Paint objects in _ProgressPainter | 1 hour |
| P2 | A | Debounce auto-save to 500ms | 2 hours |
| P2 | A | Add null safety to WillCard.fromMap | 30 min |
| P2 | All | Add Firebase Crashlytics + Analytics | 2 days |
| P3 | All | Add i18n with flutter_intl | 5 days per language |
| P3 | All | Add unit + widget tests | 3 weeks |
| P3 | All | Cache SharedPreferences singleton | 2 hours |
| P3 | C | Add biometric authentication | 3 days |
| P3 | C | Add Firestore cost monitoring | 1 day |

### Estimated Total Technical Debt: 6-8 weeks for P0-P2, 12+ weeks for full P3

---

*End of Technical Audit Report*
