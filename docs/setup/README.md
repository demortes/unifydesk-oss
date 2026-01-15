# Setup Guide

## Prerequisites

### Required Software

#### Flutter SDK
- **Version**: 3.19.0 or higher
- **Channel**: Stable recommended
- **Installation**: Follow [official Flutter installation guide](https://flutter.dev/docs/get-started/install)

#### Dart SDK
- **Version**: 3.3.0 or higher (included with Flutter)

#### Git
- For version control and dependency management

### Platform-Specific Requirements

#### Android Development
- **Android Studio**: Latest stable version
- **Android SDK**: API Level 21 (Android 5.0) or higher
- **Java**: JDK 17 (OpenJDK recommended)
- **Android Device/Emulator**: For testing

#### iOS Development (macOS only)
- **Xcode**: 15.0 or higher
- **CocoaPods**: For dependency management
- **iOS Simulator**: Included with Xcode
- **Apple Developer Account**: For device testing (free account OK)

#### Windows Desktop
- **Visual Studio 2022**: Community edition or higher
- **Desktop development with C++** workload
- **Windows 10 SDK** (10.0.17763.0 or higher)

#### macOS Desktop
- **Xcode**: 15.0 or higher
- **Xcode Command Line Tools**
- **CocoaPods** (for some dependencies)

#### Linux Desktop
- **Clang**: C++ compiler
- **CMake**: 3.10 or higher
- **Ninja**: Build system
- **pkg-config**
- **GTK 3.0 development libraries**

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev

# Fedora
sudo dnf install clang cmake ninja-build gtk3-devel
```

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Demortes/unifydesk.git
cd unifydesk
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Platform-Specific Setup

#### Android

1. Open Android Studio
2. Configure Android SDK (API 21+)
3. Create a virtual device or connect a physical device
4. Enable USB debugging (physical device)

```bash
# Verify Android setup
flutter doctor -v
```

#### iOS (macOS only)

1. Open Xcode
2. Install Xcode Command Line Tools:
```bash
xcode-select --install
```

3. Install CocoaPods:
```bash
sudo gem install cocoapods
```

4. Setup iOS pods:
```bash
cd ios
pod install
cd ..
```

5. Open iOS Simulator or connect a device

```bash
# Verify iOS setup
flutter doctor -v
```

#### Windows Desktop

1. Install Visual Studio 2022
2. Select "Desktop development with C++" workload
3. No additional Flutter setup needed

```bash
# Verify Windows setup
flutter doctor -v
```

#### macOS Desktop

1. Xcode should already be installed (for iOS)
2. No additional setup needed

```bash
# Verify macOS setup
flutter doctor -v
```

#### Linux Desktop

After installing system dependencies:

```bash
# Verify Linux setup
flutter doctor -v
```

## Running the Application

### Development Mode

```bash
# List available devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run with specific flavor (if configured)
flutter run --flavor dev

# Run with debug logging
flutter run -v
```

### Platform-Specific Commands

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Chrome (for testing)
flutter run -d chrome
```

## Building for Production

### Android

#### APK (for testing)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release

# Or build archive in Xcode:
# Open ios/Runner.xcworkspace in Xcode
# Product > Archive
```

### Windows Desktop

```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

### macOS Desktop

```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### Linux Desktop

```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## Development Environment Setup

### Recommended IDE

#### Visual Studio Code
1. Install VS Code
2. Install Flutter extension
3. Install Dart extension
4. Configure settings:

```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "editor.formatOnSave": true,
  "dart.lineLength": 100,
  "editor.rulers": [100]
}
```

#### Android Studio / IntelliJ IDEA
1. Install Android Studio or IntelliJ IDEA
2. Install Flutter plugin
3. Install Dart plugin
4. Configure Flutter SDK path

### Code Style

The project follows official Dart style guide with some customizations:

```yaml
# analysis_options.yaml (example)
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_final_fields
    - avoid_print
    - always_declare_return_types
```

Format code before committing:
```bash
dart format .
```

Run analyzer:
```bash
flutter analyze
```

## Testing Setup

### Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/features/mail/mail_test.dart

# With coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

### Test Coverage

Generate coverage report:
```bash
# Generate coverage
flutter test --coverage

# View coverage (requires lcov)
# macOS
brew install lcov
# Ubuntu/Debian
sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Troubleshooting

### Common Issues

#### "Flutter command not found"
- Add Flutter to PATH:
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

#### Android SDK not found
- Configure in Android Studio: Tools > SDK Manager
- Or set ANDROID_HOME environment variable

#### iOS build fails
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### Linux build fails (GTK errors)
```bash
sudo apt-get install libgtk-3-dev libblkid-dev liblzma-dev
```

#### Windows build fails
- Ensure Visual Studio 2022 with C++ workload is installed
- Run as administrator if permission issues

### Clean Build

```bash
# Clean Flutter build
flutter clean

# Get dependencies again
flutter pub get

# For iOS/macOS
cd ios
pod install
cd ..
```

## Environment Variables

Create `.env` file for development (not committed to git):

```env
# Development settings
DEBUG_MODE=true
LOG_LEVEL=verbose

# API keys (if needed for testing)
# Note: For production, these should come from secure storage
```

## Database Setup

The app uses local SQLite database. No setup required - database is created automatically on first run.

For development, you can reset database by clearing app data or:

```bash
# Find app data location
flutter run --verbose

# Clear app data through device settings
# Or reinstall app
```

## Debugging

### Enable Debug Logging

In `lib/core/utils/logger.dart`:
```dart
Logger.level = Level.verbose; // or Level.debug
```

### Platform-Specific Debugging

#### Android
```bash
# View Android logs
adb logcat | grep Flutter
```

#### iOS
- Use Xcode Console
- Or view device logs in Console.app

#### Desktop
- Logs printed to terminal running `flutter run`

### Remote Debugging

```bash
# Get debug URL
flutter run --verbose

# Opens DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## CI/CD Setup

See `.github/workflows/ci.yml` for GitHub Actions configuration.

### Local CI Testing

```bash
# Run all checks locally
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Desktop Support](https://flutter.dev/desktop)
- [Platform-Specific Code](https://flutter.dev/docs/development/platform-integration/platform-channels)

## Getting Help

- **Documentation**: Check [docs/](../) folder
- **Issues**: Create a GitHub issue
- **Discussions**: Join GitHub Discussions
- **Flutter Community**: [Flutter Discord](https://discord.gg/flutter)
