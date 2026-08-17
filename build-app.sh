#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/vkQuake Launcher.app"
MACOS="$APP/Contents/MacOS"
RESOURCES="$APP/Contents/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

swiftc -parse-as-library -O \
  -framework AppKit \
  -framework UniformTypeIdentifiers \
  "$ROOT/Sources/vkQuakeLauncher.swift" \
  -o "$MACOS/vkQuakeLauncher"

cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"

for asset in base.jpg hipnotic.jpg rogue.jpg dopa.jpg mg1.jpg mg3.jpg vkquake.icns; do
  if [ -f "$ROOT/Resources/$asset" ]; then
    cp "$ROOT/Resources/$asset" "$RESOURCES/$asset"
  fi
done

codesign --force --deep --sign - "$APP"
printf 'Built %s\n' "$APP"
