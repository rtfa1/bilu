# Phase 00 — Board data audit

## Goal

Audit the current board data and document inconsistencies that the UI must normalize.

## Checklist

- [x] Inventory board files:
  - [x] `.bilu/board/config.json`
  - [x] `.bilu/board/default.json`
  - [x] `.bilu/board/tasks/*.md`
- [x] List inconsistencies and decide normalization targets:
  - [x] status values (e.g. `Done` vs `DONE`)
  - [x] priority casing (e.g. `High` vs `HIGH`)
  - [x] kind representation (e.g. `kind` vs legacy keys like `bug` / `improvement`)
- [x] Confirm how to handle broken links (e.g. task points to missing `.md`).
- [x] Confirm how to handle `depends_on` paths (warn vs error).

## Acceptance

- A written list of known inconsistencies with explicit normalization rules to resolve them.

## Work done

- Audited `.bilu/board/config.json`, `.bilu/board/default.json`, and `.bilu/board/tasks/*.md`.
- Documented implementation-ready normalization rules (status/priority/kind/tags + TSV escaping).
- Documented link resolution rules for repo vs installed layout and how to handle missing `link`/`depends_on` targets.

## References

- `.bilu/board/config.json`
- `.bilu/board/default.json`
- `.bilu/board/tasks/`

---

## Implementation plan

# Phase 00 Task Implementation Plan — Board data audit

Task: `.bilu/board/tasks/00-02-board-data-audit.md`

This implementation plan produces the concrete “data audit” deliverable the UI depends on: a written list of inconsistencies plus explicit normalization rules. It applies the guardrails from `.bilu/storage/research/shell-only-cli-advanced-notes.md` (or `src/storage/research/shell-only-cli-advanced-notes.md` in repo layout) (TSV internal format, strict normalization, avoid brittle JSON parsing at runtime).

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

- `.bilu/board/config.json` (canonical enums + ordering)
- `.bilu/board/default.json` (task index)
- `.bilu/board/tasks/*.md` (task details)
- `.bilu/storage/research/shell-only-cli-advanced-notes.md` (parsing/portability guidance)

## Current state summary (observed)

### `.bilu/board/config.json`

- Canonical statuses + ordering:
  - `BACKLOG`, `TODO`, `INPROGRESS`, `BLOCKED`, `DONE`, `REVIEW`, `ARCHIVED`, `CANCELLED`
- Canonical priorities + weights:
  - `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `TRIVIAL`
- Canonical kinds:
  - `task`, `bug`, `feature`, `improvement`

### `.bilu/board/default.json` (index)

Observed patterns:
- `status` uses canonical enum-like values (e.g. `TODO`, `INPROGRESS`, `CANCELLED`) ✅
- `priority` currently uses `MEDIUM` (canonical casing) ✅
- `kind` currently uses `task` (canonical casing) ✅
- `link` values point to `board/tasks/*.md` and resolve relative to the *layout root* (`src/` for repo layout; `.bilu/` for installed layout), not relative to the `board/` directory ✅

### `.bilu/board/tasks/*.md` (details)

Observed patterns:
- Tasks are primarily narrative/spec documents (no structured `Status`/`Priority` headers to normalize today).
- The UI should still treat task markdown as untrusted input (tabs/newlines/odd characters) when deriving any internal records.

## Inconsistencies to normalize (explicit list)

Even though the current `.bilu/board/default.json` is consistent, the UI should normalize/tolerate human input in both JSON and (future) task metadata.

1) **Status value normalization**
- Accept human-friendly variants like `Done`, `In Progress`, `To Do`, etc.
- Canonical enum in config: `BACKLOG|TODO|INPROGRESS|BLOCKED|REVIEW|DONE|ARCHIVED|CANCELLED`

2) **Priority casing normalization**
- Accept `High`, `MEDIUM`, etc.
- Canonical enum in config: `CRITICAL|HIGH|MEDIUM|LOW|TRIVIAL`

3) **Kind representation**
- Accept `task|bug|feature|improvement` case-insensitively.
- Tolerate legacy boolean keys (if they ever appear) like `bug:true` by mapping to the canonical `kind`.

4) **Path/link semantics**
- `link` values use `board/tasks/<file>.md` and must resolve relative to the layout root, not relative to `board/` itself.
- Missing `link` targets must not crash the UI.

5) **`depends_on` targets**
- Missing dependency targets must be treated as warnings (default) and not crash rendering.

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

- Resolve `link` relative to the layout root (parent directory of `board/`):
  - if index path is `src/board/default.json` ⇒ layout root is `src/` ⇒ task path is `src/<link>`
  - if index path is `.bilu/board/default.json` ⇒ layout root is `.bilu/` ⇒ task path is `.bilu/<link>`
- If the resolved `link` points to a missing file: warn (stderr) and still render the card.
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

- `.bilu/board/phases/00-board-ui-overview.md`
- `.bilu/board/tasks/00-02-board-data-audit.md`
- `.bilu/storage/research/shell-only-cli-advanced-notes.md`
- `.bilu/board/config.json`
- `.bilu/board/default.json`
- `.bilu/board/tasks/`

# Description
Audit .bilu/board/config.json, .bilu/board/default.json, and .bilu/board/tasks/*.md to identify inconsistencies (status/priority/kind, broken links, depends_on) and define the normalization rules the UI must apply.
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
- usability
# depends_on
