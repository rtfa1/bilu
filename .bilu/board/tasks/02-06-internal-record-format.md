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
---

## Implementation plan

# Phase 02 Task Implementation Plan — Internal record format (TSV)

Task: `src/board/tasks/02-06-internal-record-format.md`

This implementation plan locks the single internal “wire format” used between loaders/normalizers and renderers. It follows `src/storage/research/shell-only-cli-advanced-notes.md`: TSV is the right interchange, but only if escaping rules are explicit and enforced.

## Outcome (what “done” means)

1) One TSV format is defined with strict column order.
2) Escaping rules are defined so TSV parsing is unambiguous.
3) All renderers consume this exact TSV format (no ad-hoc fields).
4) Tests and validation checks assert TSV invariants.

## Authoritative TSV format (v1)

Use **tab-separated** fields with the following strict column order:

1) `id`
2) `status`
3) `priority_weight`
4) `priority`
5) `kind`
6) `title`
7) `path`
8) `tags_csv`
9) `depends_csv`
10) `link`

Notes:
- `priority_weight` is a numeric value derived from `src/board/config.json.priorities`.
- `path` is an absolute filesystem path to the task markdown file.
- `link` is a canonical display/index link: `board/tasks/<filename>.md`.

## Escaping rules (must be enforced by normalization)

Hard rule (from research note):
- TSV fields must not contain literal **tabs** or **newlines**.

Rules:
- Replace `\t` and `\n` in `title` with spaces.
- Replace `\t` and `\n` in any other free-text fields that appear in TSV (if added later).
- Do not include full multi-line descriptions in TSV v1.

CSV subfields rules:
- `tags_csv` and `depends_csv` are comma-separated lists.
- Individual items must not contain commas.
- Empty list is represented as an empty field.

If commas are needed in the future, switch to pipe-delimited lists and version the format.

## Versioning and future-proofing

Add a format version marker in code (not in TSV line) to keep formats compatible:
- `BOARD_TSV_VERSION=1`

If the TSV format changes:
- bump version
- update all renderers and tests in the same PR
- keep older formats unsupported unless you explicitly add migration

## Producer/consumer responsibilities

### Producers (must output TSV v1)

- markdown loader (`load/tasks_md.sh`)
- index loader if used (`load/tasks_index.sh`)
- rebuild command (`actions/rebuild_index.sh`) if it emits TSV cache

### Consumers (must accept TSV v1 only)

- `render/table.sh`
- `render/kanban.sh`
- `render/tui.sh` (may parse TSV in bash)

No renderer should attempt to infer missing columns; missing columns is a fatal error in `--validate`.

## Validation and tests

### Validation checks (non-interactive)

Add a TSV sanity checker (can live in `normalize.sh` or `--validate`):
- Each line has exactly 10 fields.
- No field contains `\t` or `\n`.
- Required fields (`id`, `status`, `priority`, `title`, `path`) are non-empty.

### Tests

Add tests that:
- run the loader + normalizer and ensure output is parseable with `awk -F '\t'`.
- ensure no ANSI is present when `NO_COLOR=1`.
- ensure filtering/sorting operates on TSV reliably.

## Acceptance checks

- TSV v1 format is documented and referenced by schema docs.
- All board renderers and actions use TSV v1.
- Escaping rules are implemented and enforced.

## References

- `src/board/tasks/02-06-internal-record-format.md`
- `src/board/tasks/01-02-normalized-task-schema.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

# Description
Define the single internal TSV wire format (strict column order) used between loaders/normalizers and renderers, including explicit escaping rules for tabs/newlines so parsing is unambiguous everywhere.
# Status
TODO
# Priority
MEDIUM
# Kind
task
# Tags
- design
- frontend
- planning
- usability
# depends_on
