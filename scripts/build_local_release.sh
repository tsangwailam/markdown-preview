#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/mdp-dd}"
APP_NAME="MarkdownPreviewApp.app"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/Release/${APP_NAME}"
EXT_PATH="${APP_PATH}/Contents/PlugIns/MarkdownPreviewExtension.appex"
APP_ENTITLEMENTS="${ROOT_DIR}/src/Config/MarkdownPreviewApp.entitlements"
EXT_ENTITLEMENTS="${ROOT_DIR}/src/Config/MarkdownPreviewExtension.entitlements"
INSTALL_APP_PATH="/Applications/${APP_NAME}"
SHOULD_INSTALL=0

usage() {
  cat <<'EOF'
Usage: bash scripts/build_local_release.sh [--install]

Builds Release app locally and ad-hoc signs it for local execution.

Options:
  --install   Copy app to /Applications and refresh Quick Look registration/cache
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      SHOULD_INSTALL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

echo "Building Release app..."
xcodebuild \
  -project MarkdownPreview.xcodeproj \
  -scheme MarkdownPreviewApp \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  clean build \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build output missing: $APP_PATH" >&2
  exit 1
fi

echo "Signing extension and app (ad-hoc)..."
codesign --force --sign - --entitlements "$EXT_ENTITLEMENTS" "$EXT_PATH"
codesign --force --sign - --entitlements "$APP_ENTITLEMENTS" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Build ready:"
echo "  $APP_PATH"

if [[ "$SHOULD_INSTALL" -eq 1 ]]; then
  echo "Installing to /Applications..."
  rm -rf "$INSTALL_APP_PATH"
  cp -R "$APP_PATH" "$INSTALL_APP_PATH"

  echo "Refreshing Quick Look registration/cache..."
  pluginkit -a "${INSTALL_APP_PATH}/Contents/PlugIns/MarkdownPreviewExtension.appex"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f -R -trusted "$INSTALL_APP_PATH"
  killall -9 quicklookd || true
  killall -9 Finder || true
  qlmanage -r cache >/dev/null
  qlmanage -r >/dev/null

  echo "Installed:"
  echo "  $INSTALL_APP_PATH"
fi
