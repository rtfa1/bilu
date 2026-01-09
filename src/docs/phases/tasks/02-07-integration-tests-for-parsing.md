# Phase 02 — Integration tests for parsing

## Goal

Add tests to ensure routing + argument parsing don’t regress.

## Checklist

- [ ] Add tests verifying:
  - [ ] `bilu board --help` exits `0`
  - [ ] unknown flag exits `2`
  - [ ] `--filter` without `--filter-value` exits `2`
  - [ ] `-l -f status -fv todo` works
- [ ] Ensure tests don’t depend on ANSI output.

## Acceptance

- Test suite covers CLI parsing edge cases and passes consistently.

