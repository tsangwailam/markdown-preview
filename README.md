# Markdown Preview (macOS Quick Look)

Quick Look extension for Markdown files.

## Prerequisites

- macOS with Xcode installed
- Valid Apple Development code-signing identity (`security find-identity -v -p codesigning`)

## Build

Build Release output without Xcode signing:

```bash
cd /Volumes/sambashare/poc/mdp/code
xcodebuild \
  -project MarkdownPreview.xcodeproj \
  -scheme MarkdownPreviewApp \
  -configuration Release \
  -derivedDataPath /tmp/mdp-dd \
  clean build \
  CODE_SIGNING_ALLOWED=NO
```

App output:

```text
/tmp/mdp-dd/Build/Products/Release/MarkdownPreviewApp.app
```

## Sign + Install

Set your signing identity string and run:

```bash
IDENTITY='Apple Development: YOUR_NAME (TEAMID)'
SRC_APP='/tmp/mdp-dd/Build/Products/Release/MarkdownPreviewApp.app'
DST_APP='/Applications/MarkdownPreviewApp.app'
EXT_ENT='/Volumes/sambashare/poc/mdp/code/src/Config/MarkdownPreviewExtension.entitlements'
APP_ENT='/Volumes/sambashare/poc/mdp/code/src/Config/MarkdownPreviewApp.entitlements'

rm -rf "$DST_APP"
cp -R "$SRC_APP" "$DST_APP"
xattr -cr "$DST_APP"

EX="$DST_APP/Contents/PlugIns/MarkdownPreviewExtension.appex"

# Sign extension first
codesign --force --options runtime --timestamp=none \
  --entitlements "$EXT_ENT" \
  --sign "$IDENTITY" "$EX"

# Then sign app (no --deep so extension entitlements are preserved)
codesign --force --options runtime --timestamp=none \
  --entitlements "$APP_ENT" \
  --sign "$IDENTITY" "$DST_APP"

codesign --verify --deep --strict --verbose=2 "$DST_APP"
```

## Register + Refresh Quick Look

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted /Applications/MarkdownPreviewApp.app
pluginkit -a /Applications/MarkdownPreviewApp.app/Contents/PlugIns/MarkdownPreviewExtension.appex

killall -9 quicklookd || true
killall -9 Finder || true

qlmanage -r cache
qlmanage -r
```

## Optional: verify extension is registered

```bash
pluginkit -m -A -D -v -p com.apple.quicklook.preview | rg 'com.local.MarkdownPreviewApp.MarkdownPreviewExtension|/Applications/MarkdownPreviewApp.app'
```
