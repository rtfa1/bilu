# Phase 00 — Kanban UX requirements

## Goal

Define what the “beautiful” output looks like and which keyboard interactions are in scope.

## Non-interactive requirements

- [ ] Table view is readable and aligned.
- [ ] Kanban view renders columns and cards with borders and colors.
- [ ] Output degrades gracefully for narrow terminals.

## Interactive (`--tui`) requirements

- [ ] Navigation: arrows + `hjkl`
- [ ] Search: `/` to search, `n/p` to navigate matches
- [ ] Filter: choose field/value
- [ ] Sort: choose sort key + order
- [ ] Open/edit: `Enter` opens task, `e` opens in `$EDITOR`
- [ ] Minimal edits: change status/priority and persist safely

## Visual design requirements

- [ ] Consistent color theme for status + priority.
- [ ] Highlight selected card.
- [ ] Header with counts; footer status bar with active filter/search/sort.
- [ ] `NO_COLOR` and `--no-color` support.

## Acceptance

- A stable keymap and visual spec for the initial release.

