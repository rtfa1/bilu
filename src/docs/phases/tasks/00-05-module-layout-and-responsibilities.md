# Phase 00 — Module layout and responsibilities

## Goal

Define how `bilu board` is split into small shell modules so it stays maintainable.

## Checklist

- [ ] Confirm the module folder layout under `src/cli/commands/board/`:
  - [ ] `args.sh`, `paths.sh`
  - [ ] loaders: config/tasks
  - [ ] `normalize.sh`
  - [ ] renderers: `render/table.sh`, `render/kanban.sh`, `render/tui.sh`
  - [ ] actions: edit status/priority, open editor, rebuild index
- [ ] Confirm which parts must stay POSIX `sh`.
- [ ] Confirm which parts may be `bash` (recommend: `render/tui.sh` only).

## Acceptance

- A module layout that matches the docs and is ready for implementation.

