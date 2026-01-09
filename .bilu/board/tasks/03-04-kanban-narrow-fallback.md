# Phase 03 — Narrow-terminal fallback

## Goal

Ensure `--view=kanban` remains usable on small terminals.

## Checklist

- [ ] Define “narrow” threshold (e.g. `< 80 cols`).
- [ ] Implement fallback rendering:
  - [ ] vertical blocks per column
  - [ ] one-column-at-a-time with section headers
- [ ] Ensure card borders don’t wrap unexpectedly.

## Acceptance

- Output is still readable and doesn’t spam escape sequences on narrow terminals.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Narrow-terminal fallback

Task: `src/board/tasks/03-04-kanban-narrow-fallback.md`

This implementation plan defines the fallback rendering for `--view=kanban` when the terminal is too narrow for a multi-column grid. The fallback must remain readable, avoid wrapping/border breakage, and avoid spamming escape sequences. It complements the wide-mode algorithm in `03-03-kanban-layout-algorithm.md`.

## Outcome (what “done” means)

1) When `COLUMNS` is below the threshold, `--view=kanban` switches to narrow mode automatically.
2) Narrow mode renders the board as vertical column sections with readable cards.
3) Output is stable and testable with `NO_COLOR=1`.

## Narrow threshold (authoritative)

Define narrow mode as:
- `COLUMNS < 80` → narrow mode

Also enter narrow mode if:
- the computed per-column `inner_w` in wide mode would be `< 20`

## Fallback format (authoritative)

In narrow mode, print one column at a time as vertical blocks:

### Section header

For each column:
- Print a header line:
  - `== Backlog (N) ==`
- Optionally print a blank line after header for readability.

### Card format (minimal, no borders required)

To avoid border wrapping on small widths, use a borderless format:

- `- [PRIO] Title` (single line, truncated to terminal width)
- `  tags: #tag1 #tag2` (optional; omit if none)
- `  path: <basename>` (optional; omit if too noisy)
- blank line between cards

This format:
- reads well at 60–79 columns
- avoids box-drawing / ASCII borders that can wrap unpredictably
- keeps output friendly for piping and logs

### Alternative (optional)

If you insist on “cards” even in narrow mode:
- use a single-line border style only, e.g. `-----`
- never print side borders (`|`) that can misalign on wrap

Recommendation:
- Start borderless for v1 narrow mode.

## Truncation rules (narrow mode)

- Use ASCII `...` for truncation.
- Compute max title width as:
  - `max_title = COLUMNS - len("- [PRIO] ")`
- Truncate title to `max_title`.

## Column ordering and mapping

Column order remains:
1) Backlog
2) In Progress
3) Review
4) Done

Mapping is defined in Phase 03-05.

## Color rules

Same rules as everywhere:
- `NO_COLOR` / `--no-color` / non-TTY disables color.
- If color enabled, colorize only `[PRIO]` and/or status markers (if printed).

## Implementation steps

1) In `render/kanban.sh`, detect width early:
- compute `COLUMNS` via `stty size` (fallback to 80)
- if narrow: call `board_render_kanban_narrow`, else `board_render_kanban_wide`

2) Implement `board_render_kanban_narrow`:
- group tasks per column
- print headers and cards in the borderless format above

3) Ensure the implementation does not emit escape sequences (it’s not a TUI).

## Tests

Per `03-07-renderer-tests.md`:
- Run with `NO_COLOR=1`.
- Force a narrow width deterministically for tests:
  - if your code honors `COLUMNS`, set it (recommended), else wrap `stty` usage with a test hook.

Test expectations:
- output contains `== Backlog` and other section headers
- output contains at least one known title token (once real loading exists)

## Acceptance checks

- At widths < 80, output is readable and does not break formatting.
- No “escape spam” (no cursor movement / alt screen sequences).
- Tests can exercise narrow mode deterministically.

## References

- `src/board/tasks/03-04-kanban-narrow-fallback.md`
- `src/board/tasks/03-03-kanban-layout-algorithm.md`
- `src/board/tasks/03-07-renderer-tests.md`
- `src/board/tasks/03-02-color-theme-and-no-color.md`
