# Phase 04 — Open and edit actions

## Goal

Let users open a card and perform minimal edits from the TUI.

## Checklist

- [ ] `Enter` opens selected task:
  - [ ] `$EDITOR` if set, else `less`/`more`
- [ ] `e` opens in `$EDITOR`.
- [ ] `S` cycles status and persists.
- [ ] `P` cycles priority and persists.
- [ ] `r` refresh from disk.

## Acceptance

- Editing updates the underlying file safely and the UI refreshes to reflect changes.
---

## Implementation plan

# Phase 04 Task Implementation Plan — Open and edit actions

Task: `src/board/tasks/04-07-open-and-edit-actions.md`

This implementation plan defines how the TUI opens tasks and performs minimal edits (status/priority) safely, then refreshes the UI. It aligns with the shell-only guardrails (atomic writes, optional locking) and defers the actual markdown-edit implementations to Phase 05 tasks.

## Outcome (what “done” means)

1) `Enter` opens the selected task (editor/pager) and returns to the TUI cleanly.
2) `e` opens in `$EDITOR` explicitly.
3) `S` cycles status and persists safely.
4) `P` cycles priority and persists safely.
5) `r` refreshes from disk and keeps selection stable when possible.

## Preconditions

- Terminal setup/cleanup is reliable (Task 04-01).
- Key decoding works (`ENTER`, `e`, `S`, `P`, `r`) (Task 04-02).
- Selection has a stable `sel_id` + `path` for the selected card (Task 04-03).

## Open behavior (authoritative)

### `Enter`: open selected task

Resolution:
- If `sel_id` is empty (no selection), do nothing.
- Else open the task file at `path`:
  - If `$EDITOR` is set: run `$EDITOR "$path"`.
  - Else if `less` exists: run `less "$path"`.
  - Else: run `more "$path"`.

Terminal safety:
- Before launching editor/pager:
  - temporarily restore terminal mode (echo/canon, cursor visible, main buffer optional)
  - ensure cleanup is not triggered prematurely
- After editor exits:
  - re-enter TUI mode (setup again)
  - redraw

Simplest v1 approach:
- call `tui_cleanup_terminal` before execing editor
- after editor exits, call `tui_setup_terminal` and continue loop

### `e`: open in editor

Same as Enter, but:
- if `$EDITOR` is not set, show a status bar message: “EDITOR not set”.

## Edit behavior (authoritative)

All edits must write to markdown (source of truth) and must be safe:
- temp file + atomic `mv`
- optional lock to prevent concurrent edits

### `S`: cycle status

Cycle through a canonical list (v1):
- `TODO` → `INPROGRESS` → `REVIEW` → `DONE` → `TODO`

Notes:
- This cycle list is *UI-focused* (not all statuses).
- `BLOCKED` can be a separate toggle later (e.g. key `B`).

Implementation:
- read current normalized `status` for selected card
- compute next status
- call a shared action function:
  - `set_status "$path" "$next_status"`
- refresh view and keep `sel_id` selected

### `P`: cycle priority

Cycle through canonical priorities (v1):
- `TRIVIAL` → `LOW` → `MEDIUM` → `HIGH` → `CRITICAL` → `TRIVIAL`

Implementation:
- read current normalized priority for selected card
- compute next priority
- call:
  - `set_priority "$path" "$next_priority"`
- refresh view and keep selection stable

### `r`: refresh from disk

- Reload tasks from source of truth.
- Reapply active search/filter/sort.
- Keep `sel_id` selected if still present.

## Error handling and messaging

On edit failures:
- Do not crash the TUI.
- Show an error message in the status bar for a few frames, e.g.:
  - `error: failed to update status (see stderr)`

On missing file:
- Show message: `error: task file missing: <path>`

## Integration points (Phase 05)

The TUI should call action modules rather than implementing file edits directly:
- `actions/open.sh`
- `actions/set_status.sh`
- `actions/set_priority.sh`

Those action modules implement:
- section replacement in markdown
- normalization validation before writing
- locking (optional but recommended)

## Manual QA checklist

- Enter opens a task and returns to TUI with terminal intact.
- `e` respects `$EDITOR`.
- `S` changes status and the card moves columns after refresh.
- `P` changes priority and the badge updates after refresh.
- `r` reloads changes made externally.

## Acceptance checks

- Edits persist safely and are reflected in the UI immediately after refresh.
- TUI never leaves the terminal in a broken state after opening an editor.

## References

- `src/board/tasks/04-07-open-and-edit-actions.md`
- `src/board/tasks/05-01-edit-status-in-markdown.md`
- `src/board/tasks/05-02-edit-priority-in-markdown.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
