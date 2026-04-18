# CheckinFlow V7 — Flutter Clean Architecture Implementation

## TL;DR

> **Quick Summary**: Build a complete daily checkin flow for the Life-Log V7 Flutter app — a glassmorphic UI where users select energy level (1-5 stars), mood (5 emojis), and focus mode (4 chips), then submit to a Dio-backed API via Riverpod StateNotifier.

**Deliverables**:
- `PlannerApiClient` — Dio HTTP client (POST → `/api/health/daily-checkin`)
- `PlannerRepositoryImpl` — Data-layer bridge from `PlannerApiClient` to domain `PlannerRepository`
- `CheckinProvider` — Riverpod StateNotifier (enum states: initial/loading/success/error)
- `CheckinScreen` — Glassmorphic UI (deep abyss gradient, star rating, emoji mood, focus chips, submit)
- Updated `main.dart` — `ProviderScope`, dark theme, `GoogleFonts.inter`, `CheckinScreen` as home
- Barrel exports for clean `package:life_log_v7/...` imports
- TDD test files for API client, provider, and screen widget tests

**Estimated Effort**: Medium
**Parallel Execution**: YES — 3 waves
**Critical Path**: T1 → T2 → T5 → T6 → T7 → T8 → T9 → T10 → T11 → T12 → T13

---

## Context

### Original Request
Build a CheckinFlow (daily health checkin) for a Flutter app at `apps/life_log_v7` using Clean Architecture (domain/data/presentation layers):

1. **API Client**: Dio-based `PlannerApiClient` → POST `http://192.168.45.61:8080/api/health/daily-checkin`
2. **Provider**: Riverpod `StateNotifier` with `initial/loading/success/error` states
3. **Screen**: Glassmorphic UI — energy star rating, mood emoji selector, focus mode chips, submit button
4. **main.dart**: Wire everything — `ProviderScope`, dark theme, `GoogleFonts.inter`, `CheckinScreen` as home

### Interview Summary

**Key Discussions**:
- **Energy level**: Int 1-5, rendered as star Icon buttons
- **Mood emojis**: 😡 → 😢 → 😐 → 🙂 → 😄 (5 choices, single select)
- **Focus modes**: 딥워크 / 메일 / 회의 / 학습 (4 choices, single select)
- **Test strategy**: TDD — test-first, RED → GREEN → REFACTOR cycle per feature
- **Existing domain files are immutable** — `CheckinData` and `PlannerRepository` must NOT be modified

**Research Findings**:
- **Riverpod 2.5.1**: Use `StateNotifier` with assignment (`state = ...`), NOT `super.update()`; providers use `.autoDispose`; use `ProviderScope` in `main.dart`
- **Dio 5.x**: Returns `Response<String>` raw body; parse JSON manually with `jsonDecode`; use try-catch for non-2xx and connection errors
- **google_fonts 6.3.2**: Use `GoogleFonts.inter()` returning `TextStyle`; apply via `ThemeData.textTheme.apply(fontFamily: GoogleFonts.inter().fontFamily)`
- **Glassmorphism**: `ClipRRect` + `BackdropFilter` (ImageFilter.blur(sigmaX: 15, sigmaY: 15)) + Container with semi-transparent white color
- **Scaffold + Snackbar**: `ScaffoldMessenger.of(context)` requires `Scaffold` as ancestor — screen must be wrapped in `Scaffold`

---

## Metis Review — Gaps Identified & Addressed (BEFORE Plan Generation)

| Gap | Resolution |
|-----|------------|
| Missing `PlannerRepository` concrete implementation | Added TODO #7: `PlannerRepositoryImpl` implementing `PlannerRepository` |
| Boolean state design (idle/loading/success/error ambiguous) | Use `enum CheckinState { initial, loading, success, error }` |
| Missing Scaffold wrapper for Snackbar | Screen wraps content in `Scaffold` |
| Existing `widget_test.dart` blocks on new `main.dart` | TODO #12 updates `test/widget_test.dart` |
| Barrel exports unspecified | TODO #2-4: all 3 barrel files |
| Double-submit during loading | Submit button disabled via `onPressed: state.state == CheckinState.loading ? null : ...` |
| API client not bridged to domain repository | TODO #7 bridges `PlannerApiClient` → `PlannerRepository` |

