# Phase 01 — Normalization rules

## Goal

Make the board tolerant to human input and historical inconsistencies.

## Checklist

- [ ] Status normalization:
  - [ ] Accept `Done/done/DONE` → `DONE`
  - [ ] Accept `in progress/in-progress/INPROGRESS` → `INPROGRESS`
  - [ ] Accept unknown values → warning + fallback
- [ ] Priority normalization:
  - [ ] Case-insensitive (`High/HIGH/high`) → `HIGH`
  - [ ] Unknown values → warning + fallback
- [ ] Kind normalization:
  - [ ] Prefer `kind`
  - [ ] Map legacy keys (`bug`, `improvement`) into `kind`
- [ ] Tag normalization:
  - [ ] Canonicalize casing if needed (or keep as-is and only label via `config.json`)

## Acceptance

- A normalization table exists and is implemented consistently across loaders.

