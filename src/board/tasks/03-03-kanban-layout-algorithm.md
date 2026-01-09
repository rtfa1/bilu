# Phase 03 — Kanban layout algorithm (non-interactive)

## Goal

Define the rendering algorithm for a non-interactive kanban layout that adapts to terminal size.

## Checklist

- [ ] Use `stty size` to get `LINES`/`COLUMNS`.
- [ ] Choose number of columns to render based on width.
- [ ] Define column width calculation:
  - [ ] padding
  - [ ] borders
  - [ ] inter-column spacing
- [ ] Define card layout:
  - [ ] title line (with priority badge)
  - [ ] optional description preview lines
  - [ ] tags chips line (truncated)
- [ ] Define truncation/wrapping rules that avoid breaking the screen.

## Acceptance

- Kanban output is readable at common widths (80/100/120) and degrades gracefully when narrow.

