# Phase 04 Task Implementation Plan — Help overlay and status bar

Task: `src/docs/phases/tasks/04-08-help-overlay-and-status-bar.md`

This implementation plan makes the TUI discoverable via a help overlay (`?`) and ensures the status bar always communicates current state (search/filter/sort, counts, hints, and transient errors). It integrates with the UX plans for key decoding, search, filter/sort, and edit actions.

## Outcome (what “done” means)

1) `?` toggles a help overlay showing keybindings and short descriptions.
2) The status bar shows:
- counts (total/visible, and optionally per-column)
- active search query and match count
- active filter and sort summary
- hints (`q quit`, `? help`, `/ search`, etc.)
3) Overlay and status bar render correctly on small terminals (no corruption, truncation is graceful).

## Help overlay spec (authoritative)

### Toggle behavior

- `?` toggles `help_visible` (0/1).
- When `help_visible=1`:
  - the main area is replaced (or dimmed) by a help panel
  - navigation keys can be ignored or still work (choose one; v1 recommended: ignore navigation)
- `?` or `ESC` closes the overlay.

### Content (v1)

Display a compact keymap grouped by feature:

Navigation:
- `↑/↓/←/→` / `hjkl` — move selection

Search:
- `/` — search
- `n` / `p` — next/prev match
- `c` — clear search/filter

Filter/Sort:
- `f` — filter
- `s` — sort

Open/Edit:
- `Enter` — open task
- `e` — open in `$EDITOR`
- `S` — cycle status
- `P` — cycle priority
- `r` — refresh

General:
- `q` — quit
- `?` — toggle help

### Layout rules

- Overlay must fit within terminal bounds:
  - if too small, show a minimal message:
    - `Terminal too small for help. Resize.`
- Overlay text must be truncated with `...` rather than wrapping unpredictably.

## Status bar spec (authoritative)

### Always-visible information (v1)

Status bar should include:
- `Visible: <visible>/<total>`
- `Search: "<q>"` when active (or `Search: -` when empty)
- `Filter: <field>=<value>` when active (or `Filter: -`)
- `Sort: <key> <order>` (or `Sort: -` until implemented)
- Hints: `q quit  ? help`

Example:
`Visible: 7/12  Search: "contract" (2/5)  Filter: status=TODO  Sort: priority desc  q quit  ? help`

### Transient messages

Maintain:
- `status_msg` (string)
- `status_msg_ttl` (frames or milliseconds)

Use it for:
- errors (missing file, edit failure)
- confirmations (status updated)

Rendering rule:
- If `status_msg_ttl > 0`, show `status_msg` at the start of the status bar (truncated).

## Interaction with other features

- Search (04-05):
  - status bar shows query + match counts
- Filter/sort (04-06):
  - status bar shows filter/sort state
- Open/edit actions (04-07):
  - show transient success/error messages

## Implementation guidance (bash TUI)

### State variables

- `help_visible=0|1`
- `status_msg=""`
- `status_msg_ttl=0`

### Rendering

In the frame renderer (04-04):
- If `help_visible=1`, render help overlay panel instead of columns.
- Always render status bar as the last line.

Avoid cursor movement; keep “full-frame redraw” strategy.

## Acceptance checks

- Pressing `?` shows help overlay; pressing `?` again hides it.
- Status bar always shows counts and hints.
- Search/filter/sort state appears in status bar when active.
- Transient error messages show and disappear after TTL.
- Small terminal sizes degrade gracefully (help overlay shows minimal message).

## References

- `src/docs/phases/tasks/04-08-help-overlay-and-status-bar.md`
- `src/docs/phases/tasks/04-02-key-input-decoding_imp.md`
- `src/docs/phases/tasks/04-05-search-ui_imp.md`
- `src/docs/phases/tasks/04-06-filter-and-sort-ui_imp.md`
- `src/docs/phases/tasks/04-07-open-and-edit-actions_imp.md`

