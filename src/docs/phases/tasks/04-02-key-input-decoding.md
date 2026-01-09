# Phase 04 — Key input decoding

## Goal

Decode keypresses (including arrows) reliably in a shell-only TUI.

## Checklist

- [ ] Read single keys without waiting for newline (bash `read -rsn1`).
- [ ] Decode escape sequences:
  - [ ] arrow keys
  - [ ] `Home/End` (optional)
  - [ ] page up/down (optional)
- [ ] Support fallback keys: `hjkl`.
- [ ] Ensure input decoding doesn’t block redraws.

## Acceptance

- Navigation keys work consistently across common terminals (macOS Terminal/iTerm2, Linux terminals).

