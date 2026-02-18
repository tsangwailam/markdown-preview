#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MarkdownPreviewApp.app"
VOL_NAME="Markdown Preview Installer"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_DERIVED_DATA_PATH="${HOME}/Library/Developer/Xcode/DerivedData/MarkdownPreview-agtqxaknownxrrgcucdepbqvkthl"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$DEFAULT_DERIVED_DATA_PATH}"
BUILD_APP="${BUILD_APP:-${DERIVED_DATA_PATH}/Build/Products/Release/${APP_NAME}}"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/dmg-root"
DMG_PATH="${DIST_DIR}/MarkdownPreviewApp-Installer.dmg"

if [[ ! -d "$BUILD_APP" ]]; then
  echo "Build output missing: $BUILD_APP" >&2
  echo "Hint: set BUILD_APP or DERIVED_DATA_PATH before running this script." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

cp -R "$BUILD_APP" "$STAGE_DIR/$APP_NAME"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "Created $DMG_PATH"
