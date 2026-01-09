# Phase 04 Task Implementation Plan — Terminal setup and cleanup

Task: `src/docs/phases/tasks/04-01-terminal-setup-and-cleanup.md`

This implementation plan defines a safe, portable way to enter/exit full-screen TUI mode for `bilu board --tui`, without leaving the user’s terminal in a broken state. It follows `src/docs/research/shell-only-cli-advanced-notes.md` and the terminal control patterns documented in `src/docs/phases/04-interactive-tui.md`.

## Outcome (what “done” means)

1) The TUI can start and exit cleanly:
- exit via `q` returns terminal to normal
- `Ctrl-C` returns terminal to normal
- unexpected errors still restore terminal to normal
2) Terminal setup/cleanup is implemented once and reused by the TUI loop.
3) The implementation works in common terminals (macOS Terminal/iTerm2, Linux terminals).

## Scope and constraints

- This task applies to the interactive TUI only (`--tui`), implemented in `bash`.
- Non-interactive commands remain POSIX `sh` and must not emit cursor movement/alt-screen sequences.

## Terminal control contract (authoritative)

### Setup must do (in this order)

1) Save current terminal settings:
- `stty -g` into a variable (e.g. `STTY_SAVED`)
2) Switch to alternate screen buffer:
- `printf '\e[?1049h'`
3) Disable line wrapping:
- `printf '\e[?7l'`
4) Hide cursor:
- `printf '\e[?25l'`
5) Configure input mode for key reading:
- minimum: `stty -echo`
- recommended “raw-ish” (platform dependent):
  - `stty -echo -icanon time 0 min 0`
6) Clear the screen (optional):
- `printf '\e[2J\e[H'`

### Cleanup must do (in this order)

1) Restore input mode:
- `stty "$STTY_SAVED"` if available, else at least `stty echo icanon`
2) Re-enable line wrapping:
- `printf '\e[?7h'`
3) Show cursor:
- `printf '\e[?25h'`
4) Restore main screen buffer:
- `printf '\e[?1049l'`

Always run cleanup on:
- normal exit (`q`)
- `INT` (`Ctrl-C`)
- `TERM`
- script exit (`EXIT`)

## Trap strategy (must-have)

Implement:
- `trap cleanup EXIT INT TERM`

Notes:
- In bash, `EXIT` trap runs on any exit path.
- Cleanup must be idempotent (safe to run twice).

## Implementation structure

Create a dedicated TUI terminal module (bash-only), e.g.:
- `src/cli/commands/board/render/tui.sh` (bash)

Functions (suggested):
- `tui_setup_terminal`
- `tui_cleanup_terminal`

These functions should not depend on global state except `STTY_SAVED`.

## Portability notes

- Prefer VT100 escape sequences over `tput` (matches research note and avoids overhead).
- `stty` flags can vary; keep it simple and always restore from `stty -g`.
- If `stty -g` fails (rare), still attempt best-effort cleanup.

## Manual QA checklist (quick)

1) Start TUI, press `q` → terminal restored (echo works, cursor visible).
2) Start TUI, press `Ctrl-C` → terminal restored.
3) Trigger an intentional error (e.g. missing file) → terminal restored.
4) Resize terminal while in TUI (WINCH handler later) → at minimum, no terminal corruption.

## Acceptance checks

- Terminal is never left in no-echo mode after exit.
- Cursor is always visible after exit.
- Alternate screen buffer is exited after quit/error.

## References

- `src/docs/phases/tasks/04-01-terminal-setup-and-cleanup.md`
- `src/docs/phases/04-interactive-tui.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`

