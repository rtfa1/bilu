# Phase 02 Task Implementation Plan — Integration tests for parsing

Task: `src/board/tasks/02-07-integration-tests-for-parsing.md`

This implementation plan strengthens the test suite so routing and argument parsing can’t regress while the board command is modularized. It follows `src/storage/research/shell-only-cli-advanced-notes.md`: keep tests command-oriented (Bats-style without deps), assert exit codes explicitly, and avoid ANSI dependencies by running with `NO_COLOR=1` when applicable.

## Outcome (what “done” means)

1) Tests cover routing + parsing edge cases and assert correct exit codes.
2) Tests are stable across macOS/Linux shells (no terminal/ANSI dependencies).
3) The test suite (`sh tests/run.sh`) passes consistently.

## What to test (minimum set)

### A) Help routing

- Command: `bilu board --help`
- Expect:
  - exit `0`
  - stdout contains `Usage: bilu board`

### B) Unknown flag handling

- Command: `bilu board -x`
- Expect:
  - exit `2` (usage error)
  - stderr contains `Usage: bilu board`

### C) Paired flag enforcement

- Command: `bilu board --list --filter status`
- Expect:
  - exit `2`
  - stderr mentions missing `--filter-value`

- Command: `bilu board --list --filter-value todo`
- Expect:
  - exit `2`
  - stderr mentions missing `--filter`

### D) Alias correctness

- Command: `bilu board -l -f status -fv todo`
- Expect:
  - exit `0`
  - stdout indicates the filter was applied (until real listing exists, match a stable marker)

## Where these tests live

Recommended:
- Expand `tests/board.test.sh` (already exists) to include:
  - exit code assertions for `--help` and `-x`
  - paired-flag failure cases
  - ensure stderr vs stdout usage text expectations are consistent

## Test stability rules

- Run commands with:
  - `NO_COLOR=1` (once color support is introduced)
- Never assert on ANSI escape sequences.
- Prefer matching stable, minimal strings:
  - `Usage: bilu board`
  - `unknown option`
  - `--filter-value is required`

## Implementation steps

1) Update `tests/board.test.sh`:
- Add `--help` test (exit `0`).
- Change the “unknown option” test to assert exit `2` (currently it asserts only non-zero).
- Add the two paired-flag negative tests.

2) Keep tests fast:
- No file system setup beyond what’s already required.
- No dependence on installed layout for Phase 02 parsing tests (installed layout tests can live in a separate test file if needed).

## Acceptance checks

- `sh tests/run.sh` passes.
- Parsing regressions are caught by tests (exit codes + usage text).

## References

- `src/board/tasks/02-07-integration-tests-for-parsing.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `tests/board.test.sh`
- `tests/run.sh`

