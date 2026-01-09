# Phase 06 — Manual TUI test script

## Goal

Provide a repeatable manual checklist for interactive TUI QA.

## Checklist

- [ ] Terminal setup/cleanup:
  - [ ] enter TUI, exit with `q`, verify terminal is restored
  - [ ] interrupt with `Ctrl-C`, verify terminal is restored
- [ ] Navigation:
  - [ ] arrows + `hjkl`
  - [ ] selection stays visible while scrolling
- [ ] Search:
  - [ ] `/` search, `n/p` next/prev match, clear search
- [ ] Filter/sort:
  - [ ] apply filter, clear filter
  - [ ] change sort key/order
- [ ] Open/edit:
  - [ ] open in `$EDITOR`, return to TUI
  - [ ] change status/priority and verify persistence
- [ ] Resize:
  - [ ] resize terminal while in TUI and verify redraw

## Acceptance

- Manual QA steps are documented and can be followed by anyone.
---

## Implementation plan

# Phase 06 Task Implementation Plan — Manual TUI test script

Task: `src/board/tasks/06-06-manual-tui-test-script.md`

This plan defines a repeatable manual QA script for the interactive TUI (`bilu board --tui`). Automated tests intentionally exclude full-screen interaction (per Phase 06), so this checklist is the authoritative way to verify terminal safety, key handling, and persistence end-to-end. It is aligned with the terminal patterns in `src/board/phases/04-interactive-tui.md` and the safety rules in `src/storage/research/shell-only-cli-advanced-notes.md` (trap cleanup, raw-ish input, framebuffer rendering, no `tput` in hot loops).

## Outcome (what “done” means)

1) Anyone can follow a step-by-step script and validate the TUI.
2) The checklist explicitly covers terminal restore on exit and on interrupts.
3) The checklist covers the core user flows: navigate, search, filter/sort, open/edit, persistence, resize.

## Preconditions (state the environment)

Before running:
- run from a repo layout or an initialized project where board data exists
- ensure `$EDITOR` is set to a known editor (for the “open/edit” tests)
- use a real terminal emulator (not a CI pseudo-tty)

Recommended:
- run once with colors enabled, once with `NO_COLOR=1` / `--no-color` (when supported)

## Manual QA script (authoritative steps)

### 1) Terminal setup/cleanup safety

1. Start TUI: `bilu board --tui`
2. Quit via `q`
3. Verify terminal restored:
   - cursor visible
   - typing echoes
   - Enter submits commands normally
4. Start TUI again and interrupt with `Ctrl-C`
5. Verify terminal restored (same checks)

If any failure:
- document exact terminal + OS
- capture what terminal state is broken (no echo, hidden cursor, stuck alt screen)

### 2) Navigation + selection visibility

In TUI:
- use arrows and `hjkl` to move selection
- verify selection highlight is always visible
- scroll (if implemented) and ensure selection remains in view
- verify boundary behavior (first/last card, first/last column)

### 3) Search

In TUI:
- press `/` to enter search
- type a substring that matches multiple tasks
- verify:
  - first match selected/highlighted
  - `n` jumps to next match
  - `p` jumps to previous match
  - clearing search restores full set (define the key, e.g. `Esc` or empty query)

### 4) Filter + sort

In TUI:
- apply a status filter (e.g. only `TODO`)
- verify board updates and counts reflect filter
- clear the filter and verify full set returns
- change sort key/order (e.g. by priority weight)
- verify ordering changes deterministically

### 5) Open + editor/pager integration

In TUI:
- select a task and press `Enter` (open)
- verify:
  - editor/pager opens the correct task file
  - after exiting editor/pager, TUI redraws correctly
  - terminal is not corrupted

Repeat with explicit “open in editor” action (e.g. `e`) if implemented.

### 6) Edit actions + persistence

In TUI:
- change status (`S` cycle) and priority (`P` cycle) for a task (if implemented)
- verify the change persists:
  - refresh in TUI (`r`) and confirm values remain
  - exit TUI and run a non-interactive list command to confirm the persisted value is visible

If locking is implemented:
- run an edit while another edit holds the lock and confirm error messaging is clear.

### 7) Resize behavior

In TUI:
- resize the terminal window smaller and larger
- verify:
  - no visual corruption (or it self-corrects after redraw)
  - layout recalculates as expected (wide/compact modes)
  - selection remains valid after resize

### 8) Error path safety

Induce a controlled error (one of):
- temporarily point to a missing board/tasks directory (if supported by env override), or
- select a task with missing file link (fixture)

Then:
- verify the TUI shows an error message (status bar) and continues, OR exits gracefully
- terminal must always be restored

## Reporting format (make QA actionable)

When reporting a failure, capture:
- OS + terminal emulator
- exact command used
- exact steps taken and key pressed
- expected vs actual
- whether terminal restore failed (yes/no)

## Acceptance checks

- The checklist above is present and can be followed end-to-end.
- Terminal restore is verified for both `q` and `Ctrl-C`.
- Core flows (nav/search/filter/open/edit/resize) are covered.

## References

- `src/board/tasks/06-06-manual-tui-test-script.md`
- `src/board/phases/04-interactive-tui.md`
- `src/board/tasks/04-01-terminal-setup-and-cleanup.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
