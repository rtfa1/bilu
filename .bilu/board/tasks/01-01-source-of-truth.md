# Phase 01 — Choose source of truth

## Goal

Pick a single authoritative source for task metadata so rendering and editing are deterministic.

## Options

- **A (recommended):** `.bilu/board/tasks/*.md` is the source of truth; `.bilu/board/default.json` is derived.
- **B:** `.bilu/board/default.json` is the source of truth; markdown is detail-only.

## Checklist

- [x] Decide A or B.
- [x] Define precedence if both sources contain the same field.
- [x] Define what fields are editable (status/priority/kind/tags/etc).
- [x] Define whether editing should update markdown, JSON, or both.

## Acceptance

- A one-paragraph “source of truth” policy is written and will be enforced by the CLI.
---

## Implementation plan

# Phase 01 Task Implementation Plan — Choose source of truth

Task: `src/board/tasks/01-01-source-of-truth.md`

Task: `.bilu/board/tasks/01-01-source-of-truth.md`

This implementation plan selects and codifies a single authoritative source for task metadata so rendering/editing is deterministic. It follows `.bilu/storage/research/shell-only-cli-advanced-notes.md`, which strongly recommends “md is source-of-truth” and avoiding runtime JSON parsing in shell.

## Outcome (what “done” means)

1) A one-paragraph “source of truth” policy is written (in this file + referenced docs).
2) The CLI behavior enforces that policy (read path + write path are unambiguous).
3) The repo has a clear migration/rebuild story so existing inconsistent data does not block the UI.

## Recommendation (pick Option A)

Choose **Option A**:
- `.bilu/board/tasks/*.md` is the source of truth.
- `.bilu/board/default.json` is derived (generated/indexed) and treated as cache/index, not authoritative.

Rationale (from the research note):
- Editing markdown safely in shell is straightforward (section replacement + atomic `mv`).
- Parsing JSON safely without `jq` is fragile; avoid runtime JSON parsing where possible.
- A compiled internal format (TSV) keeps runtime fast and portable.

## Policy text (copy-paste into docs)

“Task metadata is sourced from `.bilu/board/tasks/*.md`. The board index (`.bilu/board/default.json`) is derived and may be regenerated at any time. All edits performed by the CLI write to task markdown files; index regeneration is explicit via a rebuild command. Renderers operate on normalized records produced from markdown.”

## Field ownership (what comes from where)

### Owned by markdown (authoritative)

- `title` (`# Title`)
- `description` (`# Description`)
- `priority` (`# Priority`)
- `status` (`# Status`)
- `depends_on` (`# depends_on`)

### Optional / future in markdown

- `tags` (can be added later as `# Tags` or inline format)
- `kind` (can be added later as `# Kind`)

### Derived / computed by CLI

- `id` (from filename)
- `path` (absolute/relative filesystem path)
- `link` (computed from path when building index)

## Write path (edits)

All edits update markdown only:
- `set_status` edits the `# Status` section.
- `set_priority` edits the `# Priority` section.
- (future) kind/tags edits target markdown sections if added.

Edits must be:
- validated (normalize to canonical enums)
- written via temp file + atomic `mv`
- optionally protected with a lock (mkdir-based) during writes

## Read path (rendering)

Primary:
- parse markdown → normalize → internal TSV → render

Optional optimization (cache):
- `--rebuild-index` generates:
  - `default.json` (human-ish index)
  - and/or `.bilu/storage/board.tsv` (fast runtime read)

If the cache exists, you may choose to read the TSV directly for speed, but the source of truth remains markdown.

## Index regeneration contract

Introduce (or confirm) an explicit command:
- `bilu board --rebuild-index`

Rules:
- Never rewrite indexes silently during `--list` (avoid surprises).
- Rebuild output must be deterministic (stable ordering).
- Rebuild can also perform migration/normalization (optional flag if you want strict separation):
  - `--rebuild-index` (pure rebuild, no edits to markdown)
  - `--migrate` (normalize markdown sections if you decide to offer it)

## Migration plan for existing data

Current repo inconsistency: markdown has `Status: Done` while config expects `DONE`.

With Option A:
- renderer normalizes `Done` → `DONE` at runtime (no migration required to render).
- editing operations should write canonical values (e.g. `DONE`) back to markdown.

If you want markdown to remain human-cased, document that as a rule and normalize on write accordingly (but then you must map back on persistence). The simplest approach is: write canonical enums.

## Tests to lock the policy

Add/extend tests so the policy can’t regress:
- Rendering reads markdown even if `default.json` is missing (or warn and continue).
- `--rebuild-index` produces `default.json` and/or TSV deterministically.
- Edit operations change markdown and are reflected in `--list` output.

Run tests with `NO_COLOR=1` for stable assertions.

## Acceptance checks

- Policy text is added to `.bilu/board/phases/01-data-contract.md` (or a dedicated policy doc) and referenced by the CLI docs.
- Implementation writes edits only to markdown.
- Index regeneration is explicit and documented.

## References

- `.bilu/board/tasks/01-01-source-of-truth.md`
- `.bilu/board/phases/01-data-contract.md`
- `.bilu/storage/research/shell-only-cli-advanced-notes.md`

---

## Outcomes

- Chose Option A: `.bilu/board/tasks/*.md` is authoritative; `.bilu/board/default.json` is a derived index.
- Defined precedence (markdown wins), edit targets (markdown only), and an explicit index rebuild contract (`bilu board --rebuild-index`).
- Updated `.bilu/board/phases/01-data-contract.md` to reflect this policy and the correct `.bilu/board/...` paths.

# Description
Decide and document the single source of truth for task metadata (recommended: tasks/*.md with default.json derived) and define precedence and edit targets when both sources exist.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- planning
# depends_on
