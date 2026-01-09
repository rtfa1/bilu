# Phase 05 — Open task in editor

## Goal

Provide a consistent “open” action for a task card.

## Checklist

- [ ] Use `$EDITOR` when set.
- [ ] Fallback to `less` (if present) or `more`.
- [ ] Ensure TUI returns to normal state after editor exits (restore terminal mode then re-enter).

## Acceptance

- `Enter`/`e` actions in the TUI open the correct file and return to the board UI cleanly.

