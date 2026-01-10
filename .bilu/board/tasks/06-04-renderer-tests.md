# Phase 06 — Renderer tests

## Goal

Verify non-interactive outputs without relying on ANSI formatting.

## Checklist

- [x] Add tests for:
  - [x] `--view=table` includes expected titles/statuses
  - [x] `--view=kanban` includes column headers/markers
  - [x] `--no-color` emits no escape sequences
- [x] Fix terminal width for tests if needed (e.g. by setting env or using a helper).

## Acceptance

- Render tests are stable and do not flake due to terminal differences.
---

## Implementation plan

# Phase 06 Task Implementation Plan — Renderer tests

Task: `src/board/tasks/06-04-renderer-tests.md`

This plan adds stable tests for non-interactive renderer outputs (table + kanban) without relying on ANSI formatting or host terminal quirks. It reuses the test strategy defined in `src/board/tasks/03-07-renderer-tests.md` and follows `src/storage/research/shell-only-cli-advanced-notes.md` (NO_COLOR, deterministic width, command-oriented assertions).

## Outcome (what “done” means)

1) Renderer tests exist and are deterministic across platforms.
2) Tests validate content via stable markers/tokens, not alignment.
3) Tests ensure `--no-color` / `NO_COLOR` emits no ANSI escape sequences.

## What to test (stable, non-flaky assertions)

### A) Table view contains expected tokens

Command (recommended stable target):
- `NO_COLOR=1 sh src/cli/bilu board --list --view=table`

Assertions:
- exit `0`
- stdout contains stable header tokens (exact set depends on the spec you implement), e.g.:
  - `STATUS`
  - `PRIORITY`
  - `TITLE`
- stdout contains at least one known task id/title token from fixtures.

Avoid:
- asserting exact spacing, column widths, or box-drawing characters.

### B) Kanban view contains column markers

Command:
- `NO_COLOR=1 sh src/cli/bilu board --list --view=kanban`

Assertions:
- exit `0`
- stdout contains the configured column headers (or stable markers) from `board/config.json`, e.g.:
  - `Backlog`
  - `In Progress`
  - `Review`
  - `Done`

If narrow fallback changes formatting, match just the header words, not full lines.

### C) No-ANSI guarantee

Commands:
- `NO_COLOR=1 ... --view=table`
- `... --view=table --no-color` (once implemented)

Assertion:
- stdout does not contain ANSI escape sequences (simple check):
  - reject `\033[` or `\x1b[` patterns

## Deterministic width

Renderer output often depends on terminal width. Tests must force width deterministically.

Preferred approach (recommended to implement in renderer width detection):
- If `COLUMNS` is set and non-empty, use it and do not call `stty size`.

Then tests can cover both modes:
- `COLUMNS=70 NO_COLOR=1 ... --view=kanban` (forces narrow mode)
- `COLUMNS=140 NO_COLOR=1 ... --view=kanban` (forces wide mode)

Alternative (if you don’t want to honor `COLUMNS`):
- implement a test-only override env var like `BILU_TEST_COLUMNS`.

## Fixtures (avoid dependence on repo data)

Renderer tests should run on a temp fixture board so results don’t change when the repo board changes.

Recommended:
- create a small fixture in a temp directory:
  - a few `board/tasks/*.md` with known titles/statuses
  - a minimal `board/config.json` with predictable column names
- run the CLI from that temp layout.

## Where tests live

Add:
- `tests/renderer.test.sh` (or `tests/board-render.test.sh`)

`tests/run.sh` should invoke it.

## Acceptance checks

- `sh tests/run.sh` passes consistently.
- Tests pass with `NO_COLOR=1` and do not rely on ANSI.
- Tests remain stable when the host terminal size differs.

## References

- `src/board/tasks/06-04-renderer-tests.md`
- `src/board/tasks/03-07-renderer-tests.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

# Description
Add stable renderer tests for non-interactive table and kanban views that assert key markers/titles/statuses, verify --no-color has no escape sequences, and force a deterministic width to avoid terminal-dependent flakes.
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
- testing
- usability
# depends_on
