#!/bin/bash

set -e

echo "===================================="
echo "Building Habit Tracker APK"
echo "===================================="

# Source Gradle proxy configuration if available (for Claude Code remote environment)
if [ -f ~/.gradle/proxy-env.sh ]; then
  echo "Loading Gradle proxy configuration..."
  source ~/.gradle/proxy-env.sh
fi

# Determine which gradle command to use
# Prefer system Gradle if wrapper fails (e.g., due to download restrictions in remote environments)
GRADLE_CMD="./gradlew"
if [ -n "${USE_SYSTEM_GRADLE:-}" ] || [ -x /opt/gradle/bin/gradle ]; then
  # Check if wrapper can download Gradle distribution
  if ! ./gradlew --version >/dev/null 2>&1; then
    if [ -x /opt/gradle/bin/gradle ]; then
      echo "Gradle wrapper unavailable, using system Gradle..."
      GRADLE_CMD="/opt/gradle/bin/gradle"
    fi
  fi
fi

# Clean previous builds
echo "Cleaning previous builds..."
$GRADLE_CMD clean

# Build debug APK
echo "Building debug APK..."
$GRADLE_CMD assembleDebug

# Build release APK
echo "Building release APK..."
$GRADLE_CMD assembleRelease

echo "===================================="
echo "Build completed successfully!"
echo "===================================="
echo ""
echo "Debug APK: app/build/outputs/apk/debug/app-debug.apk"
echo "Release APK: app/build/outputs/apk/release/app-release-unsigned.apk"
