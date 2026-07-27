# GabiFlow Mobile - Development Commands

## Flutter Development Commands

### Running the Application
```bash
# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices

# Run in release mode (optimized)
flutter run --release

# Run with specific flavor/environment
flutter run --dart-define=ENVIRONMENT=development
```

### Hot Reload and Restart
- **r** - Hot reload (while app is running)
- **R** - Hot restart (while app is running)
- **q** - Quit the running application

### Building the Application
```bash
# Build APK for Android
flutter build apk --release

# Build App Bundle for Android (Play Store)
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Build for iOS Simulator
flutter build ios --debug --simulator
```

### Code Generation
```bash
# Run build_runner for code generation (Freezed, JSON serialization)
flutter pub run build_runner build

# Run with delete conflicting outputs
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/path/to/test_file.dart

# Run tests in specific directory
flutter test test/unit/
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Format specific file
dart format lib/main.dart

# Check formatting without changing files
dart format --set-exit-if-changed .
```

### Dependency Management
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Upgrade to latest versions (major versions)
flutter pub upgrade --major-versions

# Clean and get dependencies
flutter clean && flutter pub get
```

### Project Maintenance
```bash
# Clean build artifacts
flutter clean

# Clean and rebuild
flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

### Debugging
```bash
# Run with verbose output
flutter run -v

# Check Flutter installation
flutter doctor

# Check detailed Flutter installation
flutter doctor -v
```

## Darwin/macOS Specific Commands

### iOS Development
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Install iOS dependencies (CocoaPods)
cd ios && pod install && cd ..

# Clean iOS build
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

### Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

## Git Commands
```bash
# Check status
git status

# Add changes
git add .

# Commit with message
git commit -m "feat: add new feature"

# Push to remote
git push origin feature-branch

# Pull latest changes
git pull origin main
```

## Utility Scripts
```bash
# Make script executable
chmod +x hot_restart.sh

# Run hot restart script
./hot_restart.sh
```

## Common Workflows

### Starting Development
1. `flutter pub get` - Get dependencies
2. `flutter pub run build_runner build --delete-conflicting-outputs` - Generate code
3. `flutter run` - Start the app

### Before Committing
1. `dart format .` - Format code
2. `flutter analyze` - Check for issues
3. `flutter test` - Run tests

### Full Clean Build
```bash
flutter clean && \
flutter pub get && \
flutter pub run build_runner build --delete-conflicting-outputs && \
flutter run
```