# Phase 00 — CLI surface and aliases

## Goal

Define the exact CLI syntax for the board module, including short and long flags and validation behavior.

## Required commands

- `bilu board --list`
- `bilu board --list --filter=status --filter-value=todo`
- Aliases:
  - `-l` == `--list`
  - `-f` == `--filter`
  - `-fv` == `--filter-value`

## Checklist

- [ ] Confirm whether `bilu board --list` is the only entrypoint or whether `bilu board list` is also allowed.
- [ ] Confirm whether flags can appear before/after `board` (recommend: after `board` only).
- [ ] Confirm `--filter` supports only one filter or multiple repeated filters.
- [ ] Confirm behavior when only one of `--filter` / `--filter-value` is present (error with code `2`).
- [ ] Confirm which extra flags are in-scope immediately:
  - [ ] `--view=table|kanban`
  - [ ] `--search`
  - [ ] `--sort` / `--order`
  - [ ] `--no-color`
  - [ ] `--validate`

## Acceptance

- A documented CLI contract that implementation can follow exactly.

## References

- `src/cli/commands/board.sh`
- `src/docs/bilu-cli.md`
---

## Implementation plan

# Phase 00 Task Implementation Plan — CLI surface and aliases

Task: `src/board/tasks/00-03-cli-surface-and-aliases.md`

This implementation plan locks the board CLI contract (commands, flags, aliases, and error handling) so subsequent phases can implement features without breaking users. It follows the recommendations in `src/storage/research/shell-only-cli-advanced-notes.md` (manual option parsing, predictable exit codes, avoid clever parsing).

## Outcome (what “done” means)

1) The `bilu board` CLI contract is explicitly documented (in this file + `src/docs/bilu-cli.md`).
2) The contract is reflected in the implementation:
- exact accepted flags and aliases
- accepted syntaxes (`--flag value` and `--flag=value`)
- deterministic error behavior and exit codes
3) Tests exist to prevent regressions in parsing and aliases.

## Current implementation snapshot (as of now)

- Routing: `src/cli/bilu` dispatches `board)` → `src/cli/commands/board.sh`
- `src/cli/commands/board.sh` already supports:
  - `--list` / `-l`
  - `--filter` / `-f` (with `--filter=...` / `-f=...` forms)
  - `--filter-value` / `-fv` (with `--filter-value=...` / `-fv=...` forms)
  - `--help` / `-h`
  - `--` end-of-options
  - paired enforcement: `--filter` requires `--filter-value` and vice versa
  - exit code `2` on usage errors

This task’s work is to *formalize* the contract and expand it in a controlled way.

## Decisions to lock (answer each checklist item)

### 1) Command forms

Decide one of:
- **A (recommended):** only flag-based: `bilu board --list ...`
- B: allow subcommand form too: `bilu board list ...`

Recommendation:
- Choose A for now to keep parsing simple in POSIX `sh`.

### 2) Flag placement

Policy:
- Flags for the board command appear **after** `board`, e.g. `bilu board --list`.
- `src/cli/bilu` consumes only the first token (command) and passes the remainder untouched to `board.sh`.

### 3) Filtering multiplicity

Decide:
- **A (recommended initially):** allow exactly one `--filter` and one `--filter-value`.
- B: allow multiple filters via repeated flags:
  - `--filter status --filter-value TODO --filter tag --filter-value frontend`

Recommendation:
- Choose A now; add multi-filter later with explicit syntax (e.g. repeatable pairs or `--where` DSL).

### 4) Required flags and exit codes

Required behavior:
- If `--filter` is set without `--filter-value`: exit `2` and show a usage hint.
- If `--filter-value` is set without `--filter`: exit `2` and show a usage hint.
- Unknown flag: exit `2` and show usage.

Exit codes (align with research note):
- `0`: success
- `1`: runtime/data/config error (e.g. missing board files)
- `2`: usage error (bad args)

## CLI contract (write exactly what we support)

### Required commands (now)

- `bilu board --list`
- `bilu board --list --filter=status --filter-value=todo`
- `bilu board --list -f status -fv todo`

### Required aliases

- `-l` == `--list`
- `-f` == `--filter`
- `-fv` == `--filter-value` (single token)

### Accepted syntaxes

- `--flag value`
- `--flag=value`
- `--` terminates option parsing

### Immediate scope (confirm)

Decide whether these are in-scope immediately (document per your task checklist):
- `--view=table|kanban`
- `--search`
- `--sort` / `--order`
- `--no-color`
- `--validate`

Recommendation:
- Document them as “planned” until implemented to avoid contract drift.

## Implementation steps (what to change in the repo)

1) Update user-facing docs:
   - Ensure `src/docs/bilu-cli.md` reflects the exact contract.
   - Add examples demonstrating both long and short forms.
2) Add `bilu board --help` section that includes:
   - list of flags + aliases
   - examples
   - exit code behavior (brief)
3) Add tests to lock behavior:
   - `bilu board --help` exits `0`
   - unknown flag exits `2`
   - `--filter` without value exits `2`
   - `--filter=status` without filter-value exits `2`
   - `-l -f status -fv todo` works
   - `--` stops parsing
4) Keep parsing “boring and explicit”:
   - manual `while/case` loop only (per research note)
   - explicitly handle `--flag=*` forms and value-consuming forms
   - no `getopts` for long options

## Acceptance checks

- Contract is documented and matches implementation.
- Tests cover aliases and error cases and pass consistently.

## References

- `src/board/tasks/00-03-cli-surface-and-aliases.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/cli/commands/board.sh`
- `src/docs/bilu-cli.md`
