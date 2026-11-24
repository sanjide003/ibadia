#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter SDK for Vercel..."
  FLUTTER_DIR="/tmp/flutter"
  if [ ! -d "$FLUTTER_DIR" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

APK_URL="${ANDROID_APK_URL:-https://github.com/sanjide003/ibadia/releases/download/latest/Ibadia.apk}"
MANIFEST_URL="${UPDATE_MANIFEST_URL:-https://github.com/sanjide003/ibadia/releases/download/latest/version.json}"
RAW_VER=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
APP_VER="${RAW_VER%%+*}"
BUILD_NUM="${APP_BUILD_NUMBER:-${RAW_VER#*+}}"

flutter --version
flutter pub get
flutter build web --release \
  --dart-define=QURAN_API_KEY="${QURAN_API_KEY:-}" \
  --dart-define=WEB_APP_URL="${WEB_APP_URL:-https://ibadia.vercel.app}" \
  --dart-define=ANDROID_APK_URL="${APK_URL}" \
  --dart-define=UPDATE_MANIFEST_URL="${MANIFEST_URL}" \
  --dart-define=APP_BUILD_NUMBER="${BUILD_NUM}"

cat > build/web/app_version.json <<EOF
{
  "version": "${APP_VER}",
  "buildNumber": ${BUILD_NUM},
  "apkUrl": "${APK_URL}",
  "updatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
