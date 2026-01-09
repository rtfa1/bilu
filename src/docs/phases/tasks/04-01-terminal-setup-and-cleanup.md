# Phase 04 — Terminal setup and cleanup

## Goal

Safely enter/exit full-screen mode without breaking the user’s terminal.

## Checklist

- [ ] Decide interactive script shell (`bash`) and document it.
- [ ] Implement setup:
  - [ ] alternate screen buffer on
  - [ ] hide cursor
  - [ ] disable line wrap
  - [ ] disable input echo (`stty -echo`)
  - [ ] optionally set scroll region
- [ ] Implement cleanup:
  - [ ] restore main screen buffer
  - [ ] show cursor
  - [ ] re-enable wrap
  - [ ] re-enable echo
- [ ] Add `trap` handlers for `EXIT INT TERM` to always cleanup.

## Acceptance

- Exiting via `q`, `Ctrl-C`, or errors restores the terminal to normal.

