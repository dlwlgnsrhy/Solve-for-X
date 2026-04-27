# SFX Imjong Care

A trendy 2-screen Flutter app for generating digital "positive will" cards for the MZ generation.

## Features (MVP)

- **Will Input Screen**: Enter your name, 3 values, and a 1-line will with a cyberpunk/neon UI
- **Card Render Screen**: View your generated 3D neon card with animated entrance
- **Share**: Share your card via the device's native share sheet
- **EULA Compliance**: In-app EULA agreement before using the app

## Architecture

Clean Architecture with Riverpod state management:
- `core/` - Theme, constants
- `features/will_input/` - Input form (domain, data, presentation)
- `features/will_card/` - Card rendering (presentation)

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```
