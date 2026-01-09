# Phase 02 — Layout detection

## Goal

Make board file discovery work in both repo and installed layouts.

## Checklist

- [ ] Define how to locate board root:
  - [ ] repo layout: `$BILU_ROOT/src/board`
  - [ ] installed layout: `$BILU_ROOT/board`
- [ ] Define how `BILU_ROOT` is discovered (reuse `src/cli/bilu` layout logic if possible).
- [ ] Provide helpers that return absolute paths:
  - [ ] `board_config_path`
  - [ ] `board_default_json_path`
  - [ ] `board_tasks_dir`

## Acceptance

- `bilu board --list` works from any directory inside a project that has `.bilu/`.

