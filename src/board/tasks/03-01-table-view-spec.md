# Phase 03 — Table view spec

## Goal

Define the exact output contract for `bilu board --list` (table view).

## Checklist

- [ ] Define default view name: `table`.
- [ ] Define columns and their order.
- [ ] Define truncation and wrapping rules.
- [ ] Define whether header and totals are shown.
- [ ] Define what is printed for missing fields (tags/kind/link).
- [ ] Define whether output is stable for scripting (consider a `--format=tsv` later).

## Acceptance

- A sample output snippet is documented and the implementation matches it.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Table view spec

Task: `src/board/tasks/03-01-table-view-spec.md`

This implementation plan defines an exact, testable output contract for `bilu board --list` (table view). It aligns with:
- `src/board/phases/03-rendering-table-and-kanban.md` (rendering requirements)
- `src/storage/research/shell-only-cli-advanced-notes.md` (NO_COLOR, stable output for tests, awk-friendly pipelines)

## Outcome (what “done” means)

1) A table view output contract is defined (columns, order, widths, truncation).
2) A sample output snippet exists and the implementation matches it.
3) Output is stable enough for tests and for light scripting.
4) Color is optional and fully disable-able (`NO_COLOR`, `--no-color`, non-TTY auto-disable).

## View selection contract

- Default view for `bilu board --list` is `table`.
- Future flag: `--view=table` is equivalent to the default (document once implemented).

## Table output contract (authoritative)

### Header and totals

For v1:
- Print a single header line.
- Print a single separator line.
- Print one task per line.
- Optionally print a footer totals line (defer until needed).

Recommended header:
- `STATUS  PRIO  TITLE  TAGS  PATH`

### Columns (v1)

Order and meaning:
1) `STATUS`
2) `PRIO`
3) `TITLE`
4) `TAGS`
5) `PATH` (or `LINK` — choose one and stay consistent)

Recommendation:
- Print `PATH` in table view for immediate “open/edit” friendliness.
- Keep `LINK` for index/debug output (or add `--format=tsv/json` later).

### Column widths and alignment

Constraints:
- Must fit within terminal width when possible.
- Must remain readable at 80 columns.

Rules (v1, deterministic):
- `STATUS`: fixed width 11 (fits `INPROGRESS`)
  - left-aligned, padded with spaces
- `PRIO`: fixed width 8 (fits `CRITICAL`)
  - left-aligned
- `TITLE`: flexible, takes remaining width after fixed columns
  - truncated with `...` when needed
- `TAGS`: fixed width 18 (or flexible if you prefer)
  - joined with commas, truncated with `...`
- `PATH`: flexible; if too long, print basename only (or truncate from the left)

Decide one truncation style for long paths:
- **Option A:** basename only (simple, stable)
- Option B: left-truncate with prefix `.../` (more informative)

Recommendation:
- Start with basename only for v1 stability.

### Missing values

- Missing `TAGS` → print `-`
- Missing `PRIO`/`STATUS` after normalization → use defaults (handled by normalization)
- Missing `PATH` (broken link) → print `MISSING:<filename>` and warn to stderr

### Sorting and filtering interaction

Table view must reflect the active filter/sort state:
- If a filter is applied, include a short hint in the header line, e.g.:
  - `FILTER status=TODO`
This should be optional; if it complicates alignment, print it as a first line above the header.

## Color rules (ties to 03-02)

- If colors enabled:
  - colorize `STATUS` and/or `PRIO` tokens only (avoid coloring whole line to keep alignment stable)
- If colors disabled:
  - plain text only

Disable color when:
- `NO_COLOR` is set and non-empty
- `--no-color` is passed
- stdout is not a TTY (`[ -t 1 ]` false)

## Sample output snippet (v1)

This is an illustrative format (not real data-dependent):

```
STATUS      PRIO     TITLE                          TAGS               PATH
----------  -------  -----------------------------  ------------------  -----------------------------
TODO        HIGH     Define messaging contracts...  frontend,docs       02-message-contracts.md
INPROGRESS  HIGH     Project scaffold and Chrome... frontend,planning   01-project-scaffold-and-manifest.md
```

Notes:
- Use fixed-width spacing; avoid tabs in rendered output.
- The exact underline length can be fixed or derived; tests should match only stable tokens, not spacing.

## Implementation steps

1) Implement table renderer as a single responsibility module:
- `src/cli/commands/board/render/table.sh`
2) Consume normalized TSV v1 (from `02-06-internal-record-format.md`):
- do not read markdown directly in the renderer
3) Use `awk -F '\t'` for formatting:
- easier alignment, truncation, and portability than complex shell string logic
4) Add a `--no-color` switch and `NO_COLOR` support (if not already present):
- keep it in `ui/ansi.sh` so both table and kanban share it

## Tests to lock the contract

Add/extend tests (run with `NO_COLOR=1`):
- `bilu board --list` prints:
  - header contains `STATUS` and `TITLE`
  - at least one known task title is present (once real listing is implemented)
- With filter flags:
  - header (or first line) indicates filter applied OR output contains only matching statuses

Avoid testing exact spacing; test stable tokens.

## Acceptance checks

- Contract above is implemented and reflected in docs.
- Output remains readable at 80 columns.
- Color can be disabled reliably.

## References

- `src/board/tasks/03-01-table-view-spec.md`
- `src/board/phases/03-rendering-table-and-kanban.md`
- `src/board/tasks/03-02-color-theme-and-no-color.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/tasks/02-06-internal-record-format.md`
