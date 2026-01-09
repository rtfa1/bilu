# Phase 00 — Acceptance criteria

## Goal

Define measurable acceptance criteria for the board feature so progress is testable.

## Must pass

- [ ] `bilu board --list` prints a stable list and exits `0`.
- [ ] `bilu board --list --filter=status --filter-value=todo` filters correctly.
- [ ] Aliases work: `-l`, `-f`, `-fv`.
- [ ] Unknown flags exit `2` and show usage.
- [ ] Works in repo layout and installed layout.
- [ ] No required dependencies beyond shell + coreutils.

## Nice to have (later)

- [ ] `--view=kanban` prints a readable kanban layout.
- [ ] `--tui` offers keyboard navigation and search.
- [ ] Edit status/priority safely and persist to disk.

## Acceptance

- These criteria are referenced by tests and docs, and used to decide “done”.

