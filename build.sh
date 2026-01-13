#!/bin/bash

set -e

echo "===================================="
echo "Building Habit Tracker APK"
echo "===================================="

# Clean previous builds
echo "Cleaning previous builds..."
./gradlew clean

# Build debug APK
echo "Building debug APK..."
./gradlew assembleDebug

# Build release APK
echo "Building release APK..."
./gradlew assembleRelease

echo "===================================="
echo "Build completed successfully!"
echo "===================================="
echo ""
echo "Debug APK: app/build/outputs/apk/debug/app-debug.apk"
echo "Release APK: app/build/outputs/apk/release/app-release-unsigned.apk"
