# Phase 05 — Rebuild index command

## Goal

If `default.json` is derived, provide a command to regenerate it deterministically.

## Checklist

- [ ] Define command name: `bilu board --rebuild-index` (or similar).
- [ ] Define which fields are sourced from markdown vs config defaults.
- [ ] Define ordering rules (stable).
- [ ] Define JSON output formatting (stable and minimal).
- [ ] Ensure rebuild is explicit (no silent rewrites).

## Acceptance

- Rebuild produces consistent output and can be used to normalize old data.

