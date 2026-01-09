# Phase 03 — Renderer tests

## Goal

Add tests for non-interactive renderers without depending on ANSI formatting.

## Checklist

- [ ] Add tests for:
  - [ ] `--view=table` contains expected titles/statuses
  - [ ] `--view=kanban` prints column headers (or markers) deterministically
  - [ ] `--no-color` produces no ANSI escape sequences
- [ ] Ensure tests don’t depend on terminal width (set a fixed width if needed).

## Acceptance

- Tests pass on CI and local shells with stable expectations.

