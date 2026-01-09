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
---

## Implementation plan

# Phase 05 Task Implementation Plan — Rebuild index command

Task: `src/board/tasks/05-04-rebuild-index-command.md`

This plan defines an explicit, deterministic “rebuild derived artifacts” command. It is designed to be safe (no silent rewrites), portable (POSIX `sh` + `awk`), and aligned with the project’s “md is source of truth” guidance in `src/storage/research/shell-only-cli-advanced-notes.md`.

## Outcome (what “done” means)

1) `bilu board --rebuild-index` exists and is documented in `bilu board --help`.
2) Rebuild is deterministic: same inputs → byte-identical outputs.
3) Rebuild is explicit: by default it prints to stdout; writing files requires an explicit flag.
4) Rebuild can be used after edits to normalize old/inconsistent data in *derived* outputs (without rewriting markdown unless a separate explicit migration command is chosen).

## CLI contract (authoritative)

Command:
- `bilu board --rebuild-index`

Recommended flags:
- `--format <json|tsv|both>` (default: `both`)
- `--output <path>` (optional; implies `--format` single output)
- `--write` (overwrite the canonical derived files in-place; never the default)
- `--help, -h`

Exit codes:
- `0` success
- `1` runtime/data error (missing board dir, parse failure, cannot write)
- `2` usage error (unknown flag, missing value)

## Layout + outputs

Rebuild must target the detected bilu layout (repo layout vs installed layout) and must not write to arbitrary `$PWD`.

Authoritative locations (recommended; keep consistent with `01-06-index-derivation-and-migration.md`):

- Canonical JSON index (optional):
  - repo layout: `src/board/default.json`
  - installed layout: `.bilu/board/default.json`
- Canonical TSV cache (recommended):
  - repo layout: `src/board/board.tsv` (or `src/board/storage/board.tsv` if you choose a storage subdir)
  - installed layout: `.bilu/storage/board.tsv` (or `.bilu/board/board.tsv`)

Rules:
- If `--write` is not set: write nothing to disk; print to stdout.
- If `--write` is set: write with temp file + atomic `mv` (never partial writes).
- If `--output <path>` is set: write only that file (still atomic), and require `--format json|tsv` (not `both`).

## Data sources + precedence

Assume (recommended) “markdown is authoritative”:
- Read tasks from `board/tasks/*.md`.
- Use `board/config.json` for allowed values, display order, and defaults.
- Treat `default.json` as derived and never as the primary source.

Precedence when deriving fields:
1) Markdown task file (authoritative fields: id/link, title, status, priority, depends_on, tags/kind if present in future).
2) Config defaults (e.g., default status, default priority, display ordering weights).
3) Derived values (e.g., `link` from filename, `priority_weight` from config mapping).

## Deterministic ordering rules

Ordering must be stable and documented:

1) Task sort order:
   - numeric prefix in filename (e.g. `08-...`) ascending when present
   - then filename lexicographic
2) Within a task:
   - `depends_on` order preserved as authored in markdown
   - `tags` either preserved or sorted; pick one and enforce it consistently (sorting recommended for determinism)
3) JSON key order per task object must be stable (even if JSON doesn’t require it).

## JSON output format (stable + minimal)

Because `jq` is not allowed as a runtime dependency, implement JSON generation as one of:

1) POSIX `sh` + `awk` JSON writer (recommended):
   - build records in TSV first
   - emit JSON by iterating TSV in `awk`
   - include a small JSON string escape function (`\\`, `\"`, newlines → `\\n`, tabs → `\\t`)
2) Optional helper if present (allowed only if you explicitly choose this project-wide):
   - if `python3` exists, prefer it for JSON escaping; otherwise fall back to the awk writer

Formatting guidelines (for deterministic diffs):
- 2-space indentation
- one object per task
- newline at EOF
- no trailing spaces

## Safety rules (no surprises)

Rebuild must never:
- rewrite task markdown files
- run implicitly during `--list`
- write output files unless `--write` (or `--output`) is provided

Writes must always:
- take a lock (Phase 05-05) if you implement locking, even for rebuild
- write to a temp file in the same directory and then `mv` into place

## Implementation sketch (modules)

Add a rebuild implementation used by the CLI and (later) by editing actions:

- `src/cli/commands/board/actions/rebuild_index.sh` (POSIX `sh`)
  - `board_rebuild_index --format <...> [--write|--output <path>]`

Core responsibilities:
1) Resolve board directories from the detected bilu layout (same rules used elsewhere in the board module).
2) Compile markdown tasks into strict TSV (the internal record format from Phase 02).
3) Emit TSV and/or JSON deterministically.
4) Perform atomic writes when requested.

## Tests (non-interactive)

Add a dedicated test that:
- runs rebuild twice on the same fixture set and asserts identical output (byte-for-byte)
- asserts `--rebuild-index` does not modify files unless `--write` is passed
- asserts usage errors return exit code `2`

Keep tests deterministic:
- set `NO_COLOR=1`
- force stable locale for sorting if used (`LC_ALL=C`)

## Acceptance checks

- `bilu board --rebuild-index --format tsv` prints deterministic TSV to stdout.
- `bilu board --rebuild-index --format json` prints deterministic JSON to stdout.
- `bilu board --rebuild-index --write` updates only derived files, using atomic writes.
- Running rebuild does not edit any `board/tasks/*.md` files.

## References

- `src/board/tasks/05-04-rebuild-index-command.md`
- `src/board/phases/05-persistence-and-editing.md`
- `src/board/tasks/01-06-index-derivation-and-migration.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

# Description
Add a deterministic rebuild-index command (bilu board --rebuild-index) that regenerates derived default.json from task markdown with stable ordering/formatting and explicit write behavior (no silent rewrites).
# Status
TODO
# Priority
MEDIUM
# Kind
task
# Tags
- planning
# depends_on
