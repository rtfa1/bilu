# Phase 06 — Test matrix

## Goal

Define what gets tested (and what doesn’t) for a shell-only board UI.

## Checklist

- [ ] Define test categories:
  - [ ] CLI parsing
  - [ ] data normalization
  - [ ] rendering (table/kanban) in non-interactive mode
  - [ ] persistence edits (status/priority)
- [ ] Explicitly exclude TUI interaction testing (manual-only) unless a stable harness is introduced.
- [ ] Define required tools for tests (POSIX `sh`, coreutils).

## Acceptance

- A clear matrix exists and is referenced by the test suite.
---

## Implementation plan

# Phase 06 Task Implementation Plan — Test matrix

Task: `src/board/tasks/06-01-test-matrix.md`

This plan defines the automated test coverage for a shell-only board CLI while explicitly excluding full-screen TUI interaction testing (manual only). It aligns with `src/storage/research/shell-only-cli-advanced-notes.md`: command-oriented tests, deterministic output (NO_COLOR, fixed widths), and no runtime third-party deps.

## Outcome (what “done” means)

1) A clear test matrix exists (what we test vs what we don’t).
2) The matrix is referenced by the test suite (README or `tests/run.sh` banner).
3) Each category has at least one representative test and a place to add more.

## Test categories (authoritative)

### A) CLI parsing (POSIX `sh`)

Purpose:
- lock down flags/aliases and usage errors (exit code `2`).

Scope:
- `bilu board --list/-l`
- `--filter/-f`, `--filter-value/-fv` (paired requirement)
- unknown flags error out with usage
- `--` end-of-options behavior (if supported)

Non-goals:
- interactive keystroke parsing (TUI only)

Determinism requirements:
- run with `NO_COLOR=1`

### B) Data normalization (POSIX `sh` + `awk`)

Purpose:
- validate normalization rules (e.g. `Done` → `DONE`, `High` → `HIGH`) and strict TSV constraints.

Scope:
- normalization functions/modules (unit-ish)
- `bilu board --validate` behavior (exit code `1` on invalid data, `0` otherwise)
- derived index rebuild determinism if implemented (`--rebuild-index`)

Non-goals:
- parsing arbitrary JSON without helper deps; tests should only cover the shapes we emit/consume.

Determinism requirements:
- `LC_ALL=C` for any sort-dependent output

### C) Rendering (non-interactive views)

Purpose:
- ensure table/kanban renderers produce stable text output in non-interactive mode.

Scope:
- `--list --view=table` (recommended stable target for tests)
- `--list --view=kanban` in a constrained width (if implemented)
- no-color rendering (no ANSI escapes)

Non-goals:
- cursor movement / alternate-screen behavior (TUI)

Determinism requirements:
- `NO_COLOR=1`
- fixed width (recommend one of):
  - honor `COLUMNS` if renderer uses it, or
  - pass `--width <n>` (recommended) for pure determinism

### D) Persistence edits (non-interactive)

Purpose:
- verify file edits are safe and scoped, without invoking the TUI.

Scope:
- edit status/priority commands (Phase 05)
- atomic write (temp + `mv`)
- list reflects edits
- lock behavior (mkdir lock) if implemented

Non-goals:
- editor/pager spawning in automated tests

Determinism requirements:
- operate on temp fixtures; never mutate repo files

## Explicit exclusions (documented)

Automated tests must NOT attempt to validate:
- full-screen TUI interaction (key decoding, frame timing, selection movement)
- terminal state changes (alt screen, hidden cursor, `stty` changes)

These are manual-only and covered by the Phase 06 manual TUI script task.

## Required tools (authoritative)

Tests require only:
- POSIX `sh`
- coreutils (`cp`, `mv`, `rm`, `mkdir`, `mktemp`, `printf`)
- `awk`, `sed`

Optional (dev-only) tools:
- ShellCheck, shfmt (not required at runtime; can be recommended separately)

## Test suite mapping (where each category lives)

Existing:
- `tests/board.test.sh` → Category A (CLI parsing baseline)
- `tests/run.sh` → runner

Planned additions (recommended file names):
- `tests/cli-parsing.test.sh` → Category A expansion
- `tests/normalization.test.sh` → Category B
- `tests/renderer.test.sh` → Category C
- `tests/persistence.test.sh` → Category D

## Acceptance checks

- The test matrix is documented here and referenced from `tests/run.sh` or `src/board/phases/06-testing-and-docs.md`.
- Each category has at least one test file (or a clearly stated “pending until implemented” note).
- All tests are deterministic under `NO_COLOR=1`.

## References

- `src/board/tasks/06-01-test-matrix.md`
- `src/board/phases/06-testing-and-docs.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
