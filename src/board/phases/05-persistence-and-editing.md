# Phase 5 — Persistence and editing

This phase defines how user actions change the underlying files safely.

## Safe edit strategy (shell)

- Never edit files in-place with partial writes.
- Write to a temp file and atomic `mv` into place.
- Keep edits scoped to known sections.

## Recommended persistence target

Persist edits to `src/board/tasks/*.md`:
- Update `# Status` section value
- Update `# Priority` section value

## Index regeneration (optional but useful)

If `default.json` is treated as a derived index:
- Provide `bilu board --rebuild-index`
  - Read all task markdown
  - Emit normalized JSON list
  - Preserve stable ordering

## Conflict rules

If both md and json provide values, define precedence clearly (see `01-data-contract.md`) and document it in `bilu board --help`.

## Phase 05 tasks

See `src/board/tasks/` for Phase 05 tasks.
