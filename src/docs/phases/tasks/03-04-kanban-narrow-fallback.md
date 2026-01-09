# Phase 03 — Narrow-terminal fallback

## Goal

Ensure `--view=kanban` remains usable on small terminals.

## Checklist

- [ ] Define “narrow” threshold (e.g. `< 80 cols`).
- [ ] Implement fallback rendering:
  - [ ] vertical blocks per column
  - [ ] one-column-at-a-time with section headers
- [ ] Ensure card borders don’t wrap unexpectedly.

## Acceptance

- Output is still readable and doesn’t spam escape sequences on narrow terminals.

