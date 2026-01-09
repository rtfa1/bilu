# Phase 02 — Layout detection

## Goal

Make board file discovery work in both repo and installed layouts.

## Checklist

- [x] Define how to locate board root:
  - [x] repo layout: `$BILU_ROOT/src/board`
  - [x] installed layout: `$BILU_ROOT/board`
- [x] Define how `BILU_ROOT` is discovered (reuse `src/cli/bilu` layout logic if possible).
- [x] Provide helpers that return absolute paths:
  - [x] `board_config_path`
  - [x] `board_default_json_path`
  - [x] `board_tasks_dir`

## Acceptance

- `bilu board --list` works from any directory inside a project that has `.bilu/`.
---

## Implementation plan

# Phase 02 Task Implementation Plan — Layout detection

Task: `src/board/tasks/02-03-layout-detection.md`

This implementation plan ensures the board module can locate its data (`config.json`, `default.json`, `tasks/`) in both repo and installed layouts, from any working directory. It aligns with the project constraint “no reliance on `$PWD`”, and with the “boring and explicit” shell guidance in `src/storage/research/shell-only-cli-advanced-notes.md`.

## Outcome (what “done” means)

1) `bilu board --list` works when invoked from:
- repo root
- any subdirectory inside the repo
- an installed project directory containing `.bilu/`
- any subdirectory inside an installed project
2) Layout detection returns absolute paths for:
- config path
- default.json path
- tasks directory path
3) Detection is implemented once and reused everywhere (no duplicated heuristics).

## Existing layout detection (current repo behavior)

`src/cli/bilu` already detects a “bilu root” using `find_layout()`:
- Repo layout:
  - checks for `src/board/default.json` and `src/cli/commands/init.sh`
- Installed layout:
  - checks for `board/default.json` and `cli/commands/init.sh`

It then dispatches commands with `COMMANDS_ROOT`.

Important: `board.sh` must not assume it is always invoked via `src/cli/bilu`. After install, the shortcut runs `.bilu/cli/bilu`, which has its own layout.

## Strategy (recommended)

Implement a single `board_detect_paths` helper (POSIX `sh`) in:
- `src/cli/commands/board/paths.sh`

It should:
- start from `PWD` (or the script location) and walk up to find `.bilu/` first
- if not found, fall back to repo-root patterns (for local dev)
- cap traversal depth (e.g. 8–10) to avoid infinite loops
- return absolute paths

Rationale:
- “Works from any directory inside a project that has `.bilu/`” is easiest if you search upward for `.bilu/`.

## Detection rules (authoritative)

### Priority order

1) If a `.bilu` directory exists in current dir or any ancestor:
   - board root is `<that>/board`
   - config path: `<that>/board/config.json`
   - default.json path: `<that>/board/default.json`
   - tasks dir: `<that>/board/tasks`
2) Else (repo dev mode):
   - locate repo root by walking up from the directory of `board.sh` (or from `PWD`), checking:
     - `src/board/config.json`
     - `src/board/default.json`
     - `src/cli/bilu`
   - board root is `<repo>/src/board`
   - config path: `<repo>/src/board/config.json`
   - default.json path: `<repo>/src/board/default.json`
   - tasks dir: `<repo>/src/board/tasks`

### Failure behavior

If no layout is found:
- print `bilu board: error: could not locate board root (expected .bilu/board or src/board)` to stderr
- exit `1`

## Helper API (what code should call)

In `paths.sh`:
- `board_detect_paths`
  - exports:
    - `BOARD_ROOT`
    - `BOARD_CONFIG_PATH`
    - `BOARD_DEFAULT_JSON_PATH`
    - `BOARD_TASKS_DIR`
    - `BOARD_LAYOUT` (`installed` or `repo`)

Optionally also export:
- `BOARD_PROJECT_ROOT` (where `.bilu` lives, for installed layout)

## Acceptance tests (what to add)

1) Repo layout:
- from repo root: `sh src/cli/bilu board --list`
- from a subdir: `(cd src && sh ../src/cli/bilu board --list)`

2) Installed layout:
- Use existing install/init tests to create a temp `.bilu`.
- From the install dir root: `./bilu board --list`
- From a nested dir: `(cd nested && ../bilu board --list)`

All tests run with `NO_COLOR=1` for stable output.

## References

- `src/board/tasks/02-03-layout-detection.md`
- `src/board/tasks/02-02-module-skeleton.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/cli/bilu`

# Outcomes

- Implemented project-local `.bilu`-first detection with a safe fallback to template-root detection in `.bilu/cli/commands/board/paths.sh`.
- Exported `BOARD_LAYOUT` and `BOARD_PROJECT_ROOT` (when applicable), plus added `board_config_path`, `board_default_json_path`, and `board_tasks_dir` helpers.
- Updated `.bilu/cli/commands/board.sh` to emit the canonical “could not locate board root (expected .bilu/board or src/board)” error.
- Added a regression test ensuring a local project `.bilu` takes precedence over the caller's `script_dir`; tests: `sh tests/run.sh`.

# Description
Define how bilu board locates the board root and files in both repo and installed layouts, reusing .bilu/cli/bilu layout detection where possible and exposing helpers for config/default/tasks paths.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- planning
# depends_on
