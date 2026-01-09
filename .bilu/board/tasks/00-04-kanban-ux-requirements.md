# Phase 00 — Kanban UX requirements

## Goal

Define what the “beautiful” output looks like and which keyboard interactions are in scope.

## Non-interactive requirements

- [x] Table view is readable and aligned.
- [x] Kanban view renders columns and cards with borders and colors.
- [x] Output degrades gracefully for narrow terminals.

## Interactive (`--tui`) requirements

- [x] Navigation: arrows + `hjkl`
- [x] Search: `/` to search, `n/p` to navigate matches
- [x] Filter: choose field/value
- [x] Sort: choose sort key + order
- [x] Open/edit: `Enter` opens task, `e` opens in `$EDITOR`
- [x] Minimal edits: change status/priority and persist safely

## Visual design requirements

- [x] Consistent color theme for status + priority.
- [x] Highlight selected card.
- [x] Header with counts; footer status bar with active filter/search/sort.
- [x] `NO_COLOR` and `--no-color` support.

## Acceptance

- A stable keymap and visual spec for the initial release.
---

## Implementation plan

# Phase 00 Task Implementation Plan — Kanban UX requirements

Task: `.bilu/board/tasks/00-04-kanban-ux-requirements.md`

This implementation plan defines a concrete UX spec for both non-interactive output and the interactive TUI, aligned with the project constraints and the terminal/TUI guidance in `.bilu/storage/research/shell-only-cli-advanced-notes.md`.

## Outcome (what “done” means)

1) A stable UX spec exists that implementation can follow without ambiguity:
- visual design rules (cards, columns, colors)
- a stable keymap for `--tui`
- non-interactive behavior for `--list` table and kanban modes
2) The spec includes accessibility/testability requirements:
- `NO_COLOR` and `--no-color`
- stable output modes for tests
3) The spec explicitly defines graceful degradation on small terminals.

## UX scope (what is in the initial release)

### Non-interactive

- `bilu board --list` (table)
- `bilu board --list --view=kanban` (printed kanban)
- Filtering/search/sort as flags (no interactive prompts here)

### Interactive (`--tui`)

- Full-screen kanban view with keyboard navigation
- Search, filter, sort
- Open in editor/pager
- Minimal edits (status/priority) with safe persistence

## Visual spec (non-interactive)

### Table view (`--view=table`, default)

- One task per line.
- Fixed columns (suggested):
  - `STATUS` `PRIO` `TITLE` `TAGS` `PATH`
- Truncation:
  - `TITLE` truncates with `...` when needed (avoid Unicode for portability).
  - `TAGS` truncates after N chars.
- Header line:
  - include counts and any active filter/search (optional but recommended).

### Kanban view (`--view=kanban`)

- Columns: Backlog / In Progress / Review / Done (mapping defined in Phase 03).
- Cards:
  - Border uses ASCII only (portable, test-friendly), choose one and stick to it.
  - Line 1: `[PRIO] Title` (with status color or priority badge)
  - Line 2–3: short description preview (optional; can be toggled later)
  - Last line: tags chips (e.g. `#frontend #planning`)
- Layout:
  - Use terminal width (`$COLUMNS` if set, else `stty size`) to compute column width.
  - When narrow:
    - fallback to vertical column blocks (one column at a time).

## Color + accessibility spec

Follow the research note recommendations:

- If `NO_COLOR` is set and non-empty: disable color by default.
- Add `--no-color` to always disable.
- Auto-disable color when stdout is not a TTY (`[ -t 1 ]` is false).

Define a theme (initial proposal):
- Status:
  - `TODO`: yellow
  - `INPROGRESS`: blue
  - `BLOCKED`: red
  - `REVIEW`: magenta
  - `DONE`: green
  - `CANCELLED`: dim
  - `ARCHIVED`: dim
- Priority:
  - `CRITICAL`: red + bold (if supported)
  - `HIGH`: red/yellow
  - `MEDIUM`: yellow
  - `LOW`: cyan/blue
  - `TRIVIAL`: dim

## Interactive TUI UX spec

### Terminal control (must-have)

Per `shell-only-cli-advanced-notes.md` (and common bash TUIs like `fff`):
- Alternate screen buffer on/off.
- Hide cursor.
- Disable wrap.
- Disable echo and enable raw-ish input (platform-tolerant).
- Always restore terminal via `trap` on exit/error.
- Handle `WINCH` resize.

### Keymap (stable for v1)

Navigation:
- `↑/↓/←/→` and `hjkl`

Search:
- `/` start search prompt
- `n` next match
- `p` previous match
- `c` clear search (or a general “clear filters/search”)

Filter/Sort:
- `f` filter prompt (field + value)
- `s` sort prompt (key + order)

Open/Edit:
- `Enter` open selected task (editor if `$EDITOR`, else pager)
- `e` open in `$EDITOR` explicitly
- `S` cycle status (persist)
- `P` cycle priority (persist)

General:
- `?` help overlay (keymap + hints)
- `r` refresh from disk
- `q` quit

### UI layout

- Header:
  - board name
  - total vs visible counts
  - active view name
- Main:
  - columns and cards; selected card highlighted (inverse or border emphasis)
- Footer/status bar:
  - active filter/search/sort
  - short hints (`q quit`, `? help`)

### Degradation rules

- If terminal is too small:
  - show a centered message: “Terminal too small (WxH). Resize to continue.”
  - keep `q` working.

## Implementation steps (how to realize this spec)

1) Write the theme constants in one place (planned module):
   - `src/cli/commands/board/ui/ansi.sh`
2) Write renderer contracts:
   - table renderer prints stable columns; can be tested with `NO_COLOR=1`
   - kanban renderer uses width calc + fallback
3) TUI module:
   - a self-contained `bash` file for input decoding + framebuffer rendering
   - no `tput` in hot loops
4) Add a manual QA checklist (Phase 06 already has a task for this).

## Acceptance checks

- Non-interactive:
  - Table output is aligned and readable at 80 cols.
  - Kanban output renders cards/columns and falls back on narrow width.
- Interactive:
  - Keymap works as specified.
  - Terminal always restores on exit/error.
- Accessibility:
  - `NO_COLOR` and `--no-color` disable ANSI.
  - Non-TTY output emits no ANSI by default.

## References

- `.bilu/board/tasks/00-04-kanban-ux-requirements.md`
- `.bilu/storage/research/shell-only-cli-advanced-notes.md`

---

## Outcomes (2026-01-09)

- Finalized a v1 keymap and visual spec for table + printed kanban output, including narrow-terminal degradation rules.
- Locked initial color/NO_COLOR behavior and a portable (ASCII-only) rendering rule for testability.
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/phases/03-rendering-table-and-kanban.md`
- `src/board/phases/04-interactive-tui.md`

# Description
Define the UX/spec for non-interactive table+kanban output and the interactive --tui keymap (nav/search/filter/sort/open/edit), including visual requirements like colors, selected card highlight, header/footer, and NO_COLOR support.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- design
- devops
- frontend
- planning
- usability
# depends_on
