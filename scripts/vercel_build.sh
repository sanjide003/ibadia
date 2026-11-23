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

flutter --version
flutter pub get
flutter build web --release \
  --dart-define=QURAN_API_KEY="${QURAN_API_KEY:-}" \
  --dart-define=WEB_APP_URL="${WEB_APP_URL:-https://ibadia.vercel.app}" \
  --dart-define=ANDROID_APK_URL="${ANDROID_APK_URL:-}" \
  --dart-define=UPDATE_MANIFEST_URL="${UPDATE_MANIFEST_URL:-}"
