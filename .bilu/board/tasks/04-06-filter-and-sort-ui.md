# Phase 04 — Filter and sort UI

## Goal

Add interactive filtering and sorting without external dependencies.

## Checklist

- [ ] `f` opens filter prompt:
  - [ ] choose field: `status|priority|tag|kind`
  - [ ] choose value
- [ ] `s` opens sort prompt:
  - [ ] choose key and order
- [ ] Show active filter/sort in status bar.
- [ ] Provide a way to clear filters/search quickly (e.g. `c`).

## Acceptance

- Filtering and sorting update the view correctly and remain reversible.
---

## Implementation plan

# Phase 04 Task Implementation Plan — Filter and sort UI

Task: `src/board/tasks/04-06-filter-and-sort-ui.md`

This implementation plan defines an interactive filter and sort UX for the TUI without external dependencies. It integrates with:
- search state (Task 04-05)
- selection anchoring (`sel_id`) and column/card model (Task 04-03)
- normalized TSV v1 fields (Task 02-06)

## Outcome (what “done” means)

1) `f` opens an interactive filter prompt for `status|priority|tag|kind`.
2) `s` opens an interactive sort prompt (key + order).
3) Filter/sort changes are reversible and reflected in the status bar.
4) `c` clears search and filters quickly.

## State model (authoritative)

Maintain:
- `filter_active` (0/1)
- `filter_field` (one of `status|priority|tag|kind`)
- `filter_value` (string)
- `sort_key` (one of `status|priority|title`) (v1)
- `sort_order` (`asc|desc`) (v1)

Selection anchor:
- `sel_id` remains authoritative (from 04-03).

## Filter UX (authoritative)

### Enter filter mode

- Key `f` enters filter prompt mode.
- Prompt is 2-step for simplicity:
  1) choose field
  2) choose value

### Step 1: choose field

Display in footer:
- `Filter field (status/priority/tag/kind): `

Accepted inputs:
- `s` → `status`
- `p` → `priority`
- `t` → `tag`
- `k` → `kind`
- `ESC` cancels

### Step 2: choose value

Display in footer:
- `Filter <field>: `

Accepted inputs:
- free-text input + `ENTER` to commit
- `ESC` cancels

Normalization:
- `status` and `priority` values are normalized using the same rules as non-interactive mode (canonical enums).
- `tag` and `kind` are treated case-insensitively for matching.

### Commit behavior

On commit:
- set `filter_active=1`, store `filter_field`/`filter_value`
- recompute visible cards:
  - apply filter AND search (if active)
  - apply sort
- selection:
  - keep `sel_id` if still visible
  - else select first visible card in current column, else first non-empty column

## Filter matching rules (v1)

- `status`: exact match after normalization
- `priority`: exact match after normalization
- `kind`: exact match (case-insensitive)
- `tag`: membership in `tags_csv` (case-insensitive contains on comma-separated list)

## Sort UX (authoritative)

### Enter sort mode

- Key `s` enters sort prompt mode.
- 2-step prompt:
  1) choose sort key
  2) choose order

### Step 1: choose sort key

Footer prompt:
- `Sort key (priority/title/status): `

Accepted inputs:
- `p` → `priority` (uses numeric `priority_weight` primarily)
- `t` → `title`
- `s` → `status` (uses status ordering from config if available; else lexical)
- `ESC` cancels

### Step 2: choose order

Footer prompt:
- `Order (asc/desc): `

Accepted inputs:
- `a` → asc
- `d` → desc
- `ESC` cancels

### Commit behavior

On commit:
- set `sort_key`, `sort_order`
- recompute visible cards (filter/search applied first, then sort)
- keep `sel_id` if still visible; otherwise pick fallback selection

## Clear behavior (quick reset)

Key `c` clears:
- `search_query` (Task 04-05)
- `filter_active` and filter state

Optional:
- keep sort state (so users can clear filters without losing sort)
OR clear everything including sort (choose one and document).

Recommendation:
- `c` clears search + filters, keeps sort.

## Status bar integration

Status bar must show:
- active search query (if any)
- active filter (e.g. `Filter: status=TODO`)
- sort state (e.g. `Sort: priority desc`)
- counts (total/visible)
- hints (`q quit`, `? help`)

## Performance rules

- Recompute filter/sort on `ENTER` commit, not on every keystroke (v1).
- Avoid expensive parsing in the TUI loop:
  - keep TSV fields in arrays/maps prepared once per refresh
  - apply filter/sort by operating on ids and cached fields

## Acceptance checks

- `f` + field/value applies filter and updates visible list.
- `s` + key/order applies sort and updates visible list.
- `c` clears search + filters quickly.
- Status bar reflects active filter/sort and counts.

## References

- `src/board/tasks/04-06-filter-and-sort-ui.md`
- `src/board/tasks/04-05-search-ui.md`
- `src/board/tasks/04-03-layout-and-selection-model.md`
- `src/board/tasks/04-08-help-overlay-and-status-bar.md`
- `src/board/tasks/02-06-internal-record-format.md`

# Description
Add interactive filtering and sorting in the TUI: f opens a field/value filter prompt (status/priority/tag/kind), s opens sort prompt, status bar shows active modes, and a quick clear action resets filter/search/sort.
# Status
TODO
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
