# Markdown Preview Quick Look App (Source Layout)

This folder contains the implementation scaffold for a macOS Finder Quick Look markdown preview app.

## Structure

- `CoreMarkdownPreview/`: shared Swift package with renderer, theme, and cache.
- `MarkdownPreviewExtension/`: Quick Look extension controller (`QLPreviewingController`).
- `MarkdownPreviewApp/`: host app stubs (required for extension discovery).
- `Config/`: `Info.plist` templates for app and extension targets.

## What is implemented

- Markdown rendering pipeline: `.md` text -> sanitized HTML -> styled page.
- Common syntax support: headings, paragraphs, lists, blockquotes, fenced code, tables, links, inline code, emphasis.
- Light/dark theme CSS.
- In-memory LRU cache by file path + mtime + size.
- Large-file fallback (`>2MB`) to escaped plain-code view for safety/performance.
- Unit tests for renderer and cache.

## Build notes

1. Create an Xcode macOS App project and add a Quick Look Preview Extension target.
2. Wire `MarkdownPreviewApp/*.swift` into the app target.
3. Wire `MarkdownPreviewExtension/PreviewViewController.swift` into the extension target.
4. Add local package dependency from `CoreMarkdownPreview/Package.swift` and link it to extension target.
5. Apply plist templates from `Config/` to the corresponding targets.
6. Build and run host app once, then enable extension in System Settings.

## Local tests for shared package

```bash
cd mdp/code/src/CoreMarkdownPreview
swift test
```
