# Phase 05 — Edit priority in markdown

## Goal

Implement safe priority updates by editing `src/board/tasks/*.md`.

## Checklist

- [ ] Define the exact markdown section to edit:
  - [ ] `# Priority` followed by a single-line value
- [ ] Implement update logic with temp file + atomic move.
- [ ] Handle missing `# Priority` section (insert vs error).
- [ ] Validate normalized priority before writing.

## Acceptance

- Priority edits persist safely and are reflected in list/kanban output.
---

## Implementation plan

# Phase 05 Task Implementation Plan — Edit priority in markdown

Task: `src/board/tasks/05-02-edit-priority-in-markdown.md`

This implementation plan implements safe priority updates by editing `src/board/tasks/*.md` (source of truth). It mirrors the status-edit approach (05-01) and follows the shell-only guardrails:
- validate/normalize before writing
- rewrite only the target section line
- temp file + atomic `mv`
- optional lock for concurrency

## Outcome (what “done” means)

1) A `set_priority` action exists that updates only the `# Priority` section value.
2) Writes are atomic and do not corrupt markdown files.
3) Priority values are validated and normalized to canonical enums before writing.
4) The board UI reflects the change after refresh (`--list` and TUI `r`).

## Canonical priority set

Use canonical priorities from `src/board/config.json.priorities`:
`CRITICAL|HIGH|MEDIUM|LOW|TRIVIAL`

Normalize inputs using the mapping defined in:
- `src/board/tasks/01-03-normalization-rules.md`

## API (authoritative)

Create a POSIX `sh` action module:
- `src/cli/commands/board/actions/set_priority.sh`

Expose a function:
- `board_set_priority <path> <priority>`

Behavior:
- On success: exit `0`
- On invalid priority: print error to stderr, exit `1`
- On missing file: print error to stderr, exit `1`

## Markdown edit contract

Target pattern:
- Section header: `# Priority`
- Next non-empty line after the header is the priority value line.

Update rule:
- Replace only the value line.
- Do not alter other content/spacing outside the priority line.

## Missing `# Priority` section behavior

Choose one (documented):

Option A (recommended for v1):
- If `# Priority` section missing: error (exit `1`) with a clear message.

Option B:
- Insert a `# Priority` section after `# Description` (or at end) and write value.

Recommendation:
- Start with Option A to avoid unexpected document rewrites; add insertion later once stable.

## Implementation approach (portable)

Use `awk` to rewrite the file deterministically (same pattern as status edit):

- When you see `# Priority`, set `in_priority=1`.
- The next non-empty line after `# Priority` is replaced with the new canonical priority.
- All other lines are printed unchanged.

Write to temp file then atomic move:
- `tmp="$(mktemp ...)"` with fallback
- `awk ... "$path" > "$tmp"`
- `mv "$tmp" "$path"`

## Locking (optional but recommended)

If you add locking (05-05):
- Acquire lock before writing (mkdir-based).
- Release via `trap` on exit.

## Integration points

- TUI `P` action calls `board_set_priority "$path" "$next_priority"` then refreshes.
- Non-interactive CLI can later expose a command like:
  - `bilu board --set-priority <id> <priority>` (optional)

## Tests

Add a persistence test (05-06):
- Copy a markdown task file to a temp dir.
- Call `board_set_priority` on the copy.
- Assert:
  - priority line changed
  - title still present
  - file remains readable markdown

## Acceptance checks

- Priority edit does not corrupt markdown.
- Priority is written in canonical form.
- Refresh reflects changes in UI ordering/labels.

## References

- `src/board/tasks/05-02-edit-priority-in-markdown.md`
- `src/board/tasks/05-01-edit-status-in-markdown.md`
- `src/board/tasks/01-03-normalization-rules.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

# Description
Implement safe priority updates by editing the # Priority section in task markdown, validating the normalized priority, and persisting changes via temp file + atomic mv so list/kanban output reflects edits reliably.
# Status
TODO
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
