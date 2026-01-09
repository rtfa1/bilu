# Phase 06 — Test matrix

## Goal

Define what gets tested (and what doesn’t) for a shell-only board UI.

## Checklist

- [ ] Define test categories:
  - [ ] CLI parsing
  - [ ] data normalization
  - [ ] rendering (table/kanban) in non-interactive mode
  - [ ] persistence edits (status/priority)
- [ ] Explicitly exclude TUI interaction testing (manual-only) unless a stable harness is introduced.
- [ ] Define required tools for tests (POSIX `sh`, coreutils).

## Acceptance

- A clear matrix exists and is referenced by the test suite.

