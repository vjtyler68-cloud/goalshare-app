# Spanx - Goal & Budget Tracking App

A comprehensive Flutter mobile application for personal goal setting, budget tracking, and community engagement. Built with GetX state management for a reactive and scalable architecture.

## 📱 Features

### Core Features
- **Authentication System**: Complete auth flow with email/password, OTP verification, password reset
- **User Profile Management**: Setup and edit profile with image upload
- **Goal Setting & Tracking**: Create missions, track progress, manage client details
- **Budget Management**: Set budgets, track income/expenses, view spending analytics
- **Vision Board**: Create and manage visual goal boards
- **Motivational Nudges**: Daily motivations and affirmations
- **Community Features**: Follow users, view suggested people, community profiles
- **Analytics Dashboard**: Track time spent, analyze trends, view reports
- **Priming & Mission Details**: Pre-session preparation and detailed mission tracking
- **Subscription Management**: View and manage subscription plans
- **Todo Management**: Daily todo lists with local Hive storage
- **Offline Support**: Internet connectivity detection and handling

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                      # App entry point
├── bindings/                      # GetX dependency injection
│   └── bindings.dart
├── routes/                        # Navigation setup
│   ├── app_routes.dart           # Route constants
│   └── app_pages.dart            # Route definitions
├── core/                         # Core infrastructure
│   ├── config/                   # Environment configuration
│   ├── const/                    # App constants (colors, fonts, sizes)
│   ├── data/                     # Data layer
│   │   └── repositories/         # Repository pattern implementations
│   ├── error/                    # Error & exception handling
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── global_widgets/           # Reusable UI components
│   │   ├── loading_state_widget.dart
│   │   ├── error_state_widget.dart
│   │   ├── empty_state_widget.dart
│   │   └── [other widgets...]
│   ├── local/                    # Local storage wrapper
│   ├── network_caller/           # API client & endpoints
│   │   ├── endpoints.dart
│   │   ├── network_config.dart   # Legacy HTTP client
│   │   └── network_config_v2.dart # Improved HTTP client
│   ├── services/                 # Business services
│   │   ├── no_internet/          # Connectivity monitoring
│   │   └── token_service.dart    # JWT token management
│   ├── user_info/                # User state management
│   └── utils/                    # Utility classes
│       └── result.dart           # Result type for API responses
└── features/                     # Feature modules
    ├── auth/                     # Authentication
    ├── home/                     # Home dashboard
    ├── mission/                  # Goal/Mission management
    ├── mybudget/                 # Budget tracking
    ├── profile_tab/              # User profile
    ├── analytics_tab/            # Analytics & reports
    ├── community_profile/        # Community features
    ├── vision_board/             # Vision board
    ├── motivationalNudges/       # Motivations
    └── [23 total feature modules]
```

Each feature follows a consistent structure:
```
feature/
├── controller/          # GetX controllers (state management)
├── model/              # Data models
├── screen/             # UI screens
└── [optional] ui/      # Additional UI components
```

## 🛠️ Tech Stack

### Framework & Language
- **Flutter**: 3.8.0+ (Dart SDK: >=3.8.0 <4.0.0)
- **Dart**: Null-safe

### State Management
- **GetX** (^4.7.2): Controllers, reactive state, dependency injection, routing

### Networking & Data
- **http**: REST API communication
- **internet_connection_checker** (^3.0.1): Network connectivity monitoring
- **shared_preferences** (^2.3.3): Key-value storage
- **hive** (^2.2.3) & **hive_flutter** (^1.1.0): Local database for todos

### UI & Design
- **flutter_screenutil** (^5.9.3): Responsive sizing
- **google_fonts** (^6.3.1): Typography
- **flutter_svg** (^2.2.0): SVG rendering
- **cached_network_image** (^3.4.1): Image caching
- **loading_animation_widget** (^1.3.0): Loading indicators
- **shimmer** (^3.0.0): Skeleton loading
- **carousel_slider** (^5.1.1): Image carousels
- **flutter_staggered_grid_view** (^0.7.0): Masonry layouts

### Charts & Data Visualization
- **syncfusion_flutter_charts** (^31.1.17): Advanced charting
- **percent_indicator** (^4.2.1): Progress indicators

### Additional Features
- **image_picker** (^1.2.0): Camera & gallery access
- **video_player** (^2.10.0): Video playback
- **url_launcher** (^6.3.2): External URLs
- **pinput** (^5.0.1): OTP input
- **table_calendar** (^3.2.0): Calendar views
- **intl** (^0.20.2): Internationalization
- **logger** (^2.6.2): Advanced logging
- **fluttertoast** (^8.2.12): Toast notifications
- **flutter_easyloading** (^3.0.5): Loading overlays

### Development Tools
- **flutter_lints** (^6.0.0): Linting rules
- **build_runner** (^2.4.8): Code generation
- **hive_generator** (^2.0.1): Hive model generation
- **flutter_launcher_icons** (^0.14.4): App icon generation
- **device_preview** (^1.3.1): Multi-device preview

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.0 or higher
- Dart SDK 3.8.0 or higher
- Xcode (for iOS development)
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd spanx
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (if models change)
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Setup environment** (optional)
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Run the app**
   ```bash
   # Development
   flutter run

   # With environment variables
   flutter run --dart-define=BASE_URL=https://your-api.com/api/v1

   # Release build
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

