# Title
Project scaffold and Chrome Extension Manifest V3

# Description
Set up the Chrome extension project structure, baseline configuration, and Manifest V3 with the required permissions and entry points (content script, background service worker, extension UI assets).

# Implementation Plan
1. Create the extension directory layout (src, public, scripts, wasm, ui, assets).
2. Define `manifest.json` with content scripts, background service worker, permissions, and host permissions.
3. Add minimal placeholder files for content script and background worker.
4. Document the local dev/run flow for loading the unpacked extension in Chrome.

# Priority
High

# Status
Done

# Details
- Created extension scaffold directories at repo root (src, public, scripts, wasm, ui, assets).
- Added MV3 `manifest.json` with background worker, content script, and popup UI entry.
- Added placeholder content script, background service worker, and popup UI assets.
- Documented Chrome unpacked extension workflow in `docs/extension-dev.md`.

# depends_on
[]
