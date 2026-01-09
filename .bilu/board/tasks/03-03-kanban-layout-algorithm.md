# Phase 03 — Kanban layout algorithm (non-interactive)

## Goal

Define the rendering algorithm for a non-interactive kanban layout that adapts to terminal size.

## Checklist

- [ ] Use `stty size` to get `LINES`/`COLUMNS`.
- [ ] Choose number of columns to render based on width.
- [ ] Define column width calculation:
  - [ ] padding
  - [ ] borders
  - [ ] inter-column spacing
- [ ] Define card layout:
  - [ ] title line (with priority badge)
  - [ ] optional description preview lines
  - [ ] tags chips line (truncated)
- [ ] Define truncation/wrapping rules that avoid breaking the screen.

## Acceptance

- Kanban output is readable at common widths (80/100/120) and degrades gracefully when narrow.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Kanban layout algorithm (non-interactive)

Task: `src/board/tasks/03-03-kanban-layout-algorithm.md`

This implementation plan defines a concrete, width-aware algorithm for rendering a kanban board in the terminal without full-screen interaction. It aligns with:
- `src/board/tasks/00-04-kanban-ux-requirements.md` (card structure + degradation)
- `src/board/tasks/03-02-color-theme-and-no-color.md` (NO_COLOR rules)
- `src/storage/research/shell-only-cli-advanced-notes.md` (avoid `tput` in hot loops; build output buffers; portability)

## Outcome (what “done” means)

1) `bilu board --list --view=kanban` renders columns and cards cleanly at common widths (80/100/120).
2) The renderer adapts to terminal width using `stty size` (or a compatible fallback).
3) A narrow-terminal fallback exists (Phase 03-04 handles specifics, but algorithm must support it).
4) Output does not wrap unpredictably and avoids “escape spam”.

## Inputs

The kanban renderer consumes **normalized TSV v1** (see `02-06-internal-record-format.md`):
- `id, status, priority_weight, priority, kind, title, path, tags_csv, depends_csv, link`

## Terminal size detection

Use `stty size` (POSIX) to get `LINES` and `COLUMNS`:
- `read -r LINES COLUMNS <<EOF\n$(stty size)\nEOF`

Fallback (if `stty` fails):
- default `COLUMNS=80`, `LINES=24`

Do not call `tput` repeatedly.

## Column set and mapping

Displayed columns (v1):
- Backlog
- In Progress
- Review
- Done

Mapping from task `status` → column is defined in Phase 03-05, but the renderer should accept a mapping structure like:
- `COLUMN_BACKLOG_STATUSES="BACKLOG TODO"`
- `COLUMN_INPROGRESS_STATUSES="INPROGRESS BLOCKED"`
- `COLUMN_REVIEW_STATUSES="REVIEW"`
- `COLUMN_DONE_STATUSES="DONE ARCHIVED CANCELLED"` (or configured)

The renderer must only rely on the normalized `status` field.

## Layout algorithm (authoritative)

### Step 1: Choose mode (wide vs narrow)

Define a threshold (coordinated with Phase 03-04):
- if `COLUMNS < 80` → narrow mode (vertical blocks)
- else → wide mode (multi-column)

### Step 2: Compute column widths (wide mode)

Let:
- `N=4` columns
- `G=2` gutter spaces between columns
- `B=2` border characters per column (left/right)
- `P=2` inner padding spaces (1 left, 1 right)

Available width for columns:
- `W = COLUMNS - (G * (N - 1))`
- `col_w = floor(W / N)`

Inner text width per column:
- `inner_w = col_w - B - P`

Constraints:
- `inner_w` must be at least 20; if less, switch to narrow mode.

### Step 3: Render column headers

For each column:
- Print a header line with the column title centered/truncated to `inner_w`.
- Print a divider line (e.g. `+-----+` style per column).

### Step 4: Card layout (within a column)

Each card is rendered as a fixed-height block (v1: 4 lines) to keep the grid aligned:

1) Top border: `+` + `-` * (col_w-2) + `+`
2) Title line: `| ` + `[PRIO] Title` truncated to `inner_w` + ` |`
3) Tags line: `| ` + `#tag1 #tag2` truncated to `inner_w` + ` |` (or `-` if none)
4) Bottom border: `+` + `-` * (col_w-2) + `+`

Optional (later):
- add 1–2 description preview lines (increases card height and complexity).

### Step 5: Build the grid

Approach:
- Group tasks into arrays per column (based on status mapping).
- For each column, pre-render each card into a list of lines.
- To print the board:
  - iterate row-by-row (card index) up to max cards in any column
  - for each column:
    - print the 4 card lines if the card exists, else print 4 blank lines of `col_w` spaces
    - print gutters between columns

Performance rule:
- Build a full output buffer (string) and print once if feasible; otherwise print in large chunks, not per character.

## Truncation and wrapping rules

- Use truncation, not wrapping, inside cards to prevent accidental terminal wrapping.
- Truncate with `...` (ASCII) for portability.
- Tags formatting:
  - convert `tags_csv` into `#tag` tokens separated by spaces
  - if empty, print `-`

## Color application

- Apply color only to small tokens:
  - `[PRIO]` badge and/or status indicator
- Do not colorize border characters.
- If `NO_COLOR` / `--no-color` / non-TTY: print plain text.

## Acceptance tests (non-ANSI)

Tests should:
- run with `NO_COLOR=1`
- assert output contains column titles (`Backlog`, `In Progress`, `Review`, `Done`)
- assert it contains at least one known task title (once real task loading exists)

Avoid asserting exact spacing; prefer stable tokens.

## Acceptance checks

- Wide mode works at 80+ columns.
- Narrow mode is triggered correctly and still readable (delegated to Phase 03-04 but must be reachable).
- No unexpected wrapping in typical terminals.

## References

- `src/board/tasks/03-03-kanban-layout-algorithm.md`
- `src/board/tasks/03-04-kanban-narrow-fallback.md`
- `src/board/tasks/03-05-column-mapping-config.md`
- `src/board/tasks/00-04-kanban-ux-requirements.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/tasks/02-06-internal-record-format.md`
