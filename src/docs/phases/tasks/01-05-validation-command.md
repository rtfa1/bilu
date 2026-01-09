# Phase 01 — `bilu board --validate`

## Goal

Specify validation output and exit codes so broken boards are detectable.

## Checklist

- [ ] Define exit codes:
  - [ ] `0` ok
  - [ ] `1` fatal config/data errors
  - [ ] `2` CLI usage error
- [ ] Validate `src/board/config.json`:
  - [ ] required top-level keys exist
  - [ ] status ordering values are unique
  - [ ] priority weights are unique (or explicitly allow ties)
- [ ] Validate tasks:
  - [ ] every task normalizes cleanly
  - [ ] `depends_on` targets exist (warn-only vs error)
  - [ ] `link` targets exist (warn-only vs error)

## Acceptance

- `--validate` has a stable output format and is used by tests.

