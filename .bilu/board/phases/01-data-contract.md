# Phase 1 — Data contract

This phase makes the board data predictable and safe to render/edit.

## Sources

- Index (derived): `.bilu/board/default.json`
- Detail/source: `.bilu/board/tasks/*.md`
- Schema/config: `.bilu/board/config.json`

## Source of truth (choose one)

Pick one and enforce it in code and docs.

**Policy (chosen):** Task metadata is sourced from `.bilu/board/tasks/*.md`. The board index (`.bilu/board/default.json`) is derived and may be regenerated at any time. All edits performed by the CLI write to task markdown files; index regeneration is explicit via a rebuild command. Renderers operate on normalized records produced from markdown.

### Option A (recommended)
`tasks/*.md` is the source of truth. `default.json` is derived (generated/indexed).

Pros:
- Editing is simple (plain markdown).
- Git diffs are readable.

Cons:
- Need a small “index rebuild” command.

### Option B
`default.json` is the source of truth. `tasks/*.md` is detail-only.

Pros:
- Fast to read and render.

Cons:
- Editing JSON in shell is more fragile.

## Normalized task record (internal)

All renderers operate on a normalized internal record:

- `id`: derived from filename (e.g. `01-project-scaffold-and-manifest`)
- `title`
- `description` (optional)
- `status`: one of `BACKLOG|TODO|INPROGRESS|BLOCKED|REVIEW|DONE|ARCHIVED|CANCELLED`
- `priority`: one of `CRITICAL|HIGH|MEDIUM|LOW|TRIVIAL`
- `kind`: one of `task|bug|feature|improvement` (or a configurable set)
- `tags[]`
- `depends_on[]`
- `path`: filesystem path to markdown detail
- `link`: link field if present

## Normalization rules (must-have)

- **Status**
  - Accept common variants (`Done`, `done`, `in-progress`, etc)
  - Normalize to the canonical values from `config.json`
- **Priority**
  - Case-insensitive mapping (`High`, `HIGH`, `high` → `HIGH`)
- **Kind**
  - If missing, map legacy keys in `default.json` (`bug`, `improvement`) to `kind`
- **Missing/invalid values**
  - Never crash: emit warnings to stderr and fall back to safe defaults (`TODO`, `MEDIUM`, etc)

## Validation behavior

Provide `bilu board --validate`:

- Validate `config.json` keys exist and are consistent.
- Validate each task can be normalized.
- Validate `depends_on` targets (warn if missing).

## Phase 01 tasks

See `.bilu/board/tasks/` for Phase 01 tasks.
