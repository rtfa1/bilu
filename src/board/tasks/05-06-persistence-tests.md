# Phase 05 — Persistence tests

## Goal

Add tests covering file edits without relying on the interactive TUI.

## Checklist

- [ ] Create a temp copy of `src/board/tasks/*.md` and operate on it.
- [ ] Test status edit updates only the status section.
- [ ] Test priority edit updates only the priority section.
- [ ] Ensure atomic write behavior (file is always valid after operation).
- [ ] Ensure list output reflects edits.

## Acceptance

- Tests run in `sh tests/run.sh` and validate persistence behavior.

