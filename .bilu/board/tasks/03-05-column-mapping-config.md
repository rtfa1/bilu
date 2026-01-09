# Phase 03 — Column mapping and configuration

## Goal

Define how statuses map into displayed columns and how to configure it.

## Checklist

- [ ] Define default mapping (Backlog/In Progress/Review/Done).
- [ ] Decide whether mapping is:
  - [ ] hard-coded initially, or
  - [ ] read from `src/board/config.json` (recommended later)
- [ ] Decide how to treat:
  - [ ] `ARCHIVED`
  - [ ] `CANCELLED`
  - [ ] `showCompletedTasks` config

## Acceptance

- A clear mapping is documented and consistent across renderers.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Column mapping and configuration

Task: `src/board/tasks/03-05-column-mapping-config.md`

This implementation plan defines a single, documented mapping from task statuses to displayed kanban columns, including how `ARCHIVED`, `CANCELLED`, and `showCompletedTasks` are handled. The mapping must be shared by all renderers (non-interactive kanban and later the TUI) so users see consistent grouping.

## Outcome (what “done” means)

1) A default mapping is defined and documented.
2) The mapping is implemented in one place and reused everywhere.
3) The treatment of `ARCHIVED` and `CANCELLED` is explicit and configurable.
4) The mapping integrates with `src/board/config.json.ui.showCompletedTasks`.

## Default column set (v1)

Use the 4 columns already present in `src/board/config.json.ui.columns`:
- `Backlog`
- `In Progress`
- `Review`
- `Done`

## Default status → column mapping (authoritative)

Using canonical statuses from `src/board/config.json.statuses`:

- **Backlog**:
  - `BACKLOG`
  - `TODO`
- **In Progress**:
  - `INPROGRESS`
  - `BLOCKED`
- **Review**:
  - `REVIEW`
- **Done**:
  - `DONE`
  - plus optionally: `ARCHIVED`, `CANCELLED` (see below)

Rationale:
- Users usually want to see blocked work near in-progress.
- Review is a distinct stage.
- Archived/cancelled are “done-ish” but often hidden.

## Completed tasks visibility (`showCompletedTasks`)

### Default behavior

If `ui.showCompletedTasks` is `true`:
- include `DONE` in the Done column

If `ui.showCompletedTasks` is `false`:
- hide `DONE` tasks from the kanban view (but keep them accessible via table view or an explicit flag later)

Note:
- Hiding done tasks can make kanban more focused.
- If you hide `DONE`, consider printing a small summary count in the header (optional).

## Treatment of `ARCHIVED` and `CANCELLED`

Define separate visibility toggles (v1 can be hard-coded, but must be documented):

Option A (recommended):
- Always hide `ARCHIVED` and `CANCELLED` by default.
- Add flags later:
  - `--show-archived`
  - `--show-cancelled`

Option B:
- Treat `ARCHIVED` and `CANCELLED` as “completed” and follow `showCompletedTasks`.

Recommendation:
- Start with **Option A** to avoid clutter in v1.

If you keep Option A:
- `ARCHIVED` and `CANCELLED` are excluded from kanban unless explicitly requested.

## Configuration source (hard-coded vs config-driven)

### v1 approach (pragmatic)

Hard-code the mapping in code (single source of truth) to avoid runtime JSON parsing complexity.

Where to implement:
- `src/cli/commands/board/ui/layout.sh` or a dedicated `columns.sh` module that exports:
  - `COLUMN_TITLES`
  - `COLUMN_*_STATUSES` sets
  - visibility flags

### Later (config-driven)

Once you have a safe parsing/compilation strategy:
- read mapping from `src/board/config.json` or a compiled config TSV generated at `--rebuild-index`.

## Implementation steps

1) Define mapping constants in one module:
- `COLUMN_BACKLOG_STATUSES="BACKLOG TODO"`
- `COLUMN_INPROGRESS_STATUSES="INPROGRESS BLOCKED"`
- `COLUMN_REVIEW_STATUSES="REVIEW"`
- `COLUMN_DONE_STATUSES="DONE"`
- `HIDE_ARCHIVED_DEFAULT=1`
- `HIDE_CANCELLED_DEFAULT=1`

2) Ensure renderers use mapping constants (no duplicate mapping logic).

3) Integrate `showCompletedTasks`:
- decide how to read it:
  - compile config into a simple KV file during rebuild, or
  - schema-extract only that boolean, or
  - treat it as a renderer flag for v1 (documented default)

## Tests

Add a test fixture (later, once real listing is implemented):
- a TSV list containing each status
- assert grouping goes to expected column headers

Run tests with `NO_COLOR=1`.

## Acceptance checks

- Mapping is documented and consistent across all kanban renderers.
- `ARCHIVED`/`CANCELLED` behavior is not ambiguous.
- The `showCompletedTasks` interaction is explicit (even if config-driven reading is deferred).

## References

- `src/board/tasks/03-05-column-mapping-config.md`
- `src/board/config.json`
- `src/board/phases/03-rendering-table-and-kanban.md`
- `src/board/tasks/03-03-kanban-layout-algorithm.md`

# Description
Define how status values map into displayed kanban columns (default Backlog/In Progress/Review/Done), whether mapping is hard-coded or read from config.json, and how to treat ARCHIVED/CANCELLED and showCompletedTasks.
# Status
TODO
# Priority
MEDIUM
# Kind
task
# Tags
- planning
# depends_on
