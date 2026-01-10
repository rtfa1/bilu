# Phase 05 — Open task in editor

## Goal

Provide a consistent “open” action for a task card.

## Checklist

- [x] Use `$EDITOR` when set.
- [x] Fallback to `less` (if present) or `more`.
- [x] Ensure TUI returns to normal state after editor exits (restore terminal mode then re-enter).

## Acceptance

- `Enter`/`e` actions in the TUI open the correct file and return to the board UI cleanly.
---

## Implementation plan

# Phase 05 Task Implementation Plan — Open task in editor

Task: `src/board/tasks/05-03-open-task-in-editor.md`

This implementation plan provides a single, consistent “open task” action used by both the TUI and any future non-interactive commands. It matches the open behavior defined in `04-07-open-and-edit-actions.md` and ensures terminal state is restored properly when the TUI launches an editor.

## Outcome (what “done” means)

1) There is one “open” implementation that:
- uses `$EDITOR` if set
- falls back to `less` or `more`
2) The TUI can open a task and return without leaving the terminal broken.
3) The action has predictable error behavior and messaging.

## API (authoritative)

Create a POSIX `sh` action module:
- `src/cli/commands/board/actions/open.sh`

Expose a function:
- `board_open_task <path> [mode]`

Where:
- `path` is an absolute filesystem path to the task markdown file
- `mode` is optional:
  - `auto` (default): `$EDITOR` if set else pager
  - `editor`: require `$EDITOR`
  - `pager`: force pager

Exit codes:
- `0` success
- `1` runtime error (missing file, editor not found, pager not found)

## Resolution rules

### Mode: `auto`

1) If `$EDITOR` is set and non-empty:
- run: `$EDITOR "$path"`
2) Else:
- if `less` exists: `less "$path"`
- else: `more "$path"`

### Mode: `editor`

- If `$EDITOR` set: `$EDITOR "$path"`
- Else: error (exit `1`) with message: `bilu board: error: EDITOR not set`

### Mode: `pager`

- Prefer `less`, else `more`.

## Terminal mode integration (TUI)

The TUI is bash and controls the terminal state. The “open” action should not assume it is in alt-screen mode.

Recommended integration pattern:

- In the TUI:
  1) call `tui_cleanup_terminal` (restore echo/canon, show cursor, exit alt-screen)
  2) call `board_open_task "$path" <mode>`
  3) call `tui_setup_terminal`
  4) redraw

This keeps responsibilities separated:
- TUI owns terminal setup/cleanup
- action owns editor/pager selection and execution

## Error handling and messaging

On missing file:
- `bilu board: error: task file not found: <path>` (stderr), exit `1`

On missing pager:
- `bilu board: error: neither less nor more found` (stderr), exit `1`

On editor execution failure:
- bubble exit status (or normalize to `1`) and show a clear error.

## Tests (non-interactive)

Automated tests should not spawn an interactive pager/editor.

Instead, test selection logic using a fake editor:
- set `EDITOR` to a harmless command (e.g. `cat` or `true`) in a controlled environment
- call `board_open_task` and assert exit code `0`

If you keep tests shell-only and minimal, you can skip full automation and rely on the Phase 06 manual TUI checklist for interactive verification.

## Acceptance checks

- `Enter` opens file and returns to TUI with terminal intact.
- `e` opens in `$EDITOR` or shows “EDITOR not set”.
- No terminal corruption after editor exits.

## References

- `src/board/tasks/05-03-open-task-in-editor.md`
- `src/board/tasks/04-07-open-and-edit-actions.md`
- `src/board/tasks/04-01-terminal-setup-and-cleanup.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

# Description
Provide a consistent open action for tasks: use $EDITOR when set (or a pager fallback like less/more) and ensure the TUI restores terminal state before/after opening so it returns cleanly.
# Status
DONE
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
