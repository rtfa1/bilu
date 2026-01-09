# Phase 04 — Render loop and frame buffer

## Goal

Implement efficient redraws in shell.

## Checklist

- [ ] Use a main loop:
  - [ ] read key
  - [ ] update state
  - [ ] render frame
- [ ] Build a full-frame string buffer and print once.
- [ ] Handle `WINCH` resize:
  - [ ] recalc layout
  - [ ] redraw
- [ ] Avoid per-cell `tput` calls; use VT100 escapes sparingly.

## Acceptance

- TUI redraw is flicker-free and responsive with 100+ tasks.

