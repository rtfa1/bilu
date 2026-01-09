# Phase 02 — Internal record format (TSV)

## Goal

Define the internal “wire format” passed from loaders/normalizers into renderers.

## Checklist

- [ ] Choose a line format (recommended TSV) with a strict column order, e.g.:
  - `id<TAB>status<TAB>prioWeight<TAB>priority<TAB>kind<TAB>title<TAB>path<TAB>tagsCsv<TAB>dependsCsv`
- [ ] Define escaping rules:
  - [ ] how tabs/newlines in fields are handled (strip or replace)
- [ ] Ensure every renderer consumes the same format.

## Acceptance

- A single internal format is defined and used everywhere (no ad-hoc parsing).

