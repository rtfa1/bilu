# Phase 00 — Board data audit

## Goal

Audit the current board data and document inconsistencies that the UI must normalize.

## Checklist

- [ ] Inventory board files:
  - [ ] `src/board/config.json`
  - [ ] `src/board/default.json`
  - [ ] `src/board/tasks/*.md`
- [ ] List inconsistencies and decide normalization targets:
  - [ ] status values (e.g. `Done` vs `DONE`)
  - [ ] priority casing (e.g. `High` vs `HIGH`)
  - [ ] kind representation (e.g. `kind` vs legacy keys like `bug` / `improvement`)
- [ ] Confirm how to handle broken links (e.g. task points to missing `.md`).
- [ ] Confirm how to handle `depends_on` paths (warn vs error).

## Acceptance

- A written list of known inconsistencies with explicit normalization rules to resolve them.

## References

- `src/board/config.json`
- `src/board/default.json`
- `src/board/tasks/`

