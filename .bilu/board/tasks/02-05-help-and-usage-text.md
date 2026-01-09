# Phase 02 — Help and usage text

## Goal

Standardize help output for `bilu board` and ensure docs match.

## Checklist

- [x] Add `bilu board --help` output with:
  - [x] usage line
  - [x] options with aliases
  - [x] examples for filter usage
- [x] Ensure `bilu help` mentions `board`.
- [x] Update `.bilu/cli/bilu-cli.md` if flags change.

## Acceptance

- Help output is concise, accurate, and consistent across commands.
---

## Implementation plan

# Phase 02 Task Implementation Plan — Help and usage text

Task: `.bilu/board/tasks/02-05-help-and-usage-text.md`

This implementation plan standardizes help output for `bilu board`, keeps it consistent with `bilu help` and `.bilu/cli/bilu-cli.md`, and ensures usage errors always show the same guidance. It follows `.bilu/storage/research/shell-only-cli-advanced-notes.md` by preferring boring/explicit CLI contracts and stable outputs suitable for tests.

## Outcome (what “done” means)

1) `bilu board --help` prints a concise, accurate help message and exits `0`.
2) Usage errors (exit `2`) print the same usage block to stderr.
3) `bilu help` lists `board` (already true) and stays accurate.
4) `.bilu/cli/bilu-cli.md` matches the implemented flags and examples.

## Help content spec (authoritative)

### `bilu board --help` must include

- Usage:
  - `bilu board --list [--filter <name> --filter-value <value>]`
  - `bilu board --validate`
  - `bilu board --migrate [--dry-run]`
  - `bilu board --rebuild-index [--dry-run]`
- Options list with aliases:
  - `--list, -l`
  - `--filter, -f <name>`
  - `--filter-value, -fv <value>`
  - `--validate`
  - `--migrate`
  - `--rebuild-index`
  - `--dry-run`
  - `--help, -h`
- Examples:
  - `bilu board --list`
  - `bilu board --list --filter=status --filter-value=todo`
  - `bilu board --list -f status -fv todo`
  - `bilu board --validate`

### Consistency rules

- The options list must match the parser exactly (no “planned” flags shown as implemented).
- Exit codes are implied by behavior:
  - `--help` exits `0`
  - usage errors exit `2`

## Where help text lives

To avoid drift:
- `.bilu/cli/commands/board.sh` should call a single `board_usage` function (eventually from `args.sh` or `lib/log.sh`).
- All usage errors should call `usage_error` which prints:
  - an error line (stderr)
  - usage text (stderr)
  - exit `2`

## Documentation sync

Update/keep consistent:
- `.bilu/cli/bilu-cli.md` section `bilu board`:
  - ensure examples match actual flags and aliases
  - avoid mentioning unimplemented flags until they exist

## Tests to lock help output

Add/adjust tests:
- `bilu board --help` exit `0`, output contains `Usage: bilu board`
- Unknown flag exits `2` and stderr contains `Usage: bilu board`
- Paired flag errors exit `2` and stderr contains `--filter-value`/`--filter` message plus `Usage:`

Run tests with `NO_COLOR=1` to keep output stable.

## Acceptance checks

- Help output is concise, accurate, and matches the parser behavior.
- Docs (`.bilu/cli/bilu-cli.md`) match the CLI.
- Tests prevent help/usage regressions.

## References

- `.bilu/board/tasks/02-05-help-and-usage-text.md`
- `.bilu/storage/research/shell-only-cli-advanced-notes.md`
- `.bilu/cli/commands/board.sh`
- `.bilu/cli/bilu-cli.md`

# Description
Standardize bilu board help output (usage line, options with aliases, filter examples), ensure bilu help mentions board, and keep the CLI docs in sync as flags evolve.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- documentation
- planning
# depends_on

---

## Outcomes

- Updated `bilu board --help` to include examples and keep options aligned with the parser (`.bilu/cli/commands/board.sh`).
- Synced docs to include `--validate` and `--help` (`.bilu/cli/bilu-cli.md`).
- Tests: `sh tests/run.sh`.
