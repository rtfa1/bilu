# Phase 03 — Color theme and `NO_COLOR`

## Goal

Standardize ANSI styling so output is “beautiful” but still script-friendly and accessible.

## Checklist

- [ ] Define status colors (TODO, INPROGRESS, BLOCKED, REVIEW, DONE, CANCELLED, ARCHIVED).
- [ ] Define priority colors/badges (CRITICAL, HIGH, MEDIUM, LOW, TRIVIAL).
- [ ] Define styles for:
  - [ ] selected card (TUI later)
  - [ ] dimmed/cancelled items
  - [ ] warnings
- [ ] Implement and document:
  - [ ] `NO_COLOR=1` disables ANSI
  - [ ] `--no-color` flag disables ANSI

## Acceptance

- Colors are consistent across table and kanban renderers and can be disabled.

