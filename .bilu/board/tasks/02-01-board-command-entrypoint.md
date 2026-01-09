# Phase 02 — Board command entrypoint

## Goal

Make `bilu board` a first-class command with a thin dispatcher and predictable routing.

## Checklist

- [x] Confirm `src/cli/bilu` routes `board` to `src/cli/commands/board.sh`.
- [x] Ensure `board.sh` is thin (dispatch only; no heavy logic).
- [x] Add/verify `bilu help` documents `board`.
- [x] Define exit codes for:
  - [x] unknown subcommand/flag (`2`)
  - [x] runtime error (`1`)

## Acceptance

- Running `bilu board --help` prints usage and exits `0`.
---

## Implementation plan

# Phase 02 Task Implementation Plan — Board command entrypoint

Task: `src/board/tasks/02-01-board-command-entrypoint.md`

This implementation plan ensures `bilu board` is a stable “first-class” CLI entrypoint: predictable routing, thin dispatcher, consistent exit codes, and accurate help. It follows `src/storage/research/shell-only-cli-advanced-notes.md` by keeping parsing explicit, using exit codes (`0/1/2`), and avoiding brittle behavior hidden behind `set -e`.

## Outcome (what “done” means)

1) Routing is correct and tested:
- `src/cli/bilu` dispatches `board` to `src/cli/commands/board.sh`.
2) `src/cli/commands/board.sh` is a thin dispatcher (no heavy data/render logic).
3) Help is accurate:
- `bilu help` lists `board`
- `bilu board --help` prints board usage and exits `0`
4) Exit codes are consistent:
- `2` for usage errors
- `1` for runtime/data/config failures

## Current state (already true, verify and preserve)

- `src/cli/bilu` has:
  - `board) exec sh "$COMMANDS_ROOT/board.sh" "$@"`
  - help includes “board”
- `src/cli/commands/board.sh` currently contains both parsing + behavior output.
  - This will be split in Phase 02 tasks into modules, but this task ensures the entrypoint contract remains stable throughout refactors.

## Entry-point contract (what `board.sh` must guarantee)

### Behavior

- Accept `--help|-h` and exit `0`.
- Reject unknown flags with exit `2` and show usage.
- On runtime errors (missing board files, parse failures): exit `1` with an error to stderr.

### Interface

- `board.sh` reads arguments only from `$@` (no hidden env requirements).
- It may rely on the layout detection already performed by `src/cli/bilu` (i.e., `BILU_ROOT` exists in parent process), but if you don’t pass it down, `board.sh` must be able to locate board paths itself (Phase 02-03).

## Implementation steps

1) Keep routing stable
- Do not change how `src/cli/bilu` dispatches `board`.
- Ensure `src/cli/bilu help` always includes `board` in the command list.

2) Make `board.sh` “thin” (prepare for the module split)
- Phase 02 module plan calls for moving logic under `src/cli/commands/board/`.
- In this task, define the rule:
  - `board.sh` parses args and dispatches to a renderer/action module.
  - It should not contain file parsing, normalization, or rendering layout logic long-term.

3) Standardize error helpers
- Introduce a shared pattern (even before full module split):
  - `die()` for runtime errors (exit `1`)
  - `usage_error()` for bad args (exit `2`)

4) Ensure `bilu board --help` is accurate
- Usage text should match what `board.sh` actually accepts.
- Include examples and alias list (already documented in Phase 00-03).

## Tests to lock the entrypoint contract

Add/extend tests (command-oriented):
- `sh src/cli/bilu board --help` exits `0`.
- `sh src/cli/bilu board -x` exits `2` and prints `Usage:` to stderr.
- (later, once paths are implemented) missing board root should exit `1` with a clear message.

Run tests with `NO_COLOR=1` to keep output stable.

## Acceptance checks

- Entry-point routing remains correct after refactors.
- `board.sh` stays a dispatcher (logic migrates into `src/cli/commands/board/` modules in subsequent tasks).
- Exit code semantics are consistent with the project contract (`0/1/2`).

## References

- `src/board/tasks/02-01-board-command-entrypoint.md`
- `src/board/phases/02-cli-and-modules.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/cli/bilu`
- `src/cli/commands/board.sh`

## Outcomes

- Refactored `.bilu/cli/commands/board.sh` into a thin dispatcher and moved validation/list logic into `.bilu/cli/commands/board/{validate.sh,list.sh}`.
- Verified `bilu help` documents `board`, `bilu board --help` exits `0`, unknown flags exit `2`, and runtime/data/config failures exit `1`.
- Tests: `sh tests/run.sh`

# Description
Make bilu board a first-class command by wiring .bilu/cli/bilu to a thin .bilu/cli/commands/board.sh dispatcher, documenting it in bilu help, and standardizing exit codes (2 usage, 1 runtime).
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- documentation
- planning
# depends_on
