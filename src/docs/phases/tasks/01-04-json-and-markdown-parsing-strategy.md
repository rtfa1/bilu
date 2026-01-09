# Phase 01 — Parsing strategy (no `jq`)

## Goal

Define how shell scripts parse `config.json`, `default.json`, and `tasks/*.md` safely.

## Constraints

- No `jq` dependency.
- Keep parsing limited to the known schema; fail gracefully with clear errors.

## Checklist

- [ ] Decide whether JSON parsing uses:
  - [ ] `python3 -c` helper (allowed?) OR
  - [ ] `awk/sed` schema-specific extraction only
- [ ] Define markdown parsing approach:
  - [ ] parse `# Title`, `# Description`, `# Priority`, `# Status`, `# depends_on`
- [ ] Define handling for missing files and broken links (warn vs error).

## Acceptance

- Parsing approach is documented and chosen to be portable and maintainable.

