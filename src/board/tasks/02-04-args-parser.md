# Phase 02 — Args parser

## Goal

Build a robust board flag parser with aliases and consistent error handling.

## Required flags (now)

- `--list` / `-l`
- `--filter` / `-f`
- `--filter-value` / `-fv`
- `--help` / `-h`

## Checklist

- [ ] Support both `--flag value` and `--flag=value`.
- [ ] Reject unknown flags with exit `2`.
- [ ] Enforce paired flags:
  - [ ] `--filter` requires `--filter-value`
  - [ ] `--filter-value` requires `--filter`
- [ ] Ensure `-fv` is accepted as a single token (not split into `-f -v`).
- [ ] Add `--` end-of-options support.

## Acceptance

- Parser behavior is deterministic and matches docs exactly.

