# Phase 01 Task Implementation Plan — `bilu board --validate`

Task: `src/board/tasks/01-05-validation-command.md`

This implementation plan defines the `--validate` contract (output + exit codes) and how it relates to normalization. It follows `src/storage/research/shell-only-cli-advanced-notes.md`:
- keep exit codes consistent (`0/1/2`)
- treat normalization issues as warnings by default, but allow validation to be stricter
- keep tests command-oriented (assert exit code + stdout/stderr patterns)

## Outcome (what “done” means)

1) `bilu board --validate` exists and is documented in `--help`.
2) It has a stable, human-readable output format and deterministic exit codes.
3) Tests cover success and failure modes.

## CLI contract

### Command

- `bilu board --validate`

### Exit codes

- `0`: all checks pass (no fatal errors)
- `1`: fatal config/data errors detected
- `2`: usage error (unknown flag, missing argument, etc.)

### Output format (stable)

Write to stdout for the summary, stderr for warnings/errors:

- On success:
  - stdout: `ok`
  - optional stdout lines: counts (tasks checked)
- On warnings only:
  - stdout: `ok` (still ok)
  - stderr: `bilu board: warn: ...`
- On fatal error:
  - stderr: `bilu board: error: ...`
  - exit `1`

Keep wording consistent so tests can match simple strings (`ok`, `warn:`, `error:`).

## Validation checks (what `--validate` does)

### A) Config validation (`src/board/config.json`)

Required top-level keys:
- `statuses`
- `priorities`
- `kind`
- `tags`
- `ui` (optional for v1, but validate if present)

Checks:
- `statuses` values are unique integers (ordering map).
- `priorities` values are unique integers (or explicitly allow ties and document it).
- `kind` keys are non-empty strings.
- `tags` keys are non-empty strings.

Failure severity:
- Missing `statuses`/`priorities`/`kind` → fatal (exit `1`).
- Missing `tags` → warn or fatal (decide; recommend warn because tags can be empty).

### B) Task validation (`src/board/tasks/*.md` and/or index)

Depending on the chosen source-of-truth policy:

- If markdown is authoritative:
  - enumerate `tasks/*.md`
  - parse required sections: `Title`, `Priority`, `Status`
  - normalize values using the rules from `01-03-normalization-rules_imp.md`
- If index is authoritative:
  - validate `default.json` entries and check referenced markdown exists

Checks per task:
- Required fields are present after parsing.
- `status` normalizes to canonical enum.
- `priority` normalizes to canonical enum.
- `depends_on` targets:
  - default: warn if missing
  - optional strict mode later: error if missing
- `link` target exists (warn-only by default).

### C) Internal record sanity (TSV contract)

If you generate TSV during validate (recommended), confirm:
- no tabs/newlines in any TSV field
- required columns are non-empty

## Implementation strategy (shell-only, no `jq`)

Per the parsing strategy task:
- Prefer parsing markdown with `awk`.
- Prefer avoiding runtime JSON parsing; if you must read `config.json`:
  - schema-specific `awk` extraction, or
  - optional `python3` helper, or
  - use a compiled config TSV produced by `--rebuild-index`

`--validate` can be the place where stricter parsing is acceptable, as it’s not called in hot loops.

## Tests to add

Command-oriented tests (no ANSI dependencies):
- `bilu board --validate` exits `0` with current board data.
- Introduce a temporary broken task file in a temp dir:
  - missing `# Status` → exit `1` (if you choose fatal), or warn-only (if you choose lenient)
- Unknown flag:
  - `bilu board --validate -x` exits `2`

Run tests with `NO_COLOR=1` to keep output stable.

## Acceptance checks

- `--validate` output and exit codes match this doc.
- Validation reuses normalization rules (single source of truth).
- Tests exist and pass.

## References

- `src/board/tasks/01-05-validation-command.md`
- `src/board/tasks/01-03-normalization-rules_imp.md`
- `src/board/tasks/01-04-json-and-markdown-parsing-strategy_imp.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

