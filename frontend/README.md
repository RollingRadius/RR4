# Fleet Management System - Flutter Frontend

Flutter frontend application for the Fleet Management System.

## Features

- User authentication (Email & Security Questions)
- Company management
- Clean architecture with Riverpod state management
- Material Design UI

## Setup

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart (>=3.0.0)
- Android Studio / Xcode (for mobile)

### Installation

```bash
# Navigate to frontend directory
cd E:\Projects\RR4\frontend

# Get dependencies
flutter pub get

# Run code generation (if needed)
# flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Or for specific platform
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS (Mac only)
```

### Configuration

Edit `lib/core/config/app_config.dart` to set your API base URL:

```dart
static const String apiBaseUrl = 'http://localhost:8000';
```

**Note:** For Android emulator, use: `http://10.0.2.2:8000`
**Note:** For iOS simulator, use: `http://localhost:8000`

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── core/
│   ├── config/                    # App configuration
│   ├── theme/                     # App theme
│   └── constants/                 # Constants
├── data/
│   ├── models/                    # Data models
│   └── services/                  # API services
├── providers/                     # Riverpod providers
├── presentation/
│   ├── screens/                   # UI screens
│   └── widgets/                   # Reusable widgets
└── routes/                        # Navigation routing
```

## Available Screens

1. **Login Screen** (`/login`)
   - Username and password login
   - Navigate to signup

2. **Signup Screen** (`/signup`)
   - Email-based or Security Questions signup
   - Form validation
   - Terms acceptance

3. **Dashboard Screen** (`/dashboard`)
   - User profile display
   - Logout functionality

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building

```bash
# Build APK (Android)
flutter build apk --release

# Build iOS (Mac only)
flutter build ios --release

# Build Web
flutter build web --release
```

## Troubleshooting

### Issue: "Target of URI doesn't exist"
```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: "Cannot connect to backend"
- Make sure backend is running on `http://localhost:8000`
- For Android emulator, change URL to `http://10.0.2.2:8000`
- Check CORS configuration in backend

### Issue: "Bad state: No element"
- Run `flutter clean`
- Delete `pubspec.lock`
- Run `flutter pub get`

## Next Steps

- Add security questions screen
- Add company selection flow
- Add email verification screen
- Improve UI/UX
- Add form validation feedback
- Add loading states
- Add error handling

## License

[License information]
