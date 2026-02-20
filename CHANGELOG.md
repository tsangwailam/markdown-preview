# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project aims to follow Semantic Versioning.

## [Unreleased]

## [0.0.6] - 2026-02-19

### Added

- macOS Quick Look preview extension for Markdown (`.md`, `.markdown`, etc.).
- Shared `CoreMarkdownPreview` Swift package for Markdown -> sanitized HTML rendering, templating, and theming.
- Light/dark theme CSS and a safe large-file fallback view.
- Preview cache (in-memory LRU) keyed by file path + mtime + size.
- Unit tests for renderer and cache.
- Build/sign/install documentation and helper scripts for local release builds and DMG creation.

[Unreleased]: https://github.com/tsangwailam/markdown-preview/compare/v0.0.6...HEAD
[0.0.6]: https://github.com/tsangwailam/markdown-preview/releases/tag/v0.0.6
