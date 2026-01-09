# Phase 02 — Module skeleton

## Goal

Create the module directory structure under `.bilu/cli/commands/board/` and wire imports in a consistent way.

## Checklist

- [x] Create module directories:
  - [x] `.bilu/cli/commands/board/`
  - [x] `.bilu/cli/commands/board/render/`
  - [x] `.bilu/cli/commands/board/actions/`
  - [x] `.bilu/cli/commands/board/ui/`
- [x] Add placeholder modules with clear interfaces:
  - [x] `paths.sh`, `args.sh`, `normalize.sh`
  - [x] `load/config.sh`, `load/tasks_json.sh`, `load/tasks_md.sh`
- [x] Decide module sourcing convention:
  - [x] `SCRIPT_DIR` + `. "$SCRIPT_DIR/..."` includes
  - [x] no reliance on `$PWD`

## Acceptance

- `board.sh` can source modules reliably from any working directory.
---

## Implementation plan

# Phase 02 Task Implementation Plan — Module skeleton

Task: `.bilu/board/tasks/02-02-module-skeleton.md`

This implementation plan creates the module directory skeleton for `bilu board` and defines a sourcing convention that works from any working directory. It aligns with `.bilu/storage/research/shell-only-cli-advanced-notes.md` and the Phase 00 module layout plan: keep non-interactive code POSIX `sh`, keep stateful TUI code in `bash`, and structure logic so `awk` can be the compute engine.

## Outcome (what “done” means)

1) The directory tree under `.bilu/cli/commands/board/` exists.
2) Placeholder modules exist with documented, stable interfaces.
3) `.bilu/cli/commands/board.sh` can source modules reliably from any working directory.

## Directory structure to create

Create:
- `.bilu/cli/commands/board/`
- `.bilu/cli/commands/board/render/`
- `.bilu/cli/commands/board/actions/`
- `.bilu/cli/commands/board/ui/`
- `.bilu/cli/commands/board/lib/`
- `.bilu/cli/commands/board/load/`

Note: Phase 02 task list uses flat `load_config.sh` naming, while Phase 00 plan proposes `load/config.sh`. Choose one structure now and keep it consistent.

Recommendation:
- Use folders (`load/`, `lib/`) to avoid filename sprawl and keep responsibilities clear.

## Module sourcing convention (authoritative)

In `.bilu/cli/commands/board.sh`:

1) Compute a stable module root:
- `SCRIPT_DIR` = directory of `board.sh`
- `BOARD_LIB_DIR` = `$SCRIPT_DIR/board`

2) Source modules via absolute paths:
- `. "$BOARD_LIB_DIR/lib/log.sh"`
- `. "$BOARD_LIB_DIR/args.sh"`
- etc.

Rules:
- Do not rely on `$PWD`.
- Do not assume callers run from repo root.

## Placeholder modules and interfaces

Define minimal function interfaces now so later tasks can fill them in without changing call sites.

### `lib/log.sh` (POSIX `sh`)

- `die <message>` → prints `bilu board: error: ...` to stderr and exits `1`
- `warn <message>` → prints `bilu board: warn: ...` to stderr
- `usage_error <message>` → prints error + usage hint and exits `2`

### `paths.sh` (POSIX `sh`)

- `board_detect_paths` sets exported variables:
  - `BOARD_ROOT`
  - `BOARD_CONFIG_PATH`
  - `BOARD_DEFAULT_JSON_PATH`
  - `BOARD_TASKS_DIR`
  - `BOARD_STORAGE_DIR` (if applicable)

### `args.sh` (POSIX `sh`)

- `board_parse_args "$@"` sets exported variables:
  - `BOARD_ACTION` (e.g. `list`, `validate`, `tui`, `rebuild-index`)
  - `BOARD_VIEW` (e.g. `table`, `kanban`)
  - `BOARD_FILTER_NAME`, `BOARD_FILTER_VALUE`
  - `BOARD_NO_COLOR`

### `normalize.sh` (POSIX `sh` + awk)

- `board_normalize_tsv` reads TSV on stdin and writes normalized TSV on stdout.
- Enforces no tab/newline in fields (replace with spaces).

### `load/tasks_md.sh` (POSIX `sh` + awk)

- `board_load_tasks_from_md` emits normalized TSV (or raw TSV + normalization stage).

### `render/table.sh` (POSIX `sh` + awk)

- `board_render_table` reads normalized TSV and prints table output.

### `render/kanban.sh` (POSIX `sh` + awk)

- `board_render_kanban` reads normalized TSV and prints kanban output (width-aware).

### `render/tui.sh` (bash only)

- `board_tui_main` reads normalized TSV (or reads tasks via helper) and runs the interactive loop.

## Shell boundary rules (enforce now)

- All non-interactive modules use `#!/usr/bin/env sh` patterns and avoid bashisms.
- Only `render/tui.sh` uses `#!/usr/bin/env bash`.
- Avoid bash 4+ features to keep macOS compatibility.

## Implementation steps

1) Create the folders.
2) Add placeholder files with function stubs and clear comments in docstrings (no heavy logic yet).
3) Update `.bilu/cli/commands/board.sh` to:
  - compute module paths
  - source `lib/log.sh` first
  - call `board_detect_paths`, then `board_parse_args`
  - dispatch based on `BOARD_ACTION`

## Acceptance checks

- Running `sh .bilu/cli/bilu board --help` still works from any directory.
- Running `sh .bilu/cli/bilu board --list` still works and does not depend on `$PWD`.
- `board.sh` sources modules successfully (no “file not found”).

## References

- `.bilu/board/tasks/02-02-module-skeleton.md`
- `.bilu/board/tasks/00-05-module-layout-and-responsibilities.md`
- `.bilu/board/phases/02-cli-and-modules.md`
- `.bilu/storage/research/shell-only-cli-advanced-notes.md`

# Description
Create the board module skeleton under .bilu/cli/commands/board/ (render/actions/ui + core modules) and standardize sourcing/imports via SCRIPT_DIR so board.sh works from any working directory.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- design
- frontend
- planning
- usability
# depends_on

## Outcomes

- Confirmed module skeleton exists under `.bilu/cli/commands/board/` (including `render/`, `actions/`, `ui/`, `lib/`, `load/`).
- Confirmed `.bilu/cli/commands/board.sh` sources modules via `SCRIPT_DIR`/`BOARD_LIB_DIR` and does not rely on `$PWD`.
- Tests: `sh tests/run.sh`
