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

# Auto-detect public GitHub Release APK URL when deployed from GitHub to Vercel.
if [ -z "${ANDROID_APK_URL:-}" ] && [ -n "${VERCEL_GIT_REPO_OWNER:-}" ] && [ -n "${VERCEL_GIT_REPO_SLUG:-}" ]; then
  ANDROID_APK_URL="https://github.com/${VERCEL_GIT_REPO_OWNER}/${VERCEL_GIT_REPO_SLUG}/releases/download/latest/Al-Quran.apk"
  echo "Auto-configured ANDROID_APK_URL=${ANDROID_APK_URL}"
fi

if [ -z "${WEB_APP_URL:-}" ] && [ -n "${VERCEL_PROJECT_PRODUCTION_URL:-}" ]; then
  WEB_APP_URL="https://${VERCEL_PROJECT_PRODUCTION_URL}"
elif [ -z "${WEB_APP_URL:-}" ] && [ -n "${VERCEL_URL:-}" ]; then
  WEB_APP_URL="https://${VERCEL_URL}"
fi

APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-$(( $(date -u +%s) - 1700000000 ))}"
APP_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)

DART_DEFINES=(
  "--dart-define=APP_BUILD_NUMBER=${APP_BUILD_NUMBER}"
)
if [ -n "${QURAN_API_BASE_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=QURAN_API_BASE_URL=${QURAN_API_BASE_URL}")
fi
if [ -n "${QURAN_API_KEY:-}" ]; then
  DART_DEFINES+=("--dart-define=QURAN_API_KEY=${QURAN_API_KEY}")
fi
if [ -n "${ANDROID_APK_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=ANDROID_APK_URL=${ANDROID_APK_URL}")
fi
if [ -n "${WEB_APP_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=WEB_APP_URL=${WEB_APP_URL}")
fi

echo "Building Flutter Web release bundle (build ${APP_BUILD_NUMBER})..."
flutter --suppress-analytics build web --release "${DART_DEFINES[@]}"

cat > build/web/app_version.json <<EOF
{
  "version": "${APP_VERSION}",
  "buildNumber": ${APP_BUILD_NUMBER},
  "platform": "web"
}
EOF

echo "Flutter Web build ready at build/web"
