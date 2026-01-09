# Phase 06 — CLI parsing tests

## Goal

Prevent regressions in flags and aliases.

## Checklist

- [ ] Add tests for:
  - [ ] `bilu board --help` exits `0`
  - [ ] `bilu board -l` works
  - [ ] unknown flags exit `2`
  - [ ] missing required flag values exit `2`
  - [ ] `--filter=status --filter-value=todo` works
  - [ ] `-f status -fv todo` works

## Acceptance

- Parser tests pass consistently across platforms.
---

## Implementation plan

# Phase 06 Task Implementation Plan — CLI parsing tests

Task: `src/board/tasks/06-02-cli-parsing-tests.md`

This plan locks down the `bilu board` option parser with portable, deterministic shell tests. It follows `src/storage/research/shell-only-cli-advanced-notes.md`: explicit flag parsing behavior, predictable exit code `2` for usage errors, and command-oriented tests (assert exit code + stdout/stderr patterns).

## Outcome (what “done” means)

1) Parser behavior is covered by automated tests and won’t regress silently.
2) Tests assert correct exit codes (`0` success, `2` usage error).
3) Tests pass on macOS and Linux with POSIX `sh`.

## Authoritative behaviors to test

From the parser spec (`src/board/tasks/02-04-args-parser.md`):

Success cases (exit `0`):
- `bilu board --help`
- `bilu board --list`
- `bilu board -l`
- `bilu board --list --filter=status --filter-value=todo`
- `bilu board -l -f status -fv todo`
- (if supported) `--filter status --filter-value todo`

Usage errors (exit `2`):
- unknown flag: `bilu board -x`
- missing required value: `bilu board -f`
- missing required value: `bilu board -fv`
- missing paired option:
  - `bilu board -l -f status`
  - `bilu board -l -fv todo`
- unexpected positional args:
  - `bilu board --list extra`
- end-of-options behavior:
  - if `--` is supported but positionals are not: `bilu board -- --list` should exit `2`

## Where tests live

Preferred:
- Keep `tests/board.test.sh` as a small smoke test.
- Add a dedicated parser test file with detailed cases:
  - `tests/cli-parsing.test.sh`

The test runner (`tests/run.sh`) should include the new file.

## Test structure (portable)

Use a small helper pattern per test file:
- `run()` to execute a command capturing stdout/stderr and exit code.
- `assert_status <expected>`
- `assert_stdout_contains <needle>` / `assert_stderr_contains <needle>`

Constraints:
- don’t require `bash`, `jq`, `mktemp` extensions, or GNU-only flags
- don’t rely on colors:
  - run with `NO_COLOR=1` (even if board list currently prints no ANSI)

## Specific upgrades to existing tests

`tests/board.test.sh` currently checks “non-zero” for unknown flags. Tighten it:
- assert unknown flag returns `2` specifically
- add missing-value cases returning `2`
- assert `--help` returns `0`

This aligns with the spec and makes failures actionable.

## Acceptance checks

- `sh tests/run.sh` passes on macOS and Linux.
- Parser behavior matches `02-04-args-parser.md` exactly.
- Unknown flags and missing values consistently return exit code `2`.

## References

- `src/board/tasks/06-02-cli-parsing-tests.md`
- `src/board/tasks/02-04-args-parser.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `tests/board.test.sh`

# Description
Add parser regression tests for bilu board covering help output, -l alias, unknown flags exiting 2, missing values exiting 2, and both long and short filter forms (--filter=status --filter-value=todo and -f status -fv todo).
# Status
TODO
# Priority
MEDIUM
# Kind
task
# Tags
- documentation
- planning
- testing
# depends_on
