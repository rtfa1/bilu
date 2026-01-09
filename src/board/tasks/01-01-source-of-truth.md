# Phase 01 — Choose source of truth

## Goal

Pick a single authoritative source for task metadata so rendering and editing are deterministic.

## Options

- **A (recommended):** `src/board/tasks/*.md` is the source of truth; `src/board/default.json` is derived.
- **B:** `src/board/default.json` is the source of truth; markdown is detail-only.

## Checklist

- [ ] Decide A or B.
- [ ] Define precedence if both sources contain the same field.
- [ ] Define what fields are editable (status/priority/kind/tags/etc).
- [ ] Define whether editing should update markdown, JSON, or both.

## Acceptance

- A one-paragraph “source of truth” policy is written and will be enforced by the CLI.

