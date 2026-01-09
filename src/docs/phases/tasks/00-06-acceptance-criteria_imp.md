# Phase 00 Task Implementation Plan — Acceptance criteria

Task: `src/docs/phases/tasks/00-06-acceptance-criteria.md`

This implementation plan turns the “acceptance criteria” list into a versioned, test-backed contract. It aligns with `src/docs/research/shell-only-cli-advanced-notes.md` by keeping tests command-oriented (Bats-style without deps), enforcing exit codes (`0/1/2`), and ensuring output is stable under `NO_COLOR`.

## Outcome (what “done” means)

1) The acceptance criteria are written as executable checks (tests) where practical.
2) The remaining “manual-only” criteria are explicitly documented as manual QA steps.
3) `src/docs/phases/tasks/00-06-acceptance-criteria.md` becomes the single checklist for “board v1 done”.

## Convert criteria into checks

### Must pass (automated)

From `00-06-acceptance-criteria.md`:

1) `bilu board --list` prints a stable list and exits `0`
- Test:
  - run `sh src/cli/bilu board --list`
  - assert exit `0`
  - assert stdout contains a stable marker (initially: “board listing”; later: a header like `STATUS` or a known task title)

2) `bilu board --list --filter=status --filter-value=todo` filters correctly
- Test:
  - run with filter flags (both long and alias variants)
  - assert exit `0`
  - assert stdout indicates filter applied and/or only matching tasks appear (once real data output exists)

3) Aliases work: `-l`, `-f`, `-fv`
- Test:
  - run `bilu board -l -f status -fv todo`
  - assert exit `0`

4) Unknown flags exit `2` and show usage
- Test:
  - run `bilu board -x`
  - assert exit `2`
  - assert stderr contains `Usage:` (or `bilu board:` + `Usage:`)

5) Works in repo layout and installed layout
- Tests:
  - Repo layout: run directly from repo (already done by existing tests).
  - Installed layout: leverage `tests/install.test.sh` flow to create `.bilu`, then run `./bilu board --list`.
  - Ensure installed run can find board files under `.bilu/board`.

6) No required dependencies beyond shell + coreutils
- Enforced by policy + smoke checks:
  - Ensure code paths do not call `jq`, `fzf`, `gum`, etc.
  - Tests should run without those tools present.

### Nice to have (explicitly deferred or staged)

1) `--view=kanban` prints a readable kanban layout
- Stage as Phase 03 acceptance; add a minimal test:
  - run `--view=kanban` with `NO_COLOR=1`
  - assert output contains column titles (e.g. “Backlog”, “In Progress”, “Review”, “Done”)

2) `--tui` offers keyboard navigation and search
- Manual QA only (document under Phase 06 manual TUI checklist).

3) Edit status/priority safely and persist to disk
- Add automated persistence tests once actions exist (Phase 05):
  - operate on a temp copy of a markdown task file
  - change status/priority
  - verify only the intended section changed

## Exit codes contract (lock it)

Per research note and docs:
- `0`: success
- `1`: data/config/runtime error
- `2`: usage error (bad args)

Tests should assert exit codes explicitly.

## Output stability rules (for tests)

To avoid flaky assertions:
- Run tests with `NO_COLOR=1` to remove ANSI output.
- Prefer matching stable markers:
  - headers
  - known task titles
  - deterministic column labels

## Concrete repo changes (what to do next)

1) Expand `tests/board.test.sh`:
- Assert exit code `2` for unknown flags (currently it only asserts non-zero).
- Add a test for missing paired flags (`--filter` without `--filter-value`).
- Add an installed-layout test case (may live in `tests/install.test.sh` or new `tests/board-installed.test.sh`).

2) Keep docs in sync:
- Ensure `src/docs/bilu-cli.md` reflects all accepted flags and aliases.
- When adding new flags (`--view`, `--no-color`, `--validate`), add acceptance bullets + tests.

## Acceptance checks

- “Must pass” criteria are all covered by automated tests.
- “Nice to have” are explicitly linked to later phases (03/04/05) and have either deferred or minimal smoke tests.
- Tests pass under `sh tests/run.sh`.

## References

- `src/docs/phases/tasks/00-06-acceptance-criteria.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
- `tests/board.test.sh`
- `src/docs/phases/06-testing-and-docs.md`

