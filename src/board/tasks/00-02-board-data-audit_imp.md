# Phase 00 Task Implementation Plan — Board data audit

Task: `src/board/tasks/00-02-board-data-audit.md`

This implementation plan produces the concrete “data audit” deliverable the UI depends on: a written list of inconsistencies plus explicit normalization rules. It applies the guardrails from `src/storage/research/shell-only-cli-advanced-notes.md` (TSV internal format, strict normalization, avoid brittle JSON parsing at runtime).

## Outcome (what “done” means)

1) A written audit report exists (in this file) describing:
- the current board file set
- observed inconsistencies
- the exact normalization rules and fallbacks
- how broken links and `depends_on` are handled

2) The audit decisions are actionable by implementation (Phase 01+), especially:
- normalized enum sets for `status`, `priority`, `kind`
- explicit behavior for invalid/missing fields

## Inputs reviewed (current repo)

- `src/board/config.json` (canonical enums + ordering)
- `src/board/default.json` (task index)
- `src/board/tasks/*.md` (task details)
- `src/storage/research/shell-only-cli-advanced-notes.md` (parsing/portability guidance)

## Current state summary (observed)

### `src/board/config.json`

- Canonical statuses + ordering:
  - `BACKLOG`, `TODO`, `INPROGRESS`, `BLOCKED`, `DONE`, `REVIEW`, `ARCHIVED`, `CANCELLED`
- Canonical priorities + weights:
  - `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `TRIVIAL`
- Canonical kinds:
  - `task`, `bug`, `feature`, `improvement`

### `src/board/default.json` (index)

Observed patterns:
- `status` uses canonical enum-like values (e.g. `TODO`, `INPROGRESS`, `CANCELLED`) ✅
- `priority` casing is inconsistent (`HIGH`, `High`, `Medium`) ❌
- `kind` is sometimes missing; legacy keys sometimes appear (`bug`, `improvement`) ❌
- `link` values point to `board/tasks/*.md` (path-like strings) ✅

### `src/board/tasks/*.md` (details)

Observed patterns:
- `# Priority` uses human-cased values like `High`, `Medium` (not canonical casing) ❌
- `# Status` uses `Done` (human-cased and not aligned to config casing) ❌
- `# depends_on` uses paths with a different prefix (some reference `docs/...`), which does not match `default.json` paths ❌

## Inconsistencies to normalize (explicit list)

1) **Status value normalization**
- Input variants in markdown: `Done`
- Canonical enum in config: `DONE`

2) **Priority casing normalization**
- Input variants: `High`, `Medium`, plus JSON has `HIGH`, `Medium`, `High`, etc.
- Canonical enum in config: `HIGH`, `MEDIUM`, etc.

3) **Kind representation**
- JSON sometimes uses `kind`, sometimes uses legacy keys like `bug` / `improvement` instead.
- Canonical enum in config: `task|bug|feature|improvement`

4) **Path/link inconsistencies**
- JSON `link` uses `board/tasks/<file>.md`
- Markdown `# depends_on` entries may reference `docs/...` paths (likely wrong/outdated)
- Some referenced files may be missing (must not crash)

## Normalization rules (implementation-ready)

Per `shell-only-cli-advanced-notes.md`, normalize early and produce a strict internal record (TSV) with no tabs/newlines in fields.

### 1) Status normalization

Canonical set: `BACKLOG|TODO|INPROGRESS|BLOCKED|REVIEW|DONE|ARCHIVED|CANCELLED`

Accept the following case-insensitive mappings:
- `done` → `DONE`
- `in progress`, `in-progress`, `inprogress` → `INPROGRESS`
- `to do`, `todo` → `TODO`
- `backlog` → `BACKLOG`
- `blocked` → `BLOCKED`
- `review` → `REVIEW`
- `archived` → `ARCHIVED`
- `cancelled`, `canceled` → `CANCELLED`

Fallback behavior:
- Unknown status → warn to stderr + default to `TODO` (or `BACKLOG`; choose one and document)

### 2) Priority normalization

Canonical set: `CRITICAL|HIGH|MEDIUM|LOW|TRIVIAL`

Accept case-insensitive mappings:
- `critical` → `CRITICAL`
- `high` → `HIGH`
- `medium` → `MEDIUM`
- `low` → `LOW`
- `trivial` → `TRIVIAL`

Fallback behavior:
- Unknown priority → warn to stderr + default to `MEDIUM`

### 3) Kind normalization

Canonical set: `task|bug|feature|improvement`

Rules:
- If `kind` exists and matches canonical set (case-insensitive), normalize to lowercase canonical.
- Else if legacy keys are present in JSON:
  - if key `bug` exists → `kind=bug`
  - else if key `improvement` exists → `kind=improvement`
  - else if key `feature` exists → `kind=feature`
- Else default: `kind=task`

### 4) Tags normalization

Rules:
- Keep tags as-is (lowercase strings in current config).
- If a tag is not present in `config.json.tags`, keep it but warn (non-fatal).

### 5) Fields escaping for internal TSV

Rules:
- Replace `\t` and `\n` in `title`/`description` with spaces before writing TSV.
- Never allow literal tabs/newlines inside a TSV field.

## Broken links and dependencies (policy)

### `link` (task detail path)

- If `link` points to a missing file: warn (stderr) and still render the card.
- TUI “open” action:
  - if file missing, show an error message in the status bar (do not crash).

### `depends_on`

- Treat missing `depends_on` targets as warnings by default.
- Provide `bilu board --validate` option later to choose severity:
  - default: warn-only
  - optional strict mode: non-zero exit on missing dependencies

## Recommended “source of truth” direction (ties to Phase 01)

Per the research note, runtime JSON parsing in shell is fragile. Prefer:
- `tasks/*.md` as source of truth
- derive an internal TSV (and optionally `default.json`) via an explicit `--rebuild-index`

If you keep `default.json` as the source of truth instead, strongly consider allowing an optional `python3` helper for JSON parsing, or constrain JSON strictly to formats the project itself emits.

## Deliverables for later phases

- A single mapping table (status/priority/kind) implementable in `awk`/shell.
- A validation policy for missing files and bad references.
- TSV escaping rules that all renderers can rely on.

## References

- `src/board/phases/00-board-ui-overview.md`
- `src/board/tasks/00-02-board-data-audit.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/config.json`
- `src/board/default.json`
- `src/board/tasks/`

