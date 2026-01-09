# Phase 04 — Render loop and frame buffer

## Goal

Implement efficient redraws in shell.

## Checklist

- [ ] Use a main loop:
  - [ ] read key
  - [ ] update state
  - [ ] render frame
- [ ] Build a full-frame string buffer and print once.
- [ ] Handle `WINCH` resize:
  - [ ] recalc layout
  - [ ] redraw
- [ ] Avoid per-cell `tput` calls; use VT100 escapes sparingly.

## Acceptance

- TUI redraw is flicker-free and responsive with 100+ tasks.
---

## Implementation plan

# Phase 04 Task Implementation Plan — Render loop and frame buffer

Task: `src/board/tasks/04-04-render-loop-and-frame-buffer.md`

This implementation plan defines the interactive TUI loop architecture: non-blocking input → state update → full-frame render, with resize handling. It follows the guidance in `src/storage/research/shell-only-cli-advanced-notes.md`: build one buffer per frame, avoid `tput` in hot loops, and handle `WINCH` with a redraw.

## Outcome (what “done” means)

1) TUI redraw is flicker-free and responsive.
2) The main loop is simple and robust (no hidden side effects).
3) Resize (`WINCH`) triggers layout recalculation and a redraw.

## Main loop contract (authoritative)

The TUI runs a single loop with three phases:

1) **Read key (non-blocking)**
- Uses `tui_read_key` (from Task 04-02).
- Returns `NONE` if no input is available.

2) **Update state**
- Applies movement/search/filter actions based on the key.
- Updates selection and scroll state (Task 04-03).

3) **Render frame**
- Builds a full frame string (header + columns + footer) and prints it once.

Pseudo-structure:

- `tui_setup_terminal`
- `trap tui_cleanup_terminal EXIT INT TERM`
- `trap tui_on_resize WINCH`
- `while :; do`
  - `key="$(tui_read_key)"`
  - `tui_handle_key "$key"`
  - `tui_render_frame`
- `done`

## Frame buffer rules (authoritative)

- Build a single string buffer per frame (e.g. `frame="$frame$line\n"`).
- Print once per frame:
  - `printf '%b' "$frame"`
- Avoid per-cell prints (reduces flicker and improves speed).

Non-negotiable:
- Do not use `tput` in the render loop.

## Screen control sequences (minimal set)

The TUI may use a small set of VT100 escapes:
- Clear + home at start of each frame:
  - `\e[H\e[2J`
Or (preferred for performance later):
- Use home + clear-to-end for partial redraws.

For v1 simplicity:
- full clear per frame is acceptable if frame rate is low (driven by keypresses).

## Resize handling (`WINCH`)

Implement:
- `tui_on_resize` handler that:
  - reads new `LINES/COLUMNS`
  - recalculates layout values (visible rows, column widths)
  - sets a flag `NEEDS_REDRAW=1`

In the main loop:
- if `NEEDS_REDRAW=1`, render a frame even if key is `NONE`.

## Layout calculation inputs

Inputs:
- terminal size (`LINES`, `COLUMNS`)
- column count (4)
- card height (TUI cards likely taller than non-interactive; define it explicitly)

Outputs:
- `col_w`, `inner_w`
- `visible_rows` (per column or global)

These should be recalculated only:
- on startup
- on resize

## Render responsibilities

### Header

Must include:
- board name
- counts (total/visible)
- active search/filter/sort summary (when present)

### Main area

- Render columns with card lists.
- Highlight selected card (visual style defined elsewhere).

### Footer/status bar

Must include:
- short help hints (`q quit`, `? help`)
- current mode/prompt state (search input, etc.)

## Blocking avoidance

The loop must not block waiting for input:
- `tui_read_key` returns `NONE` quickly
- sleep only if needed to prevent CPU spin (small `sleep 0.01`), but keep it optional

## Error handling strategy

Avoid `set -e` in the TUI loop:
- handle failures inline
- on fatal errors, print a message (stderr) and exit (cleanup runs via trap)

## Acceptance checks

- Pressing keys updates selection immediately without flicker.
- Resizing window redraws correctly and does not corrupt the terminal.
- CPU usage stays low when idle (no busy loop).

## References

- `src/board/tasks/04-04-render-loop-and-frame-buffer.md`
- `src/board/tasks/04-02-key-input-decoding.md`
- `src/board/tasks/04-03-layout-and-selection-model.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
