<img width="128" height="128" alt="icon_128" src="https://github.com/user-attachments/assets/38d023aa-83ee-45ed-9cba-61c9adc00f1e" />

# Markdown Preview - Mac OS Quicklook plugin

[![Downloads](https://img.shields.io/github/downloads/tsangwailam/markdown-preview/total)](https://github.com/tsangwailam/markdown-preview/releases)
[![Release](https://img.shields.io/github/v/release/tsangwailam/markdown-preview)](https://github.com/tsangwailam/markdown-preview/releases)
[![Stars](https://img.shields.io/github/stars/tsangwailam/markdown-preview?style=social)](https://github.com/tsangwailam/markdown-preview/stargazers)
[![License](https://img.shields.io/github/license/tsangwailam/markdown-preview)](LICENSE)

<img width="1908" height="1332" alt="image" src="https://github.com/user-attachments/assets/3b5d78bc-658b-4024-8a23-a2daeadbfc56" />


Quick Look extension for Markdown files on macOS.

## What is Markdown Preview?

Markdown Preview is a macOS Finder Quick Look plugin that renders Markdown documents as styled HTML previews. Instead of plain text in Quick Look, you get readable formatting for headings, lists, blockquotes, code fences, tables, links, and inline emphasis. The project includes:

- `MarkdownPreviewExtension`: the Quick Look extension.
- `MarkdownPreviewApp`: host app used for extension registration.
- `CoreMarkdownPreview`: shared Swift package for rendering, theming, and cache.

## Prerequisites

- macOS with Xcode installed
- Valid Apple Development code-signing identity (`security find-identity -v -p codesigning`)

## Quick Start

From the repository root, use the local release script:

```bash
bash scripts/build_local_release.sh
```

To build and install to `/Applications` (and refresh Quick Look registration/cache):

```bash
bash scripts/build_local_release.sh --install
```

Default output app path:

```text
/tmp/mdp-dd/Build/Products/Release/MarkdownPreviewApp.app
```

Optional: customize DerivedData path for build output:

```bash
DERIVED_DATA_PATH=/tmp/custom-mdp-dd bash scripts/build_local_release.sh --install
```

## Sign + Install

Set your signing identity string and run:

```bash
IDENTITY='Apple Development: YOUR_NAME (TEAMID)'
SRC_APP='/tmp/mdp-dd/Build/Products/Release/MarkdownPreviewApp.app'
DST_APP='/Applications/MarkdownPreviewApp.app'
EXT_ENT='ROOT/src/Config/MarkdownPreviewExtension.entitlements'
APP_ENT='ROOT/src/Config/MarkdownPreviewApp.entitlements'

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

## License

This project is licensed under the MIT License. See `LICENSE` for details.
