# Phase 04 — Open and edit actions

## Goal

Let users open a card and perform minimal edits from the TUI.

## Checklist

- [ ] `Enter` opens selected task:
  - [ ] `$EDITOR` if set, else `less`/`more`
- [ ] `e` opens in `$EDITOR`.
- [ ] `S` cycles status and persists.
- [ ] `P` cycles priority and persists.
- [ ] `r` refresh from disk.

## Acceptance

- Editing updates the underlying file safely and the UI refreshes to reflect changes.