---

## Work Objectives

### Core Objective
Deliver a complete, test-first daily checkin flow: user selects 3 inputs (energy, mood, focus mode), submits via API, and receives a success/error response — all layered cleanly through domain/data/presentation with full TDD coverage.

### Concrete Deliverables
- `lib/data/datasources/planner_api_client.dart` — Dio POST client
- `lib/data/repositories/planner_repository_impl.dart` — Domain repository implementation
- `lib/presentation/providers/checkin_provider.dart` — Riverpod StateNotifier
- `lib/presentation/screens/checkin_screen.dart` — Glassmorphic UI
- `lib/main.dart` — App root (updated from default counter)
- `lib/domain/domain.dart` — Barrel export
- `lib/data/data.dart` — Barrel export
- `lib/presentation/presentation.dart` — Barrel export
- `test/data/planner_api_client_test.dart` — API client tests
- `test/presentation/checkin_provider_test.dart` — Provider tests
- `test/presentation/checkin_screen_test.dart` — Widget tests
- `test/widget_test.dart` — Updated screen smoke test

### Must Have
- `PlannerApiClient` POSTs `CheckinData.toJson()` to `/api/health/daily-checkin`
- `PlannerRepositoryImpl` delegates to `PlannerApiClient`
- `CheckinProvider` transitions: `initial → loading → success/error`
- Screen: deep abyss gradient background, card with `BackdropFilter(sigma: 15)`, 5-star energy, 5-emoji mood, 4-chip focus, green submit button
- Success snackbar: **"오늘의 AI 플래너가 생성되었습니다!"**
- Submit button disabled during loading (no double-submit)
- All imports: `package:life_log_v7/...` format
- `flutter analyze --no-fatal-infos` → 0 errors after each task
- TDD: test file exists and passes before the corresponding feature file exists

### Must NOT Have (Guardrails)
- **DO NOT modify** `lib/domain/entities/checkin_data.dart`
- **DO NOT modify** `lib/domain/repositories/planner_repository.dart`
- NO local persistence (no `shared_preferences`, no `hive`, no caching)
- NO authentication/login flow
- NO navigation/routing — single screen app
- NO i18n — only Korean snackbar text
- NO custom animations (button press feedback only)
- NO settings/preferences page
- NO `async`/`await` without try-catch in API code
- NO `// ignore` or `// ignore_for_file` comments
- NO generic type typos (e.g., `Future<<bool>>`)

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Automated tests**: YES — TDD (RED → GREEN → REFACTOR)
- **Framework**: `flutter_test` (baked into SDK)
- **TDD flow per task**: Write failing test → Make it pass → Run analyzer → Refactor
- **Final verify**: `flutter test` + `flutter analyze --no-fatal-infos`

