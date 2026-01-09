# Phase 06 — Normalization tests

## Goal

Ensure inconsistent data normalizes deterministically.

## Checklist

- [ ] Add fixtures or inline test data for:
  - [ ] status variants (`Done`, `done`, `INPROGRESS`, `in-progress`)
  - [ ] priority variants (`High`, `HIGH`, `medium`)
  - [ ] kind variants (missing `kind`, legacy keys)
- [ ] Assert stable normalized outputs.
- [ ] Assert warnings go to stderr (optional).

## Acceptance

- Normalization behavior is locked and won’t silently change.

