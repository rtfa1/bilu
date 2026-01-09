# Board UI (Shell-only) — Overview

Goal: a beautiful, keyboard-driven board viewer/editor in the terminal, implemented using shell scripts only.

## Constraints

- Shell scripts only (POSIX `sh` for non-interactive; `bash` allowed for interactive keystroke handling).
- No required third-party deps (no `fzf`, `gum`, `dialog`, `jq`).
- Must work both:
  - from the repo layout (`src/board/...`)
  - from an installed layout (`.bilu/board/...`)

## Inputs (current repo state)

- `src/board/config.json`: enums and UI defaults (status order, priorities, labels).
- `src/board/default.json`: task index (task cards with `title`, `status`, `priority`, etc).
- `src/board/tasks/*.md`: task detail files (human readable, editable).

## Outputs (CLI)

- `bilu board --list` (table output)
- `bilu board --list --view=kanban` (non-interactive kanban)
- `bilu board --tui` (interactive UI)

## Phases

1. Define data contract + normalization (`01-data-contract.md`)
2. Modularize `bilu board` (`02-cli-and-modules.md`)
3. Table + kanban renderers (`03-rendering-table-and-kanban.md`)
4. Interactive TUI (`04-interactive-tui.md`)
5. Persistence/editing (`05-persistence-and-editing.md`)
6. Tests + documentation (`06-testing-and-docs.md`)

## Phase 00 tasks

See `src/docs/phases/tasks/` for Phase 00 planning tasks.
