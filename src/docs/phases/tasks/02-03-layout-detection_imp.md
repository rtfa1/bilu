# Phase 02 Task Implementation Plan — Layout detection

Task: `src/docs/phases/tasks/02-03-layout-detection.md`

This implementation plan ensures the board module can locate its data (`config.json`, `default.json`, `tasks/`) in both repo and installed layouts, from any working directory. It aligns with the project constraint “no reliance on `$PWD`”, and with the “boring and explicit” shell guidance in `src/docs/research/shell-only-cli-advanced-notes.md`.

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

- `src/docs/phases/tasks/02-03-layout-detection.md`
- `src/docs/phases/tasks/02-02-module-skeleton_imp.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
- `src/cli/bilu`

