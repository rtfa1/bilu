# Phase 02 Task Implementation Plan — Args parser

Task: `src/docs/phases/tasks/02-04-args-parser.md`

This implementation plan defines a robust, deterministic flag parser for `bilu board`. It follows `src/docs/research/shell-only-cli-advanced-notes.md`: avoid `getopts` for long options, parse explicitly with a `while/case` loop, support `--flag=value`, keep exit code `2` for usage errors, and ensure `-fv` works as a single token.

## Outcome (what “done” means)

1) The board parser supports exactly the required flags and syntaxes.
2) Unknown flags and malformed inputs always fail with exit code `2` and usage output.
3) Paired flags are enforced (`--filter` + `--filter-value`).
4) Tests cover the parser’s edge cases.

## Required flags (v1)

- `--help` / `-h`
- `--list` / `-l`
- `--filter` / `-f` (value required)
- `--filter-value` / `-fv` (value required)
- `--` end-of-options

## Parsing rules (authoritative)

### Accepted syntaxes

- `--flag value`
- `--flag=value`

### Aliases

- `-l` equals `--list`
- `-f` equals `--filter`
- `-fv` equals `--filter-value` (must be recognized as one token)

### Error handling

- Unknown option (`-*` not recognized): usage error (exit `2`)
- Unexpected positional argument: usage error (exit `2`)
- Missing required value (e.g. `--filter` at end): usage error (exit `2`)
- Missing action (`--list` not provided): usage error (exit `2`)
- Paired enforcement:
  - `--filter` requires `--filter-value`
  - `--filter-value` requires `--filter`

### End-of-options

If `--` is seen:
- stop option parsing
- any remaining args are treated as positional args
- for v1: positional args are not allowed → usage error (exit `2`)

## State variables (outputs of the parser)

In a module (`args.sh`) set:
- `BOARD_ACTION` (e.g. `list`)
- `BOARD_FILTER_NAME` (string or empty)
- `BOARD_FILTER_VALUE` (string or empty)

Keep these as global variables so renderers/actions can read them after parsing.

## Implementation steps

1) Move parsing into a dedicated module:
- `src/cli/commands/board/args.sh`
- `board_parse_args "$@"`

2) Keep parsing “boring and explicit”

Use:
- `while [ $# -gt 0 ]; do case "$1" in ... esac; done`
- Explicitly handle:
  - `--filter)` then consume `$2`
  - `--filter=*)`
  - `-f)` then consume `$2`
  - `-f=*)`
  - `--filter-value)` then consume `$2`
  - `--filter-value=*)`
  - `-fv)` then consume `$2`
  - `-fv=*)`

3) Standardize errors

Use shared helpers (from `lib/log.sh`):
- `usage_error "message"` should print:
  - `bilu board: <message>` to stderr
  - usage text to stderr
  - exit `2`

4) Ensure compatibility with current behavior

The existing `src/cli/commands/board.sh` already implements most of this; refactor must preserve semantics.

## Tests to add/upgrade

Update `tests/board.test.sh` to assert exit codes precisely:

- `bilu board --help` exits `0`
- `bilu board -x` exits `2` (not just non-zero)
- `bilu board --filter status` exits `2`
- `bilu board --filter-value todo` exits `2`
- `bilu board -- --list` exits `2` (positional args not allowed)
- `bilu board -l -f status -fv todo` exits `0`
- `bilu board --list --filter=status --filter-value=todo` exits `0`

Run tests with `NO_COLOR=1` for stable output.

## Acceptance checks

- Parser behavior is deterministic and matches the docs exactly.
- `-fv` is accepted as a single token and never treated as `-f -v`.
- All error cases return `2` and include usage text.

## References

- `src/docs/phases/tasks/02-04-args-parser.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
- `src/cli/commands/board.sh`
- `tests/board.test.sh`

