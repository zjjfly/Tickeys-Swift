#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Tickeys-Swift"
PRODUCT_NAME="Tickeys-Swift"
BUNDLE_ID="github.zjjfly.Tickeys-Swift"
VERSION="${VERSION:-0.1.0}"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$BUILD_DIR/app/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SCRATCH_DIR="$BUILD_DIR/scratch"
UNIVERSAL="${UNIVERSAL:-0}"

cd "$ROOT_DIR"

build_product() {
  local scratch_path="$1"
  shift

  swift build \
    --scratch-path "$scratch_path" \
    --configuration "$CONFIGURATION" \
    --product "$PRODUCT_NAME" \
    "$@"
}

find_built_binary() {
  local scratch_path="$1"
  local binary_path="$BUILD_DIR/$CONFIGURATION/$PRODUCT_NAME"

  if [ -f "$binary_path" ]; then
    echo "$binary_path"
    return
  fi

  find "$scratch_path" -path "*/$CONFIGURATION/$PRODUCT_NAME" -type f -perm -111 | head -n 1
}

if [ "$UNIVERSAL" = "1" ]; then
  ARM64_SCRATCH_DIR="$BUILD_DIR/scratch-arm64"
  X86_64_SCRATCH_DIR="$BUILD_DIR/scratch-x86_64"
  UNIVERSAL_BINARY_DIR="$BUILD_DIR/universal/$CONFIGURATION"
  UNIVERSAL_BINARY_PATH="$UNIVERSAL_BINARY_DIR/$PRODUCT_NAME"

  build_product "$ARM64_SCRATCH_DIR" --arch arm64
  ARM64_BINARY_PATH="$(find_built_binary "$ARM64_SCRATCH_DIR")"

  build_product "$X86_64_SCRATCH_DIR" --arch x86_64
  X86_64_BINARY_PATH="$(find_built_binary "$X86_64_SCRATCH_DIR")"

  if [ -z "$ARM64_BINARY_PATH" ] || [ ! -f "$ARM64_BINARY_PATH" ]; then
    echo "error: arm64 executable not found" >&2
    exit 1
  fi
  if [ -z "$X86_64_BINARY_PATH" ] || [ ! -f "$X86_64_BINARY_PATH" ]; then
    echo "error: x86_64 executable not found" >&2
    exit 1
  fi

  mkdir -p "$UNIVERSAL_BINARY_DIR"
  lipo -create "$ARM64_BINARY_PATH" "$X86_64_BINARY_PATH" -output "$UNIVERSAL_BINARY_PATH"
  BINARY_PATH="$UNIVERSAL_BINARY_PATH"
else
  build_product "$SCRATCH_DIR"
  BINARY_PATH="$(find_built_binary "$SCRATCH_DIR")"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

if [ -z "$BINARY_PATH" ] || [ ! -f "$BINARY_PATH" ]; then
  echo "error: built executable not found" >&2
  exit 1
fi

cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
cp -R "$ROOT_DIR/Resources/data" "$RESOURCES_DIR/data"
cp "$ROOT_DIR/Resources/tickeys-swift.icns" "$RESOURCES_DIR/tickeys-swift.icns"
cp "$ROOT_DIR/LICENSE" "$RESOURCES_DIR/LICENSE"
cp "$ROOT_DIR/NOTICE.md" "$RESOURCES_DIR/NOTICE.md"

if [ -d "$ROOT_DIR/Resources/Base.lproj" ]; then
  mkdir -p "$RESOURCES_DIR/Base.lproj"
  cp "$ROOT_DIR/Resources/Base.lproj/Localizable.strings" "$RESOURCES_DIR/Base.lproj/Localizable.strings"
fi

if [ -d "$ROOT_DIR/Resources/zh-Hans.lproj" ]; then
  mkdir -p "$RESOURCES_DIR/zh-Hans.lproj"
  cp "$ROOT_DIR/Resources/zh-Hans.lproj/Localizable.strings" "$RESOURCES_DIR/zh-Hans.lproj/Localizable.strings"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>tickeys-swift</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>Base</string>
    <string>zh-Hans</string>
  </array>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMultipleInstancesProhibited</key>
  <true/>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

plutil -lint "$CONTENTS_DIR/Info.plist" >/dev/null

if [ -n "${DEVELOPER_ID:-}" ]; then
  codesign --force --options runtime --sign "Developer ID Application: $DEVELOPER_ID" "$APP_DIR"
elif [ "${AD_HOC_SIGN:-1}" = "1" ]; then
  codesign --force --sign - "$APP_DIR"
fi

echo "$APP_DIR"
