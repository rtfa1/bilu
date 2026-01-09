# Phase 4 — Interactive TUI (keyboard)

Implement a full-screen kanban UI with search/filter/sort and light editing.

## Shell constraints

Interactive keystroke handling is significantly easier in `bash` than POSIX `sh`.

Recommendation:
- Keep non-interactive commands in POSIX `sh`.
- Implement `--tui` in `bash` (still “only shell”).

## Terminal control (patterns)

Use proven techniques (e.g. as seen in `fff`):
- Alternate screen buffer: `\e[?1049h` / `\e[?1049l`
- Hide/show cursor: `\e[?25l` / `\e[?25h`
- Disable wrap: `\e[?7l` / `\e[?7h`
- Disable echo: `stty -echo`
- Always restore on exit: `trap cleanup EXIT INT TERM`
- Handle resize: `trap on_resize WINCH`

## Keybindings (initial)

- Navigation: arrows or `hjkl`
- `q`: quit
- `?`: help overlay
- `/`: search prompt; `n` next match; `p` previous match
- `f`: filter prompt (status/priority/tag/kind)
- `s`: sort prompt
- `Enter`: open task (`$EDITOR` or pager)
- `S`: cycle status and persist
- `P`: cycle priority and persist
- `r`: refresh from disk

## UI layout

- Header: board name + counts + active mode.
- Main: columns with cards; selected card highlighted.
- Footer: status bar showing filter/search/sort and short help.

## Performance rule

Avoid calling `tput` repeatedly. Prefer constructing a full frame string and printing once per redraw.

## Phase 04 tasks

See `src/board/tasks/` for Phase 04 tasks.
