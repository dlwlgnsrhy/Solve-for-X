# SFX Legacy Vault - Setup Instructions

## Overview
SFX Legacy Vault is a Dead Man's Switch application built with Flutter + Riverpod.
It stores encrypted data and delivers it to a designated recipient if the user fails
to periodically confirm their status.

## Prerequisites
- Flutter SDK 3.29.3+ (Dart 3.7.2+)
- Node.js 18+ (for Cloud Functions)
- Firebase CLI: `npm install -g firebase-tools`
- iOS development environment (Xcode)

## 1. Firebase Setup

### Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: `sfx-legacy-vault`
3. Enable **Authentication**:
   - Email/Password provider
   - Apple provider (OAuth)
4. Enable **Firestore Database**:
   - Start in test mode (update security rules after setup)
5. Enable **Cloud Functions**

### Configure Firebase in the App
1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Firebase:
   ```bash
   cd /Users/apple/development/soluni/sfx-imjong-care/sfx_legacy_vault
   flutterfire configure --project=sfx-legacy-vault
   ```
   This will auto-generate `lib/core/config/firebase_options.dart` with real credentials.

### Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Cloud Functions Setup
```bash
cd functions
npm install
firebase login
firebase use <your-project-id>

# Set email service credentials
firebase functions:config:set nodemailer.host="smtp.gmail.com"
firebase functions:config:set nodemailer.port="587"
firebase functions:config:set nodemailer.user="your-email@gmail.com"
firebase functions:config:set nodemailer.pass="your-app-password"

# Deploy
firebase deploy --only functions
```

## 2. iOS Setup

### Update Info.plist
Add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Not used</string>
```

### Apple Sign-In Configuration
1. In Xcode: Signing & Capabilities > + Capability > Sign In with Apple
2. Ensure bundle ID matches `com.sfx.sfxLegacyVault`

## 3. Run the App

```bash
flutter pub get
flutter run
```

## 4. Build for Release

```bash
# iOS debug (no codesign)
flutter build ios --debug --no-codesign

# iOS release
flutter build ios --release
```

## Architecture

```
lib/
  main.dart                          # App entry point
  core/
    config/firebase_options.dart     # Firebase config (placeholder)
    constants/app_colors.dart        # Neon theme colors
    services/encryption_service.dart # AES-256 encryption
    theme/app_theme.dart             # Dark neon theme
    utils/date_utils.dart            # Date/deadline helpers
  features/
    onboarding/                      # EULA + Privacy Policy
    auth/                            # Firebase Auth (email + Apple)
    vault/                           # Vault CRUD + dashboard
functions/
  index.js                           # Cloud Functions (deadline checker)
```

## Firestore Schema
```
users/{userId}/
  - lastActiveAt: Timestamp
  - targetEmail: String
  - encryptedData: String (AES-256 encrypted JSON)
  - deadlineDays: int (7-30)
  - createdAt: Timestamp
  - status: "active" | "alerted" | "sent"
```

## Key Design Decisions
- **Client-side encryption**: AES-256-CBC with SHA-256 key derivation
- **Passphrase storage**: Only on device (shared_preferences), never on server
- **Auto-ping**: Server updated every time app opens
- **Scheduled check**: Cloud Function runs every 60 minutes
- **Delivery**: Email via Nodemailer (configurable SMTP)
