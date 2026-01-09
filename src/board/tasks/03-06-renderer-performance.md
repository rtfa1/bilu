# Phase 03 — Renderer performance rules

## Goal

Keep rendering snappy in shell.

## Checklist

- [ ] Avoid calling `tput` repeatedly per cell/card.
- [ ] Prefer building one output buffer per frame and printing once.
- [ ] Cache terminal size and only recalc on resize (TUI later).
- [ ] Avoid external processes inside hot loops where possible.

## Acceptance

- Rendering is fast enough for 100+ tasks without visible lag.

