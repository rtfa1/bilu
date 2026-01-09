# Phase 06 Task Implementation Plan — Normalization tests

Task: `src/docs/phases/tasks/06-03-normalization-tests.md`

This plan adds deterministic tests that lock normalization behavior for status/priority/kind and TSV safety rules. It is based on the authoritative normalization table in `src/docs/phases/tasks/01-03-normalization-rules_imp.md` and the TSV contract in `src/docs/phases/tasks/02-06-internal-record-format_imp.md`, following the guidance in `src/docs/research/shell-only-cli-advanced-notes.md` (normalize early, keep TSV unambiguous, warnings to stderr, stable outputs).

## Outcome (what “done” means)

1) Normalization mappings are tested and stable across platforms.
2) Unknown/missing values default consistently and emit warnings to stderr (when warnings are enabled).
3) TSV invariants are enforced (no tabs/newlines in fields, correct field count).

## What to test (authoritative cases)

### Status normalization

Given raw inputs, expect canonical outputs:
- `Done` → `DONE`
- `done` → `DONE`
- `in-progress` → `INPROGRESS`
- `in progress` → `INPROGRESS`
- `INPROGRESS` → `INPROGRESS`
- `todo` → `TODO`
- unknown (e.g. `Doing`) → default `TODO` + warning (stderr)
- missing → default `TODO` + warning (stderr)

### Priority normalization

- `High` → `HIGH`
- `HIGH` → `HIGH`
- `medium` → `MEDIUM`
- unknown (e.g. `Urgent`) → default `MEDIUM` + warning (stderr)
- missing → default `MEDIUM` + warning (stderr)

### Kind normalization

Primary source (`kind` field) cases:
- `task` → `task`
- `BUG` → `bug` (if you normalize case to lowercase; match your spec)
- unknown → default `task` + warning (stderr)

Legacy JSON index cases (if still supported in loaders):
- legacy key present → mapped kind (e.g. `bug: true` → `bug`)
- missing kind + no legacy keys → default `task`

## Test approach

Prefer unit-ish tests against a single normalization entrypoint used by all loaders:
- `board_normalize_status`
- `board_normalize_priority`
- `board_normalize_kind`

If normalization is implemented in `awk`:
- provide a tiny harness that feeds raw values and captures normalized outputs.

If normalization is implemented in `sh`:
- source the module and call functions directly.

Rules:
- tests must be runnable with POSIX `sh`
- set `NO_COLOR=1` in tests
- keep output stable and machine-checkable

## TSV safety tests (internal record invariants)

Create inline sample records with intentionally bad content and assert the normalizer/validator:
- replaces tabs/newlines in `title` with spaces (or rejects; whichever your contract chooses—TSV v1 recommends replace)
- emits TSV lines with exactly the expected number of fields
- never outputs literal tab/newline inside a field

Use `awk -F '\t' 'NF!=10{exit 1}'` (or the v1 field count you standardized) to assert shape.

## Where tests live

Add:
- `tests/normalization.test.sh`

Optionally keep schema-specific helpers local to that test file (no shared framework required).

## Warnings behavior (testable contract)

If you emit warnings on stderr:
- ensure warnings use a stable prefix (recommended from Phase 01-03):
  - `bilu board: warn: ...`
- tests should assert:
  - stdout contains only normalized output
  - stderr contains warnings for unknown/missing values

If you add a `--quiet`/`--no-warn` flag later, tests should cover both modes.

## Acceptance checks

- `sh tests/run.sh` includes normalization tests and passes.
- Status/priority/kind mappings match `01-03-normalization-rules_imp.md`.
- TSV invariants match `02-06-internal-record-format_imp.md`.

## References

- `src/docs/phases/tasks/06-03-normalization-tests.md`
- `src/docs/phases/tasks/01-03-normalization-rules_imp.md`
- `src/docs/phases/tasks/02-06-internal-record-format_imp.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
