# Phase 00 Task Implementation Plan — Module layout and responsibilities

Task: `src/board/tasks/00-05-module-layout-and-responsibilities.md`

This implementation plan defines a maintainable module architecture for `bilu board` that fits the shell-only constraints and follows the advice in `src/storage/research/shell-only-cli-advanced-notes.md`:
- treat shell as an orchestrator
- use `awk` as the compute engine for non-interactive transforms
- keep stateful interaction in `bash` (TUI only)
- define a strict internal TSV contract and normalize early

## Outcome (what “done” means)

1) A concrete module tree is defined (paths + responsibilities).
2) Each module has a clear interface (inputs/outputs/exit codes).
3) We explicitly declare which modules are POSIX `sh` vs `bash`.
4) The architecture supports both repo and installed layouts without relying on `$PWD`.

## Proposed module tree (authoritative)

### Entry point (POSIX `sh`)

- `src/cli/commands/board.sh`
  - Responsibility: parse high-level args, dispatch to renderers/actions.
  - Must remain small; no heavy data logic.

### Module directory

- `src/cli/commands/board/`
  - `paths.sh` (POSIX `sh`)
    - Locate board root for both layouts.
    - Export absolute paths: config, default.json, tasks dir, storage dir.
  - `args.sh` (POSIX `sh`)
    - Parse board flags/aliases.
    - Enforce usage errors with exit code `2`.
  - `normalize.sh` (POSIX `sh` + awk)
    - Normalize statuses/priorities/kinds.
    - Apply TSV escaping rules (no tabs/newlines in fields).
  - `load/`
    - `config.sh` (POSIX `sh` + awk)
      - Load `config.json` into shell-friendly values (or consume precompiled TSV if adopted).
    - `tasks_md.sh` (POSIX `sh` + awk)
      - Parse `tasks/*.md` into normalized TSV records.
    - `tasks_index.sh` (POSIX `sh` + awk or optional helper)
      - Read `default.json` if used as input (schema-specific extraction or optional `python3`).
  - `render/`
    - `table.sh` (POSIX `sh` + awk)
      - Print stable list/table output.
    - `kanban.sh` (POSIX `sh` + awk)
      - Print non-interactive kanban with width-aware layout and narrow fallback.
    - `tui.sh` (bash only)
      - Full-screen interactive UI: key handling, framebuffer redraw, resize trap.
  - `actions/`
    - `open.sh` (POSIX `sh`)
      - Open a task file in `$EDITOR` or pager.
    - `set_status.sh` (POSIX `sh` + awk/sed)
      - Edit `# Status` section in markdown safely (temp + atomic mv).
    - `set_priority.sh` (POSIX `sh` + awk/sed)
      - Edit `# Priority` section safely.
    - `rebuild_index.sh` (POSIX `sh` + awk)
      - Optional: generate `default.json` and/or a compiled TSV index from markdown.
  - `ui/`
    - `ansi.sh` (POSIX `sh`)
      - Centralize styling; implement `NO_COLOR`, `--no-color`, non-TTY auto-disable.
    - `layout.sh` (POSIX `sh` + awk)
      - Width calculations and wrapping helpers shared by renderers.
  - `lib/`
    - `log.sh` (POSIX `sh`)
      - `die`, `warn`, `info` helpers and consistent exit codes.
    - `lock.sh` (POSIX `sh`)
      - mkdir-based locking for edit actions (optional but recommended).

## POSIX vs bash boundary (explicit)

Per constraints + research note:
- Everything except the interactive TUI must be POSIX `sh`.
- `render/tui.sh` may be `bash` to simplify:
  - raw-ish input (`read -rsn1`)
  - escape sequence decoding
  - stateful loop

Avoid requiring bash 4+ features (macOS compatibility):
- no associative arrays
- no `mapfile`

## Internal data contract (TSV)

All loaders and normalizers should converge to a single TSV format consumed by renderers.

Recommended columns (strict order):
`id<TAB>status<TAB>prioWeight<TAB>priority<TAB>kind<TAB>title<TAB>path<TAB>tagsCsv<TAB>dependsCsv<TAB>link`

Escaping rules (must be enforced in `normalize.sh`):
- replace tabs/newlines in `title`/`description`-derived fields with spaces
- do not allow literal tabs/newlines in any field

## JSON handling strategy (must be decided)

The research note warns against runtime JSON parsing in shell. Choose one:

- **A (recommended):** treat `tasks/*.md` as source of truth and compile to TSV via `--rebuild-index` / `init`.
- **B:** schema-specific `awk` extraction for `default.json` and `config.json`.
- **C:** optional `python3` helper for JSON parsing when present.

The module layout supports all three; the project must commit to one for v1.

## Error handling policy (align to exit codes)

- Usage errors: exit `2` (parser modules).
- Data/config errors: exit `1` (missing board files, parse failures).
- Success: `0`.

Prefer explicit checks over subtle `set -e` behavior in non-interactive code.

## Implementation steps (what to do next)

1) Create `src/cli/commands/board/` tree and move logic out of `src/cli/commands/board.sh`.
2) Implement `paths.sh` first (everything depends on it).
3) Implement `args.sh` next and lock behavior with tests.
4) Implement a first-pass `normalize.sh` with:
   - status/priority/kind normalization
   - TSV escaping rules
5) Add renderers incrementally (table → kanban → tui).

## Acceptance checks

- Module tree exists and matches this doc.
- `board.sh` remains a thin dispatcher.
- Non-interactive code runs under POSIX `sh`.
- `--tui` is isolated to a `bash` module.
- Internal TSV contract is documented and used consistently.

## References

- `src/board/tasks/00-05-module-layout-and-responsibilities.md`
- `src/board/phases/02-cli-and-modules.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`

