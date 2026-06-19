#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Tickeys-Swift"
APP_BUNDLE="$ROOT_DIR/.build/app/$APP_NAME.app"
DMG_DIR="$ROOT_DIR/.build/dmg"
STAGING_DIR="$DMG_DIR/staging"
DMG_NAME="$APP_NAME.dmg"
OUTPUT_DMG="$DMG_DIR/$DMG_NAME"

mkdir -p "$DMG_DIR"

if [ ! -d "$APP_BUNDLE" ]; then
  echo "App bundle not found, building app first..."
  bash "$ROOT_DIR/scripts/build-app.sh"
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

if [ -f "$OUTPUT_DMG" ]; then
  rm -f "$OUTPUT_DMG"
fi

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$OUTPUT_DMG"

echo "$OUTPUT_DMG"
