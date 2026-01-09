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