### QA Policy
Every task MUST include agent-executed QA scenarios with evidence files.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.txt`.
- **Widget tests**: `flutter test` with `WidgetTester` — tap, pump, expect
- **API client**: `flutter test` with `dio` mock — intercept HTTP
- **Provider**: `flutter test` with `ProviderContainer` — read state transitions
- **Full verify**: `flutter analyze --no-fatal-infos` + `flutter test`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — scaffolding):
├── T1: flutter pub get                    [sequential]
├── T2: Barrel lib/domain/domain.dart      [parallel]
├── T3: Barrel lib/data/data.dart          [parallel]
└── T4: Barrel lib/presentation/...dart    [parallel]

Wave 2 (After Wave 1 — data layer + provider core):
├── T5: PlannerApiClient tests (RED)      [depends: T2]
├── T6: PlannerApiClient impl (GREEN)     [depends: T5]
├── T7: PlannerRepositoryImpl             [depends: T2, T6]
└── T8: CheckinProvider tests (RED)       [depends: T2, T4, T7]

Wave 3 (After Wave 2 — provider + UI + wire):
├── T9: CheckinProvider impl (GREEN)     [depends: T8]
├── T10: CheckinScreen widget tests (RED) [depends: T4, T9]
├── T11: CheckinScreen UI (GREEN)        [depends: T10]
└── T12: main.dart + widget_test.dart    [depends: T11]

Wave FINAL:
└── T13: flutter pub get + analyze + test [depends: T12]
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| T1 | — | — |
| T2 | — | T5, T8 |
| T3 | — | — |
| T4 | — | T8, T9, T10 |
| T5 | T2 | T6 |
| T6 | T5 | T7 |
| T7 | T2, T6 | T8 |
| T8 | T2, T4, T7 | T9 |
| T9 | T8 | T10, T11 |
| T10 | T4, T9 | T11 |
| T11 | T10 | T12 |
| T12 | T11 | T13 |
| T13 | T12 | — |

---

## TODOs

> Implementation + Test = ONE Task (TDD). Never separate.
> Test comes FIRST (RED), then minimal code to pass (GREEN). Analyzer runs after each.

---

- [x] 1. **flutter pub get + verify dependencies**

  **What to do**:
  - cd to project root: `/Users/apple/development/soluni/Solve-for-X/apps/life_log_v7`
  - Run `flutter pub get`
  - Verify dependencies are already in pubspec.yaml (no changes needed)
  - Run `flutter analyze --no-fatal-infos` — capture output
  - Save output to `.sisyphus/evidence/task-1-pubget.txt`

  **Must NOT do**: Do NOT modify `pubspec.yaml` (dependencies are correct).

  **Recommended Agent Profile**:
  - **Category**: `quick` — single terminal command, no code changes.

  **Parallelization**:
  - **Can Run In Parallel**: YES | **Parallel Group**: Wave 1
  - **Blocks**: None | **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] `flutter pub get` exits 0
  - [ ] `flutter analyze --no-fatal-infos` → 0 errors (warnings OK)
  - [ ] Evidence: `.sisyphus/evidence/task-1-pubget.txt`

  **QA Scenarios**:
  ```
  Scenario: pub get succeeds
    Tool: Bash | Command: flutter pub get 2>&1 | tee .sisyphus/evidence/task-1-pubget.txt
    Expected: Exit 0, "Got dependencies!"

  Scenario: analyze has 0 errors
    Tool: Bash | Command: flutter analyze --no-fatal-infos 2>&1 | tee -a .sisyphus/evidence/task-1-pubget.txt
    Expected: "0 issues found"
  ```

---

- [x] 2. **Create barrel export: lib/domain/domain.dart**

  **What to do**:
  - Create `lib/domain/domain.dart` with 2 re-exports: `entities/checkin_data.dart`, `repositories/planner_repository.dart`
  - Run `flutter analyze --no-fatal-infos lib/domain/domain.dart`
  - Save to `.sisyphus/evidence/task-2-domain-barrel.txt`

  **Must NOT do**: Do NOT modify `lib/domain/entities/checkin_data.dart` or `lib/domain/repositories/planner_repository.dart`.

  **Recommended Agent Profile**: `quick` — simple barrel file.

  **Parallelization**:
  - **Can Run In Parallel**: YES | **Parallel Group**: Wave 1
  - **Blocks**: T5, T8 | **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] `lib/domain/domain.dart` exists with 2 re-exports
  - [ ] `import 'package:life_log_v7/domain/domain.dart';` compiles
  - [ ] Analyzer: 0 errors for this file

  **QA Scenarios**:
  ```
  Scenario: Barrel compiles
    Tool: Bash | flutter analyze --no-fatal-infos lib/domain/domain.dart 2>&1 | tee .sisyphus/evidence/task-2.txt
    Expected: 0 issues found
  ```

---

- [x] 3. **Create barrel export: lib/data/data.dart + directories**

  **What to do**:
  - Create dirs: `lib/data/`, `lib/data/datasources/`, `lib/data/repositories/`
  - Create `lib/data/data.dart` — empty barrel with placeholder comment
  - Run `flutter analyze --no-fatal-infos`
  - Save to `.sisyphus/evidence/task-3-data-barrel.txt`

  **Must NOT do**: Do NOT add actual exports yet.

  **Recommended Agent Profile**: `quick`.

  **Parallelization**:
  - **Can Run In Parallel**: YES | **Parallel Group**: Wave 1
  - **Blocks**: None | **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] `lib/data/data.dart` + `datasources/`, `repositories/` dirs exist

  **QA Scenarios**:
  ```
  Scenario: Empty barrel OK
    Tool: Bash | flutter analyze --no-fatal-infos 2>&1 | tee .sisyphus/evidence/task-3.txt
    Expected: 0 issues
  ```

---

- [x] 4. **Create barrel export: lib/presentation/presentation.dart + directories**

  **What to do**:
  - Create dirs: `lib/presentation/screens/`, `lib/presentation/providers/`
  - Create `lib/presentation/presentation.dart` — empty barrel with placeholder comment
  - Run `flutter analyze --no-fatal-infos`
  - Save to `.sisyphus/evidence/task-4-presentation-barrel.txt`

  **Must NOT do**: Do NOT add actual exports yet.

  **Recommended Agent Profile**: `quick`.

  **Parallelization**:
  - **Can Run In Parallel**: YES | **Parallel Group**: Wave 1
  - **Blocks**: T8, T9, T10 | **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] `lib/presentation/presentation.dart` + `screens/`, `providers/` dirs exist

  **QA Scenarios**:
  ```
  Scenario: Empty barrel OK
    Tool: Bash | flutter analyze --no-fatal-infos 2>&1 | tee .sisyphus/evidence/task-4.txt
    Expected: 0 issues
  ```

---

- [x] 5. **PlannerApiClient tests (TDD - RED)**

  **What to do**:
  - Create `test/data/planner_api_client_test.dart`
  - Test cases (4 total — must FAIL initially):
    1. POST 200 → returns true
    2. POST 4xx/5xx → throws Exception
    3. POST connection error → throws Exception
    4. POST body encodes CheckinData.toJson() correctly
  - Use mockito to mock Dio; import `package:life_log_v7/domain/domain.dart` and `package:life_log_v7/data/datasources/planner_api_client.dart`
  - Run `flutter test test/data/planner_api_client_test.dart` — EXPECT AT LEAST 1 FAILURE
  - Save to `.sisyphus/evidence/task-5-api-tests-red.txt`

  **Must NOT do**: Do NOT create `planner_api_client.dart` yet.

  **Recommended Agent Profile**: `unspecified-high` — TDD test writing with mocking.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 2
  - **Blocks**: T6 | **Blocked By**: T2

  **Acceptance Criteria**:
  - [ ] 4 test cases in file
  - [ ] Analyzer: 0 errors
  - [ ] `flutter test` → FAILS

  **QA Scenarios**:
  ```
  Scenario: Tests are RED
    Tool: Bash | flutter test test/data/planner_api_client_test.dart 2>&1 | tee .sisyphus/evidence/task-5.txt
    Expected: At least 1 test fails or compilation fails
  ```

---

- [x] 6. **PlannerApiClient implementation (TDD - GREEN)**

  **What to do**:
  - Create `lib/data/datasources/planner_api_client.dart`
  - Class `PlannerApiClient`:
    - Constructor accepts optional `Dio` for testing
    - `static const baseUrl = 'http://192.168.45.61:8080'`
    - `static const endpoint = '/api/health/daily-checkin'`
    - `Future<bool> submitCheckin(CheckinData data)` — POSTs `data.toJson()`, returns `statusCode == 200`
    - try-catch around `dio.post<Map<String, dynamic>>`, map DioException to Exception
  - Analyzer pass + tests pass
  - Save to `.sisyphus/evidence/task-6-api-client-green.txt`

  **References**: `lib/domain/entities/checkin_data.dart:toJson()`, `pubspec.yaml:dio`, `test/data/planner_api_client_test.dart`
  **Must NOT do**: Do NOT use `ResponseType.json`; suppress analyzer.

  **Recommended Agent Profile**: `unspecified-high` — Dio client with error handling.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 2
  - **Blocks**: T7 | **Blocked By**: T5

  **Acceptance Criteria**:
  - [ ] `PlannerApiClient` with `Future<bool> submitCheckin(CheckinData)`
  - [ ] POSTs correct URL with correct JSON body
  - [ ] Analyzer: 0 errors
  - [ ] `flutter test test/data/` → ALL PASS

  **QA Scenarios**:
  ```
  Scenario: Analyzer passes
    Tool: Bash | flutter analyze --no-fatal-infos lib/data/datasources/planner_api_client.dart 2>&1 | tee .sisyphus/evidence/task-6-analyze.txt
    Expected: 0 issues found

  Scenario: Tests GREEN
    Tool: Bash | flutter test test/data/planner_api_client_test.dart 2>&1 | tee .sisyphus/evidence/task-6-green.txt
    Expected: "All tests passed"
  ```

---

- [x] 7. **PlannerRepositoryImpl (DioPlannerRepository)**

  **What to do**:
  - Create `lib/data/repositories/planner_repository_impl.dart`
  - Class `PlannerRepositoryImpl implements PlannerRepository`:
    - Constructor: `PlannerRepositoryImpl({required this.apiClient})`
    - `@override Future<bool> submitCheckin(CheckinData)` — delegates to `apiClient.submitCheckin(data)`
  - UPDATE `lib/data/data.dart` to add: `export 'repositories/planner_repository_impl.dart';`
  - Analyzer: `flutter analyze --no-fatal-infos`
  - Save to `.sisyphus/evidence/task-7-repo-impl.txt`

  **References**: `lib/domain/repositories/planner_repository.dart`, `lib/data/datasources/planner_api_client.dart`
  **Must NOT do**: Do NOT modify `lib/domain/repositories/planner_repository.dart`.

  **Recommended Agent Profile**: `quick` — simple delegation.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 2
  - **Blocks**: T8 | **Blocked By**: T2, T6

  **Acceptance Criteria**:
  - [ ] `planner_repository_impl.dart` exists, implements `PlannerRepository`
  - [ ] `lib/data/data.dart` exports it
  - [ ] Analyzer: 0 errors

  **QA Scenarios**:
  ```
  Scenario: Repo impl analyzer OK
    Tool: Bash | flutter analyze --no-fatal-infos lib/data/repositories/planner_repository_impl.dart 2>&1 | tee .sisyphus/evidence/task-7.txt
    Expected: 0 issues found
  ```

---

- [x] 8. **CheckinProvider tests (TDD - RED)**

  **What to do**:
  - Create `test/presentation/checkin_provider_test.dart`
  - State definition: `enum CheckinState { initial, loading, success, error }` + `class CheckinNotifierState { final state, message? }`
  - Test cases (3, must FAIL initially):
    1. Initial state is initial
    2. submitCheckin → loading → success with "오늘의 AI 플래너가 생성되었습니다!"
    3. submitCheckin → loading → error with exception message
  - Use `ProviderContainer` + `Provider.override` with `MockPlannerRepository`
  - Save to `.sisyphus/evidence/task-8-provider-tests-red.txt`

  **Must NOT do**: Do NOT create provider implementation yet.

  **Recommended Agent Profile**: `unspecified-high` — Riverpod StateNotifier testing.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 2
  - **Blocks**: T9 | **Blocked By**: T2, T4, T7

  **Acceptance Criteria**:
  - [ ] 3+ test cases
  - [ ] Analyzer: 0 errors
  - [ ] `flutter test` → FAILS

  **QA Scenarios**:
  ```
  Scenario: Provider tests RED
    Tool: Bash | flutter test test/presentation/checkin_provider_test.dart 2>&1 | tee .sisyphus/evidence/task-8.txt
    Expected: Compilation fails or 1+ assertion fails
  ```

---

- [x] 9. **CheckinProvider implementation (TDD - GREEN)**

  **What to do**:
  - Create `lib/presentation/providers/checkin_provider.dart`
  - State: `enum CheckinState { initial, loading, success, error }` + `class CheckinNotifierState { final state, message? }`
  - `class CheckinNotifier extends StateNotifier<CheckinNotifierState>`:
    - `submitCheckin(CheckinData data) async`: loading → try→success or catch→error
    - Success message: `"오늘의 AI 플래너가 생성되었습니다!"`
  - Providers: `plannerRepositoryProvider` + `checkinProvider` (StateNotifierProvider)
  - Analyzer + tests pass
  - Save to `.sisyphus/evidence/task-9-provider-green.txt`

  **References**: `lib/domain/domain.dart`, `lib/data/data.dart`, `test/presentation/checkin_provider_test.dart`
  **Must NOT do**: Do NOT import `package:life_log_v7/lib/...`; use barrel exports.

  **Recommended Agent Profile**: `unspecified-high` — Riverpod StateNotifier with DI.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 3
  - **Blocks**: T10, T11 | **Blocked By**: T2, T4, T7

  **Acceptance Criteria**:
  - [ ] CheckinNotifier extends StateNotifier, state transitions correct
  - [ ] Contains message "오늘의 AI 플래너가 생성되었습니다!"
  - [ ] checkinProvider registered
  - [ ] Analyzer: 0 errors
  - [ ] `flutter test test/presentation/checkin_provider_test.dart` → ALL PASS

  **QA Scenarios**:
  ```
  Scenario: Provider analyzer passes
    Tool: Bash | flutter analyze --no-fatal-infos lib/presentation/providers/checkin_provider.dart 2>&1 | tee .sisyphus/evidence/task-9-analyze.txt
    Expected: 0 issues found

  Scenario: Provider tests GREEN
    Tool: Bash | flutter test test/presentation/checkin_provider_test.dart 2>&1 | tee .sisyphus/evidence/task-9-green.txt
    Expected: "All tests passed"
  ```

---

- [x] 10. **CheckinScreen widget tests (TDD - RED)**

  **What to do**:
  - Create `test/presentation/checkin_screen_test.dart`
  - Test cases (6-8, must FAIL initially):
    1. Screen shows 5 energy star buttons
    2. Screen shows 5 mood emoji buttons
    3. Screen shows 4 focus mode chips
    4. Screen shows submit button
    5. Tapping a star selects it
    6. Tapping an emoji selects it
    7. Tapping a focus chip selects it
    8. Submit button disabled in loading
  - Wrap in `ProviderScope` with `Provider.override` for mock provider
  - Save to `.sisyphus/evidence/task-10-screen-tests-red.txt`

  **Must NOT do**: Do NOT create screen implementation yet.

  **Recommended Agent Profile**: `unspecified-high` — Widget test with Provider override.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 3
  - **Blocks**: T11 | **Blocked By**: T4

  **Acceptance Criteria**:
  - [ ] 6-8 widget tests in file
  - [ ] Analyzer: 0 errors
  - [ ] `flutter test` → FAILS

  **QA Scenarios**:
  ```
  Scenario: Widget tests RED
    Tool: Bash | flutter test test/presentation/checkin_screen_test.dart 2>&1 | tee .sisyphus/evidence/task-10.txt
    Expected: Compilation fails or test assertions fail
  ```

---

- [x] 11. **CheckinScreen UI implementation (TDD - GREEN)**

  **What to do**:
  - Create `lib/presentation/screens/checkin_screen.dart`
  - **Scaffold** wrapping everything (required for ScaffoldMessenger/Snackbar)
  - **Stack** children:
    1. Background: `Container` with `LinearGradient(0xFF0F2027 → 0xFF203A43 → 0xFF2C5364)`
    2. Center: `SingleChildScrollView` → `ClipRRect` → `BackdropFilter(sigmaX:15, sigmaY:15)` → `Container` (white 0.05 opacity, border 0.1)
  - Inside card `Column`:
    - Heading: "Today's Check-in" with `GoogleFonts.inter` bold white
    - **Energy Stars**: `Row` with 5 `IconButton(Icons.star)` — selected=amber, 1-5 levels, tap sets state
    - **Mood Emojis**: `Row` with 5 text buttons — 😡😢😐🙂😄 — tap selects (fontSize 36 active, 28 inactive)
    - **Focus Chips**: `Wrap` with 4 `ActionChip` — DeepWork/Email/Meeting/Study — active=green.bg, white text
    - **Submit Button**: `ElevatedButton` green.bg, `onPressed: loading ? null : () -> onSubmit()`, disabled when loading
  - **State**: private StatefulWidget with `selectedEnergy=3` (default), `selectedMood`, `selectedFocus`, `loading`
  - **On Submit**: loading=true → read `checkinProvider` → submitCheckin → on success show snackbar "오늘의 AI 플래너가 생성되었습니다!"
  - Analyzer + screen tests pass
  - Update `lib/presentation/presentation.dart` barrel: add `export 'screens/checkin_screen.dart';`
  - Save to `.sisyphus/evidence/task-11-screen-green.txt`

  **References**: `lib/presentation/providers/checkin_provider.dart` (checkinProvider), `lib/domain/entities/checkin_data.dart`, `test/presentation/checkin_screen_test.dart`
  **Must NOT do**: Do NOT import from `package:life_log_v7/lib/...`.

  **Recommended Agent Profile**: `visual-engineering` — UI-heavy: glassmorphism, gradients, custom form controls.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 3
  - **Blocks**: T12 | **Blocked By**: T4, T9

  **Acceptance Criteria**:
  - [ ] Deep Abyss gradient background
  - [ ] Glassmorphism card with ClipRRect + BackdropFilter(sigma:15) + white 0.05
  - [ ] 5 selectable star buttons, 5 emoji buttons, 4 focus chips
  - [ ] Green submit button disabled during loading
  - [ ] Success snackbar: "오늘의 AI 플래너가 생성되었습니다!"
  - [ ] Analyzer: 0 errors for this file
  - [ ] `flutter test test/presentation/checkin_screen_test.dart` → ALL PASS

  **QA Scenarios**:
  ```
  Scenario: Screen analyzer passes
    Tool: Bash | flutter analyze --no-fatal-infos lib/presentation/screens/checkin_screen.dart 2>&1 | tee .sisyphus/evidence/task-11.txt
    Expected: 0 issues found

  Scenario: Screen tests GREEN
    Tool: Bash | flutter test test/presentation/checkin_screen_test.dart 2>&1 | tee -a .sisyphus/evidence/task-11.txt
    Expected: "All tests passed"
  ```

---

- [x] 12. **Wire main.dart + update widget_test.dart**

  **What to do**:
  - REPLACE `lib/main.dart`:
    - `ProviderScope` wrapping MyApp
    - MaterialApp: dark theme (`Brightness.dark`), `colorSchemeSeed: Colors.green`, `textTheme: GoogleFonts.interTextTheme()`
    - home: `CheckinScreen`
    - imports: `flutter/material.dart`, `flutter_riverpod`, `google_fonts`, `life_log_v7/presentation/presentation.dart`
  - REPLACE `test/widget_test.dart`:
    - Test `CheckinScreen` loads (pumpWidget with ProviderScope, find text "Today's Check-in")
  - Analyzer pass
  - Save to `.sisyphus/evidence/task-12-main-wire.txt`

  **References**: `lib/presentation/presentation.dart` (exports CheckinScreen)
  **Must NOT do**: Do NOT modify domain files.

  **Recommended Agent Profile**: `quick` — simple wiring task.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave 3
  - **Blocks**: T13 | **Blocked By**: T11

  **Acceptance Criteria**:
  - [ ] ProviderScope, dark theme, GoogleFonts.interTextTheme(), CheckinScreen home
  - [ ] widget_test.dart tests CheckinScreen
  - [ ] Analyzer: 0 errors

  **QA Scenarios**:
  ```
  Scenario: main.dart compiles
    Tool: Bash | flutter analyze --no-fatal-infos lib/main.dart 2>&1 | tee .sisyphus/evidence/task-12.txt
    Expected: 0 issues found

  Scenario: Main runs (quick visual sanity check)
    Tool: Bash | flutter analyze --no-fatal-infos test/widget_test.dart 2>&1 | tee -a .sisyphus/evidence/task-12.txt
    Expected: 0 issues found
  ```

---

- [x] 13. **Final verification: flutter pub get + flutter analyze + flutter test**

  **What to do**:
  - Run `flutter pub get`
  - Run `flutter analyze --no-fatal-infos` — capture full output
  - Run `flutter test` — capture full output
  - Verify: 0 issues in analyzer, all tests pass
  - Save combined output to `.sisyphus/evidence/task-13-final-verify.txt`

  **Must NOT do**: None — pure verification.

  **Recommended Agent Profile**: `quick`.

  **Parallelization**:
  - **Can Run In Parallel**: NO | **Parallel Group**: Wave FINAL
  - **Blocks**: None | **Blocked By**: T12

  **Acceptance Criteria**:
  - [ ] `flutter pub get` → exit 0
  - [ ] `flutter analyze --no-fatal-infos` → 0 issues
  - [ ] `flutter test` → All tests passed
  - [ ] Evidence: `.sisyphus/evidence/task-13-final-verify.txt`

  **Verification Commands**:
  ```bash
  flutter pub get && flutter analyze --no-fatal-infos 2>&1 | grep -c "0 issues"
  flutter test 2>&1 | grep "All tests passed"
  ```

  **QA Scenarios**:
  ```
  Scenario: Full analysis pass
    Tool: Bash | flutter pub get && flutter analyze --no-fatal-infos 2>&1 | tee .sisyphus/evidence/task-13.txt
    Expected: "0 issues found"

  Scenario: All tests pass
    Tool: Bash | flutter test 2>&1 | tee -a .sisyphus/evidence/task-13.txt
    Expected: "All tests passed"
  ```

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present results to user before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`. Read plan end-to-end. For "Must Have": verify implementation exists. For "Must NOT Have": search for forbidden patterns. Output: `VERDICT`
- [x] F2. **Code Quality Review** — `unspecified-high`. Run `flutter analyze` + `flutter test`. Check for `// ignore`, empty catches, unused imports, AI slop.
- [x] F3. **Real Manual QA** — `unspecified-high`. Execute EVERY QA scenario, capture evidence to `.sisyphus/evidence/final-qa/`.
- [x] F4. **Scope Fidelity Check** — `deep`. Verify 1:1 spec vs implementation. Check "Must NOT do" compliance. Detect cross-task contamination.

---

## Success Criteria

### Final Checklist
- [x] All "Must Have" items present in code
- [x] All "Must NOT Have" items absent
- [x] `flutter analyze --no-fatal-infos` → 0 issues
- [x] `flutter test` → All tests passed
- [x] `lib/domain/` files unmodified from original


