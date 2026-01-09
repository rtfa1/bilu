# Phase 01 — Normalized task schema

## Goal

Define the canonical internal record the CLI uses for rendering and editing.

## Checklist

- [ ] Define required fields: `id`, `title`, `status`, `priority`, `path`.
- [ ] Define optional fields: `description`, `kind`, `tags[]`, `depends_on[]`, `link`.
- [ ] Define ID derivation rules (from filename, from index entry, etc).
- [ ] Define how links/paths are represented in installed vs repo layout.

## Acceptance

- A stable schema is documented and referenced by all renderers.
---

## Implementation plan

# Phase 01 Task Implementation Plan — Normalized task schema

Task: `.bilu/board/tasks/01-02-normalized-task-schema.md`

This implementation plan defines a canonical, implementation-ready task schema and an internal TSV “wire format” that all renderers consume. It incorporates the guidance in `.bilu/storage/research/shell-only-cli-advanced-notes.md`: normalize early, use TSV with explicit escaping rules, and keep non-interactive transforms `awk`-friendly.

## Outcome (what “done” means)

1) A stable normalized schema is written down with required/optional fields.
2) A strict TSV record format is defined (column order + escaping rules).
3) ID and path/link representation rules are explicit for both repo and installed layouts.
4) All subsequent loaders/renderers reference this schema (no ad-hoc fields).

## Normalized task schema (authoritative)

### Required fields

- `id` (string)
  - unique identifier derived from the markdown filename (preferred).
- `title` (string)
- `status` (enum)
  - canonical set from `.bilu/board/config.json.statuses`
- `priority` (enum)
  - canonical set from `.bilu/board/config.json.priorities`
- `path` (string)
  - absolute filesystem path to the task markdown file (recommended to keep repo vs installed layouts identical).

### Optional fields

- `description` (string)
- `kind` (enum)
  - canonical set from `.bilu/board/config.json.kind`
- `tags` (list of strings)
- `depends_on` (list of strings)
  - references to other tasks (by link or id)
- `link` (string)
  - canonical “board link” path (e.g. `board/tasks/<file>.md`) for display and index compatibility

## ID derivation rules (deterministic)

Preferred:
- `id` = filename without extension, e.g.
  - `.bilu/board/tasks/01-project-scaffold-and-manifest.md`
  - → `01-project-scaffold-and-manifest`

Constraints:
- `id` must be stable across repo/installed layout.
- `id` must not contain tabs/newlines.

## Path and link representation (repo vs installed)

The CLI must work in two layouts:
- repo: `.../.bilu/board/tasks/*.md`
- installed: `.../.bilu/board/tasks/*.md`

Define both representations:

- `path`:
  - absolute filesystem path to the `.md` (recommended for internal operations like open/edit)
- `link`:
  - repo-style relative link for display/index compatibility, always:
    - `board/tasks/<filename>.md`

Rule:
- Always compute `link` from the basename of `path`, not from where the file lives.

## Internal TSV wire format (authoritative)

Per `.bilu/board/tasks/02-06-internal-record-format.md`, define a single strict TSV with stable column order.

Recommended columns:
1) `id`
2) `status`
3) `priority_weight` (numeric; derived from `config.json.priorities`)
4) `priority`
5) `kind`
6) `title`
7) `path`
8) `tags_csv`
9) `depends_csv`
10) `link`

Example (tabs shown as `\t` here for illustration only):
`01-project-scaffold-and-manifest\tINPROGRESS\t8\tHIGH\tfeature\tProject scaffold...\t/abs/.../01-project...\tfrontend,planning\t\tboard/tasks/01-project...md`

## Escaping rules (must be enforced)

From the research note:
- TSV fields must not contain literal **tabs** or **newlines**.

Rules:
- Replace `\t` and `\n` in `title`/`description` with spaces during normalization.
- For CSV subfields (`tags_csv`, `depends_csv`):
  - use comma-separated values with no spaces OR spaces are allowed but must be consistent.
  - values must not contain commas; if they could, choose a different delimiter (pipe `|`) and document it.

## Compatibility rules for optional fields

- If `kind` is missing: default to `task` (after normalization rules in Task 01-03).
- If `tags` missing: `tags_csv` empty.
- If `depends_on` missing: `depends_csv` empty.
- If `description` missing: do not include it in TSV (keep it out of the wire format to reduce escaping risk), or add as an optional 11th column later.

Recommendation:
- Keep TSV minimal and stable; renderers can read full markdown if they need long description.

## Implementation notes (how this becomes code)

- Implement the schema as the single source of truth in the board module docs and in code:
  - normalizers output exactly the TSV format above
  - renderers consume only that TSV format
- Keep non-interactive processing in `awk`-friendly steps:
  - `awk -F '\t'` can filter/sort quickly and portably.

## Acceptance checks

- A single TSV format is documented and referenced by:
  - `.bilu/board/tasks/02-06-internal-record-format.md`
  - render phase docs (03/04)
- ID and path/link rules are explicit and deterministic across layouts.
- Escaping rules are written and enforced by normalization.

## References

- `.bilu/board/tasks/01-02-normalized-task-schema.md`
- `.bilu/board/tasks/01-03-normalization-rules.md`
- `.bilu/board/tasks/02-06-internal-record-format.md`
- `.bilu/storage/research/shell-only-cli-advanced-notes.md`
- `.bilu/board/config.json`

---

## Outcomes

- Aligned the normalized schema doc to the repo’s `.bilu/board/...` layout (no more `src/board/...` references).
- Clarified `path` as an absolute filesystem path and `link` as `board/tasks/<filename>.md` for stable behavior across repo vs installed layouts.
