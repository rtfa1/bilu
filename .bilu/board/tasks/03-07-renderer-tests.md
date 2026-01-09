# Phase 03 — Renderer tests

## Goal

Add tests for non-interactive renderers without depending on ANSI formatting.

## Checklist

- [x] Add tests for:
  - [x] `--view=table` contains expected titles/statuses
  - [x] `--view=kanban` prints column headers (or markers) deterministically
  - [x] `--no-color` produces no ANSI escape sequences
- [x] Ensure tests don’t depend on terminal width (set a fixed width if needed).

## Acceptance

- Tests pass on CI and local shells with stable expectations.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Renderer tests

Task: `src/board/tasks/03-07-renderer-tests.md`

This implementation plan adds stable tests for non-interactive renderers (table and kanban) without relying on ANSI formatting or terminal quirks. It follows the shell-only guidance:
- tests should be command-oriented and assert exit codes + stable tokens
- use `NO_COLOR=1` / `--no-color` to avoid ANSI in test assertions
- avoid depending on actual terminal width; force deterministic width where needed

## Outcome (what “done” means)

1) Tests exist for:
- `--view=table` output markers
- `--view=kanban` output markers
- `--no-color` / `NO_COLOR` produces no ANSI escape sequences
2) Tests are stable across macOS/Linux and do not flake due to terminal width.
3) `sh tests/run.sh` passes consistently.

## What to test (v1, stable markers)

### A) Table view markers

Command:
- `NO_COLOR=1 sh src/cli/bilu board --list` (or later: `--view=table`)

Assertions:
- exit `0`
- stdout contains header tokens:
  - `STATUS`
  - `TITLE`
- stdout contains at least one known task title token (once real listing is implemented).

Note:
- Do not assert exact spacing/alignment; only match stable tokens.

### B) Kanban view markers

Command:
- `NO_COLOR=1 sh src/cli/bilu board --list --view=kanban`

Assertions:
- exit `0`
- stdout contains column titles (or markers):
  - `Backlog`
  - `In Progress`
  - `Review`
  - `Done`

If narrow mode prints `== Backlog (N) ==`, match `Backlog` rather than the full line.

### C) No-ANSI guarantee

Commands:
- `NO_COLOR=1 sh src/cli/bilu board --list`
- `sh src/cli/bilu board --list --no-color` (once implemented)

Assertions:
- stdout does not contain escape sequences:
  - no `\033[` patterns (simple grep check)

## Deterministic terminal width in tests

Renderer behavior depends on width (`stty size`). Tests must avoid depending on the host terminal.

Choose one deterministic strategy:

### Option A (recommended): honor `COLUMNS` when set

Implement renderers so:
- if `COLUMNS` is set and non-empty, use it instead of calling `stty size`

Then tests can do:
- `COLUMNS=70 NO_COLOR=1 ... --view=kanban` (forces narrow mode)
- `COLUMNS=120 NO_COLOR=1 ... --view=kanban` (forces wide mode)

### Option B: test hook for width detection

If you don’t want to honor `COLUMNS`, add a test-only env override:
- `BILU_TEST_COLUMNS`

Recommendation:
- Prefer Option A; it matches common shell conventions and keeps code simple.

## Where tests live

Add a new test file (recommended):
- `tests/board-render.test.sh`

Keep existing parsing tests in:
- `tests/board.test.sh`

This separation keeps failures easy to interpret.

## Implementation steps

1) Add `tests/board-render.test.sh`:
- run table view command and assert header tokens
- run kanban view command and assert column markers
- assert `NO_COLOR` disables ANSI escape sequences

2) Ensure tests do not depend on the real task loader until implemented:
- If the current implementation still prints placeholders, keep marker assertions aligned with current behavior, then update once renderers are implemented.

## Acceptance checks

- Tests pass locally and in CI environments.
- Tests remain stable with different terminal sizes and shells.
- No ANSI sequences appear when `NO_COLOR=1` or `--no-color`.

## References

- `src/board/tasks/03-07-renderer-tests.md`
- `src/board/tasks/03-01-table-view-spec.md`
- `src/board/tasks/03-03-kanban-layout-algorithm.md`
- `src/board/tasks/03-04-kanban-narrow-fallback.md`
- `src/board/tasks/03-02-color-theme-and-no-color.md`
- `tests/board.test.sh`

## Outcomes

- Added `tests/board-render.test.sh` to assert stable table/kanban markers without depending on ANSI or terminal width.
- Tests force deterministic width via `COLUMNS` and ensure `NO_COLOR` output has no `ESC[` sequences.
- Verified with `sh tests/run.sh`.

# Description
Add stable tests for non-interactive renderers (table and kanban) that assert on deterministic markers/tokens, verify --no-color produces no ANSI escapes, and avoid terminal-width flakiness by forcing a fixed width when needed.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- design
- devops
- frontend
- planning
- testing
- usability
# depends_on
