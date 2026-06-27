#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.5}"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

cd apps/cliente

flutter config --enable-web
flutter pub get

flutter build web \
  --release \
  --web-renderer html \
  --pwa-strategy=none \
  --dart-define=STABLE_BOOT=true
