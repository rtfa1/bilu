# Phase 01 Task Implementation Plan — Normalization rules

Task: `src/board/tasks/01-03-normalization-rules.md`

This implementation plan defines the normalization table and the exact runtime behavior for unknown/missing values. It is consistent with:
- the board audit (`src/board/tasks/00-02-board-data-audit_imp.md`)
- the schema and TSV contract (`src/board/tasks/01-02-normalized-task-schema_imp.md`)
- the shell guidance (`src/storage/research/shell-only-cli-advanced-notes.md`): normalize early, keep TSV unambiguous, warn but don’t crash.

## Outcome (what “done” means)

1) A normalization table exists (status/priority/kind/tags) with explicit mappings.
2) Fallback behavior is defined and consistent across all loaders (md/json).
3) Warnings vs errors are clearly separated:
- normalization issues warn and continue by default
- `--validate` can elevate certain issues later (Phase 01-05)

## Canonical enums (from `src/board/config.json`)

### Status (canonical)

`BACKLOG|TODO|INPROGRESS|BLOCKED|DONE|REVIEW|ARCHIVED|CANCELLED`

### Priority (canonical)

`CRITICAL|HIGH|MEDIUM|LOW|TRIVIAL`

### Kind (canonical)

`task|bug|feature|improvement`

## Normalization table (authoritative)

All matching is case-insensitive unless noted.

### Status normalization

Map inputs → canonical:
- `done` → `DONE`
- `in progress` → `INPROGRESS`
- `in-progress` → `INPROGRESS`
- `inprogress` → `INPROGRESS`
- `to do` → `TODO`
- `todo` → `TODO`
- `backlog` → `BACKLOG`
- `blocked` → `BLOCKED`
- `review` → `REVIEW`
- `archived` → `ARCHIVED`
- `cancelled` → `CANCELLED`
- `canceled` → `CANCELLED`

Fallback:
- unknown/missing → warn (stderr) + default to `TODO`

### Priority normalization

Map inputs → canonical:
- `critical` → `CRITICAL`
- `high` → `HIGH`
- `medium` → `MEDIUM`
- `low` → `LOW`
- `trivial` → `TRIVIAL`

Fallback:
- unknown/missing → warn (stderr) + default to `MEDIUM`

### Kind normalization

Rules (in order):
1) If `kind` is present:
   - normalize case
   - accept only canonical values; otherwise treat as unknown
2) If `kind` missing and source is JSON index:
   - map legacy keys:
     - `bug` key present → `bug`
     - `improvement` key present → `improvement`
     - `feature` key present → `feature`
3) Otherwise:
   - default to `task`

Fallback:
- unknown kind → warn (stderr) + default to `task`

### Tags normalization

Rules:
- Treat tags as opaque identifiers.
- Keep tag values as-is (current config uses lowercase).
- If a tag is not present in `config.json.tags`, keep it but warn (non-fatal).

## Escaping rules (TSV safety)

Per research note:
- TSV fields must not contain literal tabs or newlines.

Rules:
- In `title` and any description-derived preview fields:
  - replace `\t` and `\n` with single spaces
  - collapse repeated whitespace if needed (optional)

## Warning format (make it consistent)

Define a consistent warning prefix so tests and users can recognize it:
- `bilu board: warn: <message>`

Examples:
- `bilu board: warn: unknown status "Doing"; defaulting to TODO (task: 01-something)`
- `bilu board: warn: unknown tag "Frontend"; keeping as-is (task: 01-something)`

Warnings go to stderr and do not change exit code in normal list/render commands.

## Where normalization happens (single source of truth in code)

To avoid inconsistent behavior:
- implement normalization in one module/function (e.g. `normalize.sh`)
- all loaders must pass raw values through the normalizer
- renderers must never “guess” or normalize on their own

## Tests to lock normalization behavior

Add/extend tests (Phase 06 tasks):
- status variants normalize correctly:
  - `Done` → `DONE`
  - `in-progress` → `INPROGRESS`
- priority variants normalize correctly:
  - `High` → `HIGH`
  - `medium` → `MEDIUM`
- unknown values:
  - produce warnings on stderr
  - fall back to defaults

Run tests with `NO_COLOR=1` to keep output stable.

## Acceptance checks

- The normalization table above is implemented in code and referenced by docs.
- Defaulting behavior is consistent and does not crash rendering.
- Warnings go to stderr and do not pollute stable stdout formats (when possible).

## References

- `src/board/tasks/01-03-normalization-rules.md`
- `src/board/tasks/00-02-board-data-audit_imp.md`
- `src/board/tasks/01-02-normalized-task-schema_imp.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/config.json`

