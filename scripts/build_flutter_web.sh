#!/bin/bash
set -e

echo "=== OmniMark: Setting up Flutter SDK for Web Build ==="

# Install Flutter if not already present in cache
FLUTTER_DIR="/tmp/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "=== Building Flutter Web for apps/mobile ==="
cd apps/mobile
flutter pub get
flutter build web --release

echo "=== Flutter Web compilation complete! Output in apps/mobile/build/web ==="
