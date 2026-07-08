# Spanx — Goal & Budget Tracking App

A Flutter mobile application for personal goal setting, budget tracking, and community engagement. Built with GetX state management.

## Stack

- **Framework**: Flutter (Dart ≥ 3.8.0)
- **State management**: GetX
- **Backend**: `https://goalshare-backend-production.up.railway.app/api/v1`
- **Local storage**: Hive (todos, offline cache)
- **In-app purchases**: `in_app_purchase` package

## Project structure

```
lib/
├── main.dart                  # Entry point
├── bindings/bindings.dart     # GetX DI
├── routes/                    # GetX routing (30+ named routes)
├── core/
│   ├── config/                # Environment config
│   ├── const/                 # Colors, fonts, sizes
│   ├── data/repositories/     # Repository pattern
│   ├── network_caller/        # API client & endpoints
│   └── global_widgets/        # Shared UI components
└── features/                  # Feature-first modules
    ├── auth/                  # Login, signup, OTP, reset
    ├── home/
    ├── mission/               # Goals tracking
    ├── budget/
    ├── vision_board/
    ├── bible/                 # Bible reading (bible-api.com)
    ├── subscription/
    ├── chat_tab/              # ⚠️ Currently uses mock data
    └── ...
```

## Running locally (outside Replit)

```bash
flutter pub get
flutter run              # debug on connected device/emulator
flutter build apk        # Android release (requires key.properties)
flutter build ios        # iOS release (requires Xcode + provisioning)
```

> **Note**: This project requires the Flutter SDK. It is not configured to run inside Replit's web preview — use Android Studio, VS Code with Flutter extension, or a physical device.

## Android release signing

Place a `key.properties` file at `android/key.properties` with:
```
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../path/to/keystore.jks
```
Without this file, the app builds with debug signing (safe for development).

## App Store readiness (~70-75%)

**Complete**: Auth flow, missions/goals, budget, vision board, subscriptions, Bible reader, profile management, social (follow/unfollow).

**Needs work before shipping**:
- Chat tab — currently mock data only (Task #2)
- Onboarding controller has unimplemented `onInit` (Task #3)
- No automated tests (Task #4)
- App Store assets (screenshots, description, privacy policy) not yet created

## User preferences

_Add any preferences here as the project evolves._
