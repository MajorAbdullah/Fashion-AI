# Flutter Commands Reference

## Project & Setup

| Command | Description |
|---------|-------------|
| `flutter create <name>` | Creates a new Flutter project. |
| `flutter pub get` | Downloads all dependencies listed in `pubspec.yaml`. |
| `flutter pub upgrade` | Upgrades all dependencies to their latest compatible versions. |
| `flutter pub add <package>` | Adds a new dependency to `pubspec.yaml` and installs it. |
| `flutter pub remove <package>` | Removes a dependency from `pubspec.yaml`. |
| `flutter pub outdated` | Lists dependencies that have newer versions available. |
| `flutter pub cache repair` | Re-downloads all cached packages (fixes corrupted cache). |

## Running & Building

| Command | Description |
|---------|-------------|
| `flutter run` | Builds and runs the app on a connected device/emulator. |
| `flutter run -d <device_id>` | Runs the app on a specific device (use `flutter devices` to list). |
| `flutter run --release` | Runs the app in release mode (optimized, no debug tools). |
| `flutter build apk` | Builds a release Android APK. |
| `flutter build appbundle` | Builds a release Android App Bundle (AAB) for Play Store. |
| `flutter build ios` | Builds a release iOS app (requires macOS + Xcode). |
| `flutter build web` | Builds a release web app to `build/web/`. |
| `flutter build macos` | Builds a release macOS desktop app. |
| `flutter build windows` | Builds a release Windows desktop app. |
| `flutter build linux` | Builds a release Linux desktop app. |

## Testing & Analysis

| Command | Description |
|---------|-------------|
| `flutter test` | Runs all tests in the `test/` directory. |
| `flutter test --coverage` | Runs tests and generates a code coverage report. |
| `flutter analyze` | Runs the Dart static analyzer to find warnings/errors in your code. |
| `dart format .` | Formats all Dart source files according to standard style rules. |
| `dart fix --apply` | Applies automated lint fixes to your codebase. |

## Device & Debugging

| Command | Description |
|---------|-------------|
| `flutter devices` | Lists all connected devices and emulators. |
| `flutter emulators` | Lists available emulators (Android/iOS). |
| `flutter emulators --launch <id>` | Launches a specific emulator. |
| `flutter logs` | Streams log output from a running app (like `adb logcat` for Flutter). |
| `flutter clean` | Deletes `build/` and `.dart_tool/` directories (fixes stale build issues). |
| `flutter doctor` | Checks your development environment for missing dependencies. |
| `flutter doctor -v` | Detailed version of doctor with full diagnostic output. |

## Platform-Specific

| Command | Description |
|---------|-------------|
| `flutterfire configure` | (via `flutterfire_cli`) Configures Firebase for your Flutter project. |
| `dart run flutter_launcher_icons` | Generates app launcher icons from the image path in `pubspec.yaml`. |
| `dart run build_runner build` | Runs code generation (for models, JSON serialization, etc.). |
| `dart run build_runner watch` | Continuously watches for changes and re-runs code generation. |

## Config & Metadata

| Command | Description |
|---------|-------------|
| `flutter --version` | Shows installed Flutter version and channel. |
| `dart --version` | Shows installed Dart SDK version. |
| `flutter config --enable-web` | Enables web platform support. |
| `flutter config --enable-macos` | Enables macOS desktop support. |
| `flutter config --list` | Lists all current Flutter configuration settings. |

## Migration

| Command | Description |
|---------|-------------|
| `flutter upgrade` | Upgrades Flutter SDK to the latest version on your current channel. |
| `flutter upgrade --force` | Force upgrade (bypasses prompt if there are local changes). |
| `flutter channel` | Lists available Flutter release channels (stable, beta, master). |
| `flutter channel <name>` | Switches to a specific Flutter channel. |
| `dart migrate` | Applies Dart 3 null safety migration to your project. |
