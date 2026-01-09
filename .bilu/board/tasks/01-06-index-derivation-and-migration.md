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
---

## Implementation plan

# Phase 01 Task Implementation Plan — Index derivation and migration

Task: `src/board/tasks/01-06-index-derivation-and-migration.md`

This implementation plan defines how `src/board/default.json` is produced (when derived), how a faster internal index can be introduced, and how we migrate inconsistent existing data without surprising users. It follows the guidance in `src/storage/research/shell-only-cli-advanced-notes.md`: avoid fragile runtime JSON parsing, prefer explicit rebuild steps, and make all rewrites opt-in.

## Outcome (what “done” means)

1) `default.json` is clearly defined as derived (or explicitly not), and everyone knows which file is authoritative.
2) A rebuild command exists (spec + behavior) with deterministic output.
3) A migration story exists that does not silently rewrite user data.

## Assumption (recommended)

Assume Phase 01-01 chose:
- `tasks/*.md` is source of truth
- `default.json` is derived

If you choose the opposite, this plan still applies, but the implementation becomes more JSON-heavy and more brittle without `jq`.

## Rebuild contract: `bilu board --rebuild-index`

### Purpose

Generate derived artifacts from markdown:
- (optional) `src/board/default.json` (human-readable index)
- (recommended) a strict TSV cache for render speed (location depends on layout)

### Output locations

Repo layout:
- `src/board/default.json` (optional)
- `src/board/board.tsv` (recommended) or `src/board/storage/board.tsv` if you prefer a storage subdir

Installed layout:
- `.bilu/board/default.json` (optional)
- `.bilu/storage/board.tsv` (recommended) or `.bilu/board/board.tsv`

Rule:
- Derived artifacts must live alongside the board installation, not in arbitrary `$PWD`.

### Deterministic ordering

Define stable ordering for generated index:
1) by numeric task prefix if present (`01-`, `02-`, …)
2) else by filename lexicographically

Within tasks:
- `depends_on` ordering preserved from markdown input
- tags ordering preserved or sorted (choose one and document)

### Field sources (markdown vs config defaults)

From markdown (authoritative):
- title, description, priority, status, depends_on

From config defaults or derived:
- `priority_weight` from `config.json.priorities`
- `link` computed as `board/tasks/<filename>.md`
- `id` from filename
- `kind` default (`task`) unless specified (future)
- tags default empty unless specified (future)

### Normalization behavior during rebuild

Rebuild should normalize values in output artifacts, but should not rewrite markdown by default:
- `Done` becomes `DONE` in generated index/TSV
- `High` becomes `HIGH` in generated index/TSV

Any markdown rewriting is a separate, explicit action (`--migrate`), not part of rebuild.

## Migration rules (explicit and opt-in)

Migration means changing existing persisted user files (markdown and/or json). Make it explicit:

- `bilu board --migrate`
  - applies normalization to markdown sections (`# Status`, `# Priority`)
  - optionally rewrites legacy kind keys in `default.json` if you still keep that file around

### What migration changes (initial)

- Normalize markdown:
  - `# Status`: `Done` → `DONE` (or keep “Done” if you choose human-cased persistence; pick one)
  - `# Priority`: `High` → `HIGH`, `Medium` → `MEDIUM`, etc.
- Normalize JSON (if you still ship/keep it):
  - `priority` casing normalized
  - `bug`/`improvement` legacy keys converted to `kind`
  - `status` normalized

### Safety rules

- Never migrate automatically during `--list`.
- Use file locking for migrations (mkdir-based lock).
- Use temp file + atomic `mv` for edits.
- Provide a `--dry-run` mode that prints what would change.

## Validation integration

`bilu board --validate` should report:
- mismatched casing in markdown (warn by default, or error in strict mode)
- legacy kind fields in JSON (warn)
- missing `depends_on` targets (warn)
- missing linked task files (warn)

This gives users visibility without unexpected rewrites.

## Tests to lock behavior

Add tests that ensure:
- `--rebuild-index` output is deterministic (same input → same output).
- `--migrate` only runs when explicitly called.
- `--dry-run` does not modify files.

Tests should operate on temp copies of markdown files, not on repo files in place.

## Acceptance checks

- A rebuild command and its outputs are defined and documented.
- Migration is opt-in and safe (atomic writes + lock).
- Users can render boards even with inconsistent historical data (normalization at read time).

## References

- `src/board/tasks/01-06-index-derivation-and-migration.md`
- `src/board/tasks/01-01-source-of-truth.md`
- `src/board/tasks/01-04-json-and-markdown-parsing-strategy.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
