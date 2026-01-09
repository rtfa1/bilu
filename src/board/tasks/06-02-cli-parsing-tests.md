# Phase 06 — CLI parsing tests

## Goal

Prevent regressions in flags and aliases.

## Checklist

- [ ] Add tests for:
  - [ ] `bilu board --help` exits `0`
  - [ ] `bilu board -l` works
  - [ ] unknown flags exit `2`
  - [ ] missing required flag values exit `2`
  - [ ] `--filter=status --filter-value=todo` works
  - [ ] `-f status -fv todo` works

## Acceptance

- Parser tests pass consistently across platforms.

