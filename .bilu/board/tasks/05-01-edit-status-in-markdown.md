# Phase 05 — Edit status in markdown

## Goal

Implement safe status updates by editing `src/board/tasks/*.md`.

## Checklist

- [ ] Define the exact markdown section to edit:
  - [ ] `# Status` followed by a single-line value
- [ ] Implement an update function that:
  - [ ] reads file
  - [ ] replaces the status value only
  - [ ] writes to a temp file
  - [ ] atomic `mv` into place
- [ ] Handle missing `# Status` section:
  - [ ] decide whether to insert it or error out
- [ ] Validate normalized status before writing.

## Acceptance

- `bilu board` can change a task status and the file remains valid markdown.
---

## Implementation plan

# Phase 05 Task Implementation Plan — Edit status in markdown

Task: `src/board/tasks/05-01-edit-status-in-markdown.md`

This implementation plan implements safe status updates by editing `src/board/tasks/*.md` (source of truth). It follows the shell-only guardrails from `src/storage/research/shell-only-cli-advanced-notes.md`:
- temp file + atomic `mv`
- optional mkdir-based lock for concurrent edits
- validate/normalize before writing

## Outcome (what “done” means)

1) A `set_status` action exists that updates only the `# Status` section value.
2) Writes are atomic and do not corrupt markdown files.
3) Status values are validated and normalized to canonical enums before writing.
4) The board UI reflects the change after refresh (`--list` and TUI `r`).

## Canonical status set

Use canonical statuses from `src/board/config.json.statuses`:
`BACKLOG|TODO|INPROGRESS|BLOCKED|DONE|REVIEW|ARCHIVED|CANCELLED`

Normalize inputs using the mapping defined in:
- `src/board/tasks/01-03-normalization-rules.md`

## API (authoritative)

Create a POSIX `sh` action module:
- `src/cli/commands/board/actions/set_status.sh`

Expose a function:
- `board_set_status <path> <status>`

Behavior:
- On success: exit `0`
- On invalid status: print error to stderr, exit `1`
- On missing file: print error to stderr, exit `1`

## Markdown edit contract

Target pattern:
- Section header: `# Status`
- Next non-empty line after the header is the status value line.

Update rule:
- Replace only the value line.
- Do not alter other content/spacing outside the status line.

## Missing `# Status` section behavior

Choose one (documented):

Option A (recommended for v1):
- If `# Status` section missing: error (exit `1`) with a clear message.

Option B:
- Insert a `# Status` section after `# Priority` (or at end) and write value.

Recommendation:
- Start with Option A to avoid unexpected document rewrites; add insertion later once stable.

## Implementation approach (portable)

Use `awk` to rewrite the file deterministically:

- Read the file line-by-line.
- When you see `# Status`, set a flag `in_status=1`.
- The next non-empty line after `# Status` is replaced with the new canonical status.
- All other lines are printed unchanged.

Write to a temp file and atomic move:
- `tmp="$(mktemp ...)"` with fallback if `mktemp` unavailable
- `awk ... "$path" > "$tmp"`
- `mv "$tmp" "$path"`

Always clean up temp files on failure.

## Locking (optional but recommended)

If you add locking (Phase 05-05):
- Acquire lock before writing:
  - `mkdir "$lock_dir"` as atomic lock
- Release via `trap` on exit.

## Integration points

- TUI `S` action calls `board_set_status "$path" "$next_status"` and then refreshes.
- CLI (non-interactive) can later expose a command like:
  - `bilu board --set-status <id> <status>` (optional)

## Tests

Add a persistence test (Phase 05-06):
- Copy a task markdown file into a temp dir.
- Call `board_set_status` on the copy.
- Assert:
  - status line changed to expected value
  - other sections unchanged (at least by checking title text still present)

## Acceptance checks

- Running status change does not corrupt markdown.
- Status is updated and normalized (writes canonical value).
- UI refresh shows the card moved to the correct column (once kanban is implemented).

## References

- `src/board/tasks/05-01-edit-status-in-markdown.md`
- `src/board/tasks/01-03-normalization-rules.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

# Description
Implement safe status updates by editing the # Status section in task markdown (replace only the value line), validating the normalized status, and writing via temp file + atomic mv so files remain valid.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- devops
- planning
# depends_on
