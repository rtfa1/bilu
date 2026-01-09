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

