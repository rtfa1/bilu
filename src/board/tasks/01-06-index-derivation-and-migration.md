# Phase 01 — Index derivation and migration

## Goal

Define how `default.json` is produced/maintained (if it’s derived) and how to migrate existing inconsistent data.

## Checklist

- [ ] If `default.json` is derived:
  - [ ] define `bilu board --rebuild-index`
  - [ ] define stable ordering
  - [ ] define which fields come from markdown vs config defaults
- [ ] Migration rules:
  - [ ] normalize priority casing in existing JSON
  - [ ] normalize kind fields (`bug`/`improvement` → `kind`)
  - [ ] normalize status to config enum values
- [ ] Decide whether migration is automatic or an explicit command.

## Acceptance

- A migration story exists and doesn’t surprise users (no silent rewrites unless requested).

