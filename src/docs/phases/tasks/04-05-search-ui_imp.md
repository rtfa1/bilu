# Phase 04 Task Implementation Plan — Search UI

Task: `src/docs/phases/tasks/04-05-search-ui.md`

This implementation plan specifies the interactive `/` search UX for the TUI and how it interacts with selection, filtering, and rendering. It is designed to keep the UI responsive and avoid selection “jumps” by using the `sel_id` anchor described in `04-03-layout-and-selection-model_imp.md`.

## Outcome (what “done” means)

1) `/` opens a search prompt and accepts a query.
2) The visible card list is filtered by the query (title + optional description preview).
3) `n`/`p` moves between matches predictably.
4) The status bar shows the active search query and match counts.

## Search scope (what is searched)

For v1, search matches against:
- `title` (required)
- optional: a short description preview if available in TSV or precomputed metadata

Recommendation:
- Start with title-only search if descriptions are not in TSV yet.
- Add description search later once a safe preview field exists (avoid multi-line parsing in the TUI loop).

## Search state model (authoritative)

Maintain:
- `search_active` (0/1)
- `search_query` (string)
- `search_matches` (list of matching `id`s in display order)
- `search_index` (current match index in `search_matches`)

Selection anchor:
- `sel_id` remains authoritative (from 04-03).

## Prompt UX (authoritative)

### Enter search mode

- Key `/` enters search prompt mode.
- Footer shows: `Search: <current input>`
- While in prompt mode:
  - printable characters append to input
  - `BACKSPACE` deletes one char
  - `ESC` cancels prompt (restore previous search state)
  - `ENTER` commits query

### Commit behavior

On `ENTER`:
- set `search_query` to the entered text
- recompute visible card lists using the query
- recompute `search_matches` in the new visible order
- update selection:
  - if current `sel_id` is still visible, keep it
  - else move to the first match (if any)

### Clear behavior

Provide `c` (or another key) to clear search:
- `search_query=""`
- visible list returns to “no search filter”
- `search_matches` cleared

## Matching rules

For v1:
- case-insensitive substring match:
  - normalize both sides to lowercase
- match if query is empty:
  - treat as “no search filter”

Do not use regex matching for v1 (reduces surprises and complexity).

## `n`/`p` navigation rules

If `search_matches` is non-empty:
- `n`: move to next match (wrap-around)
- `p`: move to previous match (wrap-around)

Behavior:
- set `sel_id` to the match `id`
- derive `sel_col`/`sel_row` by locating the id in current column lists (recompute mapping if needed)
- ensure scroll offsets update to keep selection visible

If no matches:
- `n`/`p` do nothing, but status bar can show `0 matches`.

## Rendering requirements

### Status bar

Always show:
- `Search: <query>` when query non-empty
- `Matches: <k>/<n>` when matches exist

Example:
- `Search: "contract"  Match: 2/5  Filter: status=TODO  Sort: priority desc`

### Optional highlight (later)

For v1, do not highlight matched substrings (keeps rendering simple).
If you add it later:
- only highlight in title line
- ensure it doesn’t break alignment/width calculations

## Performance rules

- Recompute matches on `ENTER` (commit), not on every keystroke (v1).
  - This avoids expensive re-filtering in tight loops.
- If you want “live search” later, add it behind a flag and ensure performance is acceptable.

## Acceptance checks

- `/` enters prompt, typing works, `ENTER` applies search.
- `ESC` cancels without changing the previous state.
- `n`/`p` cycles through matches without selection jumps.
- Status bar shows query and match counts.

## References

- `src/docs/phases/tasks/04-05-search-ui.md`
- `src/docs/phases/tasks/04-03-layout-and-selection-model_imp.md`
- `src/docs/phases/tasks/04-08-help-overlay-and-status-bar.md`

