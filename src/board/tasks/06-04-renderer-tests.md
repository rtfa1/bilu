# Phase 06 — Renderer tests

## Goal

Verify non-interactive outputs without relying on ANSI formatting.

## Checklist

- [ ] Add tests for:
  - [ ] `--view=table` includes expected titles/statuses
  - [ ] `--view=kanban` includes column headers/markers
  - [ ] `--no-color` emits no escape sequences
- [ ] Fix terminal width for tests if needed (e.g. by setting env or using a helper).

## Acceptance

- Render tests are stable and do not flake due to terminal differences.

