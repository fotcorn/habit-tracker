#!/bin/bash
set -e

echo "===================================="
echo "Building Habit Tracker APK"
echo "===================================="

# Source proxy config if available (for Claude Code remote environment)
[ -f ~/.gradle/proxy-env.sh ] && source ~/.gradle/proxy-env.sh

echo "Cleaning previous builds..."
./gradlew clean

echo "Building debug APK..."
./gradlew assembleDebug

echo "Building release APK..."
./gradlew assembleRelease

echo "===================================="
echo "Build completed successfully!"
echo "===================================="
echo ""
echo "Debug APK: app/build/outputs/apk/debug/app-debug.apk"
echo "Release APK: app/build/outputs/apk/release/app-release-unsigned.apk"
