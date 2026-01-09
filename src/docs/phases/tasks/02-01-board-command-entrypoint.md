# Phase 02 — Board command entrypoint

## Goal

Make `bilu board` a first-class command with a thin dispatcher and predictable routing.

## Checklist

- [ ] Confirm `src/cli/bilu` routes `board` to `src/cli/commands/board.sh`.
- [ ] Ensure `board.sh` is thin (dispatch only; no heavy logic).
- [ ] Add/verify `bilu help` documents `board`.
- [ ] Define exit codes for:
  - [ ] unknown subcommand/flag (`2`)
  - [ ] runtime error (`1`)

## Acceptance

- Running `bilu board --help` prints usage and exits `0`.

