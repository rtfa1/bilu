# Phase 00 — CLI surface and aliases

## Goal

Define the exact CLI syntax for the board module, including short and long flags and validation behavior.

## Required commands

- `bilu board --list`
- `bilu board --list --filter=status --filter-value=todo`
- Aliases:
  - `-l` == `--list`
  - `-f` == `--filter`
  - `-fv` == `--filter-value`

## Checklist

- [ ] Confirm whether `bilu board --list` is the only entrypoint or whether `bilu board list` is also allowed.
- [ ] Confirm whether flags can appear before/after `board` (recommend: after `board` only).
- [ ] Confirm `--filter` supports only one filter or multiple repeated filters.
- [ ] Confirm behavior when only one of `--filter` / `--filter-value` is present (error with code `2`).
- [ ] Confirm which extra flags are in-scope immediately:
  - [ ] `--view=table|kanban`
  - [ ] `--search`
  - [ ] `--sort` / `--order`
  - [ ] `--no-color`
  - [ ] `--validate`

## Acceptance

- A documented CLI contract that implementation can follow exactly.

## References

- `src/cli/commands/board.sh`
- `src/docs/bilu-cli.md`

