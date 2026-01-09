# Phase 3 — Rendering (table + kanban)

Deliver useful output without requiring full-screen interaction.

## Table view

Default `bilu board --list` output.

Requirements:
- Stable column alignment and truncation.
- Colorized status/priority badges (ANSI), with `NO_COLOR`/`--no-color` support.
- Show counts and active filter/search in a header line.

Suggested columns:
- `STATUS` `PRIO` `TITLE` `TAGS` `LINK|PATH`

## Kanban view (non-interactive)

`bilu board --list --view=kanban`

Requirements:
- Use terminal width (via `stty size`) to size columns.
- Render cards with borders (ASCII/box drawing) and consistent spacing.
- Fallback mode when terminal is narrow:
  - render one column at a time vertically

## Column mapping

Define a mapping from statuses to columns.

Start with a default mapping derived from `src/board/config.json` and allow future override:
- Backlog: `BACKLOG`, `TODO`
- In Progress: `INPROGRESS`, `BLOCKED`
- Review: `REVIEW`
- Done: `DONE` (and optionally `ARCHIVED`, `CANCELLED` depending on a flag/config)

## Phase 03 tasks

See `src/docs/phases/tasks/` for Phase 03 tasks.

