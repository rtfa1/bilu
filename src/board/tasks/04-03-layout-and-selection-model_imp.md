# Phase 04 Task Implementation Plan — Layout and selection model

Task: `src/board/tasks/04-03-layout-and-selection-model.md`

This implementation plan defines the TUI’s internal data model for columns/cards and the rules for selection movement and scrolling. It is designed to:
- reuse the Phase 03 column mapping rules (so kanban grouping is consistent everywhere)
- consume the normalized TSV v1 record format (so the TUI doesn’t parse markdown/JSON directly)
- feel natural (minimize “selection jumps”)

## Outcome (what “done” means)

1) The TUI represents the board as columns with card lists.
2) Selection movement (`↑/↓/←/→`, `hjkl`) behaves predictably and preserves vertical position between columns.
3) Scrolling keeps the selection visible without jarring jumps.

## Inputs and invariants

- Input: normalized TSV v1 (see `src/board/tasks/02-06-internal-record-format_imp.md`).
- Column mapping: consistent with `src/board/tasks/03-05-column-mapping-config_imp.md`.
- The TUI may filter/sort the visible list, but should preserve a stable “selected task identity” when possible.

## Data model (authoritative)

### Core objects

- `columns[]` (fixed order, v1):
  1) Backlog
  2) In Progress
  3) Review
  4) Done

Each column has:
- `title` (string)
- `statuses_set` (list/set of canonical statuses)
- `cards[]` (list of task records, already filtered/sorted)

### Card record (minimum required)

For selection and rendering, each card should carry:
- `id` (unique)
- `status`
- `priority` and `priority_weight`
- `title`
- `path`
- `tags_csv`
- `link`

### Selection state

Represent selection as indices:
- `sel_col` (0-based column index)
- `sel_row` (0-based card index within that column)

Also maintain a “stable anchor”:
- `sel_id` (selected card id)

Rule:
- `sel_id` is authoritative; indices are derived from it after filters/sorts when possible.

### Scroll state

Choose one scrolling model (v1):

Option A (recommended): per-column vertical scroll offsets
- `scroll_row[col]` (top visible card index for each column)

Rationale:
- Each column can have different lengths; per-column scroll avoids confusing jumps.

Alternative:
- single global scroll offset (harder to make feel right in multi-column boards).

## Movement rules (authoritative)

### Up/Down

- `UP`:
  - if `sel_row > 0`, decrement `sel_row`
  - else stay at 0
- `DOWN`:
  - if `sel_row < len(cards[sel_col]) - 1`, increment `sel_row`
  - else stay at last

Update `sel_id` after movement.

### Left/Right (preserve vertical position)

Goal: moving between columns should keep you on the “same row” as closely as possible.

- When moving `LEFT`/`RIGHT`:
  1) set `target_col` (clamped between 0 and last col)
  2) compute `target_row = min(sel_row, len(cards[target_col]) - 1)`
  3) set `sel_col=target_col`, `sel_row=target_row`
  4) update `sel_id`

If target column has 0 cards:
- keep `sel_row=0`
- `sel_id` becomes empty
- selection highlight stays on column header only (optional), or skip empty columns (choose one).

Recommendation:
- Do not skip empty columns automatically; it can be confusing. Instead allow selection on empty columns.

### Page navigation (optional later)

- PageUp/PageDown can move by “visible cards per column”.

## Visibility and scrolling rules

Define:
- `visible_rows` = how many card slots fit vertically for a column given terminal height and card height.

For each column:
- ensure `scroll_row[col] <= sel_row <= scroll_row[col] + visible_rows - 1`
- If selection goes above visible window:
  - set `scroll_row[col] = sel_row`
- If selection goes below visible window:
  - set `scroll_row[col] = sel_row - visible_rows + 1`

Clamp:
- `scroll_row[col]` between 0 and `max(0, len(cards[col]) - visible_rows)`

## Sorting/filtering interactions

When the visible list changes (due to search/filter/sort):

1) Try to keep selection by `sel_id`:
- find `sel_id` in the new column/card lists
- if found, update `sel_col`/`sel_row` to match

2) If `sel_id` no longer exists (filtered out):
- choose a fallback selection:
  - first card of current column if available
  - else first non-empty column (left-to-right)
  - else no selection (empty board)

Scrolling should be recomputed after selection is resolved.

## Implementation guidance (bash-friendly)

Avoid complex data structures:
- Use simple bash arrays for per-column card ids and metadata.
- Keep a mapping from `id` → (col,row) by recomputing after each filter/sort (acceptable for typical task counts).

## Acceptance checks

- Moving left/right does not “jump” unexpectedly; it lands on the nearest valid row.
- Selection stays visible while navigating up/down.
- After applying a filter/sort, selection stays on the same task if it’s still visible.

## References

- `src/board/tasks/04-03-layout-and-selection-model.md`
- `src/board/tasks/03-05-column-mapping-config_imp.md`
- `src/board/tasks/02-06-internal-record-format_imp.md`

