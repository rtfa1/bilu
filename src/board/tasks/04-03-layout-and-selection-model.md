# Phase 04 — Layout and selection model

## Goal

Define how the TUI represents columns/cards and how selection moves.

## Checklist

- [ ] Data model:
  - [ ] columns with filtered card lists
  - [ ] selected position: `(column_index, card_index)`
- [ ] Movement rules:
  - [ ] left/right changes column and preserves approximate vertical position
  - [ ] up/down changes card within a column
- [ ] Scrolling:
  - [ ] vertical scroll per column or per view
  - [ ] ensure selection remains visible

## Acceptance

- Selection feels natural and doesn’t “jump” unexpectedly.

