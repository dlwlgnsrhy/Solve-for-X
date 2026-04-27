Implement a Flutter app called "SFX Imjong Care" with the following requirements:

## Product
- Name: SFX Imjong Care (임종 케어)
- Concept: Trendy "positive will" / life-end business card for MZ generation
- MVP: A 2-screen app where users input 3 values and 1-line will, then generate a flashy 3D neon digital will card shareable to Instagram

## Requirements

### 1. Clean Architecture Folder Structure
```
lib/
  core/
    theme/
      app_theme.dart          # Dark mode + Neon color palette
      neon_colors.dart        # Neon color definitions
    constants/
      app_constants.dart      # App-wide constants, EULA text
  features/
    will_input/
      presentation/
        screens/
          will_input_screen.dart   # Input form screen
        widgets/
          value_input_field.dart   # Reusable neon text field
          eula_checkbox.dart       # EULA agreement checkbox
      domain/
        entities/
          will_card.dart           # WillCard entity (name, 3 values, 1-line will)
      data/
        models/
          will_card_model.dart
    will_card/
      presentation/
        screens/
          will_card_screen.dart    # Card rendering screen
        widgets/
          neon_3d_card.dart        # 3D neon card widget with glow effects
          card_share_button.dart   # Share button widget
  main.dart
```

### 2. Dependencies (pubspec.yaml)
Add these to pubspec.yaml:
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  flutter_riverpod: ^2.5.1
  flutter_animate: ^4.5.0
  share_plus: ^10.0.2
  path_provider: ^2.1.3
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
```

### 3. Theme (Dark Mode + Neon)
- Background: #0a0a0f (deep dark)
- Neon accent colors: #00ff88 (green), #ff00aa (pink), #00ddff (cyan)
- Use Google Fonts: "Orbitron" for headings, "Inter" for body
- All UI should feel cyberpunk/neon trendy

### 4. Entity - WillCard
Use the latest Riverpod Generator syntax with @riverpod annotation.
```dart
@Riverpod(keepAlive: true)
class WillFormController extends _$WillFormController {
  String name = '';
  List<String> values = ['', '', ''];
  String will = '';
  
  void updateName(String value) { name = value; }
  void updateValue(int index, String value) { values[index] = value; }
  void updateWill(String value) { will = value; }
  
  bool get isValid => name.trim().isNotEmpty && values.every((v) => v.trim().isNotEmpty) && will.trim().isNotEmpty;
}
```

### 5. Screen 1 - WillInputScreen
- Title: "SFX 임종 케어" with neon glow effect
- Fields:
  - Name input (text field)
  - 3 "Values" inputs (my values / 내 가치) - neon styled text fields
  - 1-line will input (한 줄 유언) - neon styled text field
- EULA checkbox at bottom with link-style text "이용약관 및 EULA 동의"
  - EULA text should be displayed in a scrollable view
  - User cannot proceed without checking
- "Generate Card" button - neon styled, only enabled when form is valid AND EULA is checked
- Navigation to Screen 2 on button tap

### 6. Screen 2 - WillCardRenderScreen
- Display a 3D card with:
  - Card title: "SFX 임종 케어"
  - User's name prominently displayed
  - 3 values displayed with neon icons/bullet points
  - 1-line will displayed with emphasis
- Neon glow effects, 3D transform (use Transform.scale or AnimatedContainer with perspective)
- Animated entrance (use flutter_animate)
- Share button at bottom: "이 카드 공유하기" - uses share_plus
- Back button to return to input screen

### 7. Apple App Store Compliance
- EULA must be shown and agreed BEFORE using the app
- NO openAppSettings() calls - handle permission denials gracefully in-app
- EULA text should be comprehensive enough for App Store review

### 8. IMPORTANT CONSTRAINTS
- ONLY implement these 2 screens (MVP scope)
- Do NOT add any extra features
- Do NOT use old Riverpod syntax (no autoDispose, no old-style family)
- Do NOT leave dead code
- Run flutter analyze mentally after writing each file
- Use null-safe Dart throughout
- Use const constructors where possible

Start by updating pubspec.yaml with dependencies, then implement each file in order. After all files are created, run flutter analyze to verify.
