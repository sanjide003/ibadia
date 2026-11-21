#!/usr/bin/env bash
set -euo pipefail

FLUTTER_ROOT_DIR="${FLUTTER_ROOT_DIR:-/tmp/flutter-sdk}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter stable SDK into ${FLUTTER_ROOT_DIR}..."
  if [ ! -d "${FLUTTER_ROOT_DIR}/.git" ]; then
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_ROOT_DIR}"
  fi
  export PATH="${FLUTTER_ROOT_DIR}/bin:${PATH}"
fi

git config --global --add safe.directory "${FLUTTER_ROOT_DIR}" >/dev/null 2>&1 || true
git config --global --add safe.directory "$(pwd)" >/dev/null 2>&1 || true

flutter --suppress-analytics config --enable-web >/dev/null 2>&1 || true
flutter --suppress-analytics pub get

DART_DEFINES=()
if [ -n "${QURAN_API_BASE_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=QURAN_API_BASE_URL=${QURAN_API_BASE_URL}")
fi
if [ -n "${QURAN_API_KEY:-}" ]; then
  DART_DEFINES+=("--dart-define=QURAN_API_KEY=${QURAN_API_KEY}")
fi
if [ -n "${ANDROID_APK_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=ANDROID_APK_URL=${ANDROID_APK_URL}")
fi

echo "Building Flutter Web release bundle..."
flutter --suppress-analytics build web --release "${DART_DEFINES[@]}"
echo "Flutter Web build ready at build/web"