## 🌐 Environment Configuration

Create a `.env` file (or use `--dart-define`) for environment-specific configuration:

```env
BASE_URL=https://goal-share-backend.vercel.app/api/v1
APP_NAME=Spanx
APP_VERSION=0.1.0
ENABLE_LOGGING=true
ENABLE_DEBUG_MODE=false
```

**Using dart-define (recommended for production):**
```bash
flutter run --dart-define=BASE_URL=https://api.production.com
```

## 📊 State Management Flow

### GetX Architecture Pattern

1. **Controllers**: Manage business logic and state
   ```dart
   class HomeController extends GetxController {
     final RxBool isLoading = false.obs;
     final RxList<Data> items = <Data>[].obs;
     
     @override
     void onInit() {
       super.onInit();
       fetchData();
     }
     
     Future<void> fetchData() async { ... }
   }
   ```

2. **Bindings**: Dependency injection
   ```dart
   class AppBindings extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut<HomeController>(() => HomeController());
     }
   }
   ```

3. **Reactive UI**: Obx widgets auto-update
   ```dart
   Obx(() => Text(controller.data.value))
   ```

4. **Navigation**: Named routes with GetX
   ```dart
   Get.toNamed(AppRoutes.homeScreen);
   ```

### Improved Architecture (V2)

New files added for better scalability:
- **Repository Pattern**: `core/data/repositories/` - Separates data sources from business logic
- **Error Handling**: `core/error/` - Typed exceptions and failures
- **Result Type**: `core/utils/result.dart` - Type-safe API responses
- **State Widgets**: Standardized loading/error/empty states

## 🧪 Testing

### Setup Testing
```bash
# Add test dependencies in pubspec.yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.8
```

### Run Tests
```bash
# Unit tests
flutter test

# With coverage
flutter test --coverage

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 📦 Build & Release

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release

# Archive (for App Store)
open ios/Runner.xcworkspace
# Then: Product > Archive in Xcode
```

## 🐛 Known Issues & Improvements

### Completed Improvements ✅
- ✅ Added proper error handling with typed Failures
- ✅ Created standardized state widgets (loading/error/empty)
- ✅ Fixed route bug (editProfileScreen)
- ✅ Enhanced linting rules in analysis_options.yaml
- ✅ Added environment configuration support
- ✅ Implemented Result type for API responses
- ✅ Created improved NetworkConfigV2 with proper exception handling
- ✅ Added TokenService for better auth management
- ✅ Created example repository pattern (UserRepository)

### Recommended Next Steps 🔄
- [ ] Migrate all controllers to use repository pattern
- [ ] Replace NetworkConfig with NetworkConfigV2 throughout
- [ ] Add unit tests for repositories and controllers
- [ ] Implement JWT token refresh mechanism
- [ ] Add API response caching layer
- [ ] Integrate Firebase Analytics & Crashlytics
- [ ] Add dark mode support
- [ ] Implement multi-language support (i18n)
- [ ] Add biometric authentication
- [ ] Optimize images and assets

## 🔐 Security

- Tokens stored in SharedPreferences (consider flutter_secure_storage for production)
- API keys should be in `.env` (not committed to repo)
- HTTPS enforced for all API calls
- Input validation on all forms

## 📝 Code Style

This project follows the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with additional rules:
- Single quotes for strings
- Trailing commas for better diffs
- Const constructors where possible
- Comprehensive linting via `analysis_options.yaml`

Run linting:
```bash
flutter analyze
```

Format code:
```bash
dart format .
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] No lint errors (`flutter analyze`)
- [ ] All tests pass (`flutter test`)
- [ ] Comments added for complex logic
- [ ] Updated documentation if needed

## 📄 License

This project is private and proprietary. All rights reserved.

## 👥 Team & Support

- **Project Lead**: [Your Name]
- **Backend API**: `https://goal-share-backend.vercel.app`
- **Support Email**: support@spanx.app

## 📸 Screenshots

_Add screenshots here_

---

**Built with ❤️ using Flutter**
