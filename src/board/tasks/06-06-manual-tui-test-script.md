# Phase 06 — Manual TUI test script

## Goal

Provide a repeatable manual checklist for interactive TUI QA.

## Checklist

- [ ] Terminal setup/cleanup:
  - [ ] enter TUI, exit with `q`, verify terminal is restored
  - [ ] interrupt with `Ctrl-C`, verify terminal is restored
- [ ] Navigation:
  - [ ] arrows + `hjkl`
  - [ ] selection stays visible while scrolling
- [ ] Search:
  - [ ] `/` search, `n/p` next/prev match, clear search
- [ ] Filter/sort:
  - [ ] apply filter, clear filter
  - [ ] change sort key/order
- [ ] Open/edit:
  - [ ] open in `$EDITOR`, return to TUI
  - [ ] change status/priority and verify persistence
- [ ] Resize:
  - [ ] resize terminal while in TUI and verify redraw

## Acceptance

- Manual QA steps are documented and can be followed by anyone.

