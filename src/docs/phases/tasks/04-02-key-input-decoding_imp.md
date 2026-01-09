# Phase 04 Task Implementation Plan — Key input decoding

Task: `src/docs/phases/tasks/04-02-key-input-decoding.md`

This implementation plan defines how the bash TUI reads and decodes keys reliably (arrows + fallbacks) without blocking redraws. It follows `src/docs/research/shell-only-cli-advanced-notes.md` and the `fff`-style approach: read one byte, and if it’s ESC, read a few more bytes to decode sequences.

## Outcome (what “done” means)

1) Arrow keys and `hjkl` navigation work consistently.
2) Input reading does not block the UI loop (supports immediate redraw).
3) Escape sequence decoding is resilient across common terminals.

## Preconditions (from terminal setup)

This task depends on terminal setup (Task 04-01):
- input echo disabled
- “raw-ish” mode enabled (recommended): `stty -echo -icanon time 0 min 0`

Without `-icanon`, `read` may still wait for newline in some modes.

## Input API (authoritative)

Implement a single function in the TUI bash module:
- `tui_read_key` → prints a normalized key token to stdout, e.g.:
  - `UP`, `DOWN`, `LEFT`, `RIGHT`
  - `ENTER`, `ESC`, `BACKSPACE`
  - literal characters for single printable keys (`q`, `/`, `h`, etc.)
  - `NONE` when no key is available (non-blocking)

This keeps the main loop simple:
- `key="$(tui_read_key)"`
- `case "$key" in ... esac`

## Non-blocking read strategy (bash)

Use bash `read` with:
- `-r` raw
- `-s` silent
- `-n 1` read one byte
- `-t <small>` to avoid blocking (or rely on `stty time/min`)

Example strategy:
- primary: `read -rsn1 -t 0.05 key || key=""`
- if empty: return `NONE`

Notes:
- `-t 0` is not portable across all bash builds; small positive timeout is safer.
- When `stty time 0 min 0` is set, `read -t` may be optional; test and pick one consistent approach.

## Escape sequence decoding (authoritative)

If first byte is ESC (`$'\e'`):
- attempt to read the next two bytes quickly:
  - `read -rsn1 -t 0.001 k1 || k1=""`
  - `read -rsn1 -t 0.001 k2 || k2=""`

Then decode:
- ESC `[` `A` → `UP`
- ESC `[` `B` → `DOWN`
- ESC `[` `C` → `RIGHT`
- ESC `[` `D` → `LEFT`

Optional extended keys (later):
- Home/End often come as:
  - ESC `[` `H` / ESC `[` `F`
  - or ESC `[` `1` `~` / ESC `[` `4` `~`
- PageUp/PageDown:
  - ESC `[` `5` `~` / ESC `[` `6` `~`

For v1:
- only arrows are required; treat unknown ESC sequences as `ESC`.

## Special keys (authoritative)

Normalize these single-byte keys:
- Enter:
  - `\r` or `\n` → `ENTER`
- Backspace:
  - `\x7f` (DEL) → `BACKSPACE`

Everything else:
- return the literal character (e.g. `q`, `/`, `h`, `j`, `k`, `l`).

## Keymap integration (minimal)

Navigation should work via both:
- arrow keys (`UP/DOWN/LEFT/RIGHT`)
- `hjkl`

This ensures usability even if escape decoding fails in a weird terminal.

## Implementation location

Implement in the bash TUI module:
- `src/cli/commands/board/render/tui.sh`

Functions (suggested):
- `tui_read_key`
- `tui_decode_escape_sequence` (optional helper)

## Manual verification checklist

In macOS Terminal/iTerm2 and a Linux terminal:
- arrows move selection
- `hjkl` move selection
- `q` exits
- holding a key repeats movement smoothly (no lag spikes)

## Acceptance checks

- Arrow keys work consistently.
- UI loop continues to redraw/respond even when no key is pressed (non-blocking).
- Unknown escape sequences do not crash the TUI.

## References

- `src/docs/phases/tasks/04-02-key-input-decoding.md`
- `src/docs/phases/tasks/04-01-terminal-setup-and-cleanup_imp.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
- `src/docs/phases/04-interactive-tui.md`

