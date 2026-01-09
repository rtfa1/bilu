# Phase 00 — Scope and constraints

## Goal

Lock the project constraints and define what “shell-only board UI” means for this repo.

## Decisions

- Interactive UI is allowed to use `bash` (still shell-only).
- Non-interactive commands remain POSIX `sh`.
- No required third-party dependencies (no `fzf`, `gum`, `dialog`, `jq`).
- Must work in both layouts:
  - repo layout: `src/board/...`
  - installed layout: `.bilu/board/...`

## Checklist

- [ ] Confirm the minimum supported shells for each mode (POSIX `sh` for non-interactive; `bash` for `--tui`).
- [ ] Confirm supported platforms (macOS/Linux/WSL) and any terminal assumptions (VT100 escapes).
- [ ] Confirm required environment variables (`NO_COLOR`, `$EDITOR`) and default behavior when absent.
- [ ] Confirm “no network” runtime requirement (UI must not fetch anything).

## Acceptance

- A short summary of constraints is agreed and won’t change during implementation.

## References

- `src/board/phases/00-board-ui-overview.md`

