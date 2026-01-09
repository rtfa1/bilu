# Phase 05 Task Implementation Plan — Persistence tests

Task: `src/docs/phases/tasks/05-06-persistence-tests.md`

This plan adds non-interactive tests for persistence (editing markdown + regenerating derived outputs) without relying on the TUI. It follows `src/docs/research/shell-only-cli-advanced-notes.md`: command-oriented tests, deterministic output, atomic writes, and no runtime third-party deps.

## Outcome (what “done” means)

1) Tests cover status/priority edits on markdown tasks using a temp workspace fixture.
2) Tests verify edits are scoped (only the intended section changes).
3) Tests verify atomic-write behavior (no partial/invalid file states).
4) Tests verify list output reflects edits (non-interactive path).
5) Tests run via `sh tests/run.sh`.

## Test strategy (portable shell)

Principles:
- Never mutate repo sources under `src/board/tasks/` during tests.
- Copy fixtures into a temp directory per test.
- Point the CLI at that temp layout (by running the CLI from inside the temp “repo” root).
- Force deterministic environment:
  - `NO_COLOR=1`
  - `LC_ALL=C` (if any sorting affects output)

## Fixture layout

Create a minimal fixture board in a temp dir:
- `.bilu/cli/bilu` (copy from template install or reuse repo `src/cli/bilu` with correct relative structure)
- `.bilu/board/tasks/*.md` (a few small tasks)
- `.bilu/board/config.json` (minimal config)

Alternatively (simpler): copy the existing installed template structure:
- copy `src/cli`, `src/board` into `<tmp>/src/...` and execute `<tmp>/src/cli/bilu` from within `<tmp>`

The key requirement is: the CLI layout detection finds the board directory inside the temp tree.

## Commands under test (expected to exist by Phase 05)

These tests assume Phase 05 editing tasks implement non-interactive actions (or CLI flags) that can be invoked without the TUI:

- Status edit:
  - option A (recommended): `bilu board --set-status <task-id> <STATUS>`
  - option B: `bilu board --edit-status ...`
- Priority edit:
  - `bilu board --set-priority <task-id> <PRIORITY>`
- List:
  - `bilu board --list` (already exists as a placeholder; tests should be enabled once it lists from markdown/TSV)
- Optional:
  - `bilu board --rebuild-index --write` (derived artifacts)

If exact flag names change, update the tests to match the authoritative help text (Phase 02-05).

## Assertions (what to check)

### 1) Status edit updates only the status section

Given a task markdown file with sections including `# Status`:
- run status edit
- assert:
  - the `# Status` value changed to the expected normalized value
  - other sections (Title/Description/Priority/Depends) are byte-identical

Implementation suggestion for a robust assertion:
- snapshot file before edit: `cp task.md before.md`
- edit
- normalize away the status line for comparison and diff the rest:
  - extract “everything except the status value line” using `awk` state machine
  - compare remaining output between before/after

### 2) Priority edit updates only the priority section

Same structure as status test.

### 3) Atomic write behavior

Shell tests cannot reliably observe partial writes, but we can assert:
- after the command returns, the file:
  - exists
  - is non-empty
  - still contains required headers (e.g. `# Status`, `# Priority`)
- if you implement temp+mv in the same directory, ensure:
  - no leftover temp files remain (pattern-based check, if you name them predictably)

### 4) List output reflects edits

After editing:
- run `bilu board --list` (with `NO_COLOR=1`)
- assert the edited task appears with the updated status/priority in its row/card output (string match).

If the list output is view-dependent, allow a stable “table” view for tests:
- `bilu board --list --view=table --no-color` (recommended for test stability).

### 5) Locking behavior (optional cross-check)

If the lock module is implemented (05-05):
- acquire lock in one background process (hold with `sleep`)
- attempt an edit with short timeout and assert it fails with a clear error.

## Where to put the tests

Add a new test file:
- `tests/persistence.test.sh`

Follow the existing test harness pattern:
- avoid external dependencies
- assert exit codes and stdout/stderr content

## Acceptance checks

- `sh tests/run.sh` includes persistence tests and passes.
- Tests do not touch repo board files (only temp fixtures).
- Tests are deterministic (no colors, stable ordering).

## References

- `src/docs/phases/tasks/05-06-persistence-tests.md`
- `src/docs/phases/05-persistence-and-editing.md`
- `src/docs/phases/tasks/05-01-edit-status-in-markdown_imp.md`
- `src/docs/phases/tasks/05-02-edit-priority-in-markdown_imp.md`
- `src/docs/phases/tasks/05-05-file-locking-and-concurrency_imp.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
