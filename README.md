# Habit Tracker

A modern Android habit tracking application built with Jetpack Compose.

## Overview

Habit Tracker is an Android application that helps users build and maintain positive habits. The app is built using modern Android development practices with Jetpack Compose for the UI.

## Tech Stack

- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Min SDK**: 24 (Android 7.0)
- **Target SDK**: 34 (Android 14)
- **Build System**: Gradle with Kotlin DSL

## Building the App

### Prerequisites

- JDK 17 or higher
- Android SDK
- Git

### Build Instructions

#### Using the Build Script (Recommended)

```bash
./build.sh
```

This script will:
- Clean previous builds
- Build both debug and release APKs
- Output the APK locations

The built APKs will be located at:
- **Debug**: `app/build/outputs/apk/debug/app-debug.apk`
- **Release**: `app/build/outputs/apk/release/app-release-unsigned.apk`

#### Using Gradle Directly

Build debug APK:
```bash
./gradlew assembleDebug
```

Build release APK:
```bash
./gradlew assembleRelease
```

Clean build:
```bash
./gradlew clean
```

## CI/CD

The project includes a GitHub Actions workflow that automatically builds the app on every push and pull request to the main branch. The built APKs are uploaded as artifacts and can be downloaded from the Actions tab.

## Project Structure

```
habit-tracker/
├── app/                    # Main application module
│   ├── src/
│   │   └── main/
│   │       ├── java/       # Kotlin source files
│   │       └── res/        # Resources (layouts, drawables, etc.)
│   └── build.gradle.kts    # App-level build configuration
├── gradle/                 # Gradle wrapper files
├── .github/
│   └── workflows/
│       └── build.yml       # GitHub Actions workflow
├── build.gradle.kts        # Project-level build configuration
├── settings.gradle.kts     # Project settings
└── build.sh               # Build script
```

## Development

To contribute to this project:

1. Clone the repository
2. Open the project in Android Studio
3. Build and run the app on an emulator or physical device

## License

This project is open source and available under the [MIT License](LICENSE).
