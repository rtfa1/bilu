# Phase 03 — Color theme and `NO_COLOR`

## Goal

Standardize ANSI styling so output is “beautiful” but still script-friendly and accessible.

## Checklist

- [x] Define status colors (TODO, INPROGRESS, BLOCKED, REVIEW, DONE, CANCELLED, ARCHIVED).
- [x] Define priority colors/badges (CRITICAL, HIGH, MEDIUM, LOW, TRIVIAL).
- [ ] Define styles for:
  - [ ] selected card (TUI later)
  - [x] dimmed/cancelled items
  - [x] warnings
- [x] Implement and document:
  - [x] `NO_COLOR=1` disables ANSI
  - [x] `--no-color` flag disables ANSI

## Acceptance

- Colors are consistent across table and kanban renderers and can be disabled.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Color theme and `NO_COLOR`

Task: `src/board/tasks/03-02-color-theme-and-no-color.md`

This implementation plan defines a single color/styling system shared by table and kanban renderers (and later the TUI). It is consistent with:
- `src/storage/research/shell-only-cli-advanced-notes.md` (NO_COLOR, non-TTY auto-disable, stable tests)
- `src/board/tasks/00-04-kanban-ux-requirements.md` (initial theme proposal)
- `src/board/tasks/03-01-table-view-spec.md` (colorize tokens only, don’t break alignment)

## Outcome (what “done” means)

1) A single theme is defined for statuses and priorities.
2) Color can be disabled via:
- `NO_COLOR` (env)
- `--no-color` (flag)
- non-TTY output auto-disable
3) Renderers remain alignment-stable (colors applied only to short tokens).
4) Tests can run deterministically with no ANSI sequences.

## Color policy (authoritative)

### When colors are enabled

Colors are enabled only if:
- stdout is a TTY (`[ -t 1 ]` is true)
- `NO_COLOR` is unset/empty
- `--no-color` is not passed

### When colors are disabled

Disable colors if any of:
- `NO_COLOR` is set and non-empty
- `--no-color` is passed
- stdout is not a TTY

### Output stability rule

Never rely on colors for meaning. All meanings must remain readable in plain text.

## Theme mapping (v1)

Use ANSI SGR sequences (foreground colors + optional bold/dim).

### Status colors

- `BACKLOG`: dim
- `TODO`: yellow
- `INPROGRESS`: blue
- `BLOCKED`: red
- `REVIEW`: magenta
- `DONE`: green
- `ARCHIVED`: dim
- `CANCELLED`: dim

### Priority colors/badges

- `CRITICAL`: red + bold
- `HIGH`: yellow (or red if you prefer stronger emphasis)
- `MEDIUM`: yellow (non-bold)
- `LOW`: cyan/blue
- `TRIVIAL`: dim

### Other styles

- Selected card (TUI later): inverse video (SGR 7) or bold + border emphasis.
- Warnings: yellow “warn:” prefix (stderr).
- Errors: red “error:” prefix (stderr).

## Where theme lives (single source of truth)

Create a shared module:
- `src/cli/commands/board/ui/ansi.sh`

Responsibilities:
- detect whether color is enabled
- expose helpers for applying style to tokens:
  - `style_status "$STATUS"`
  - `style_priority "$PRIORITY"`
  - `style_dim "$text"`
  - `style_warn_prefix`, `style_error_prefix` (optional)

Implementation constraints:
- POSIX `sh` compatible.
- Do not call `tput` in hot paths.

## How to apply color without breaking alignment

Rule:
- Apply color to the token, then pad/truncate based on the *plain* token width.

Practical approach:
- Renderers keep alignment using plain strings, then wrap the token in ANSI if enabled.
- Avoid coloring entire lines.

## CLI flag integration

Add `--no-color` to the board args parser (Phase 02-04) once implemented.

Optional (later):
- `--color` to override NO_COLOR (only if you really need it; keep v1 simple).

## Tests (must be stable)

Add/extend tests:
- With `NO_COLOR=1`, assert output contains no escape sequences:
  - match: `\033[` should not appear (basic grep check).
- With color enabled (optional manual check), ensure output still includes plain tokens.

Recommendation:
- Keep automated tests running with `NO_COLOR=1` by default.

## Acceptance checks

- Theme mapping exists in one module and is reused by table + kanban renderers.
- `NO_COLOR`, `--no-color`, and non-TTY auto-disable behave as specified.
- Rendered output remains aligned when colors are on or off.

## References

- `src/board/tasks/03-02-color-theme-and-no-color.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/tasks/00-04-kanban-ux-requirements.md`
- `src/board/tasks/03-01-table-view-spec.md`

# Description
Standardize ANSI styling for table and kanban output: define status/priority colors, selected/dimmed/warning styles, and ensure NO_COLOR=1 and --no-color reliably disable escapes for script-friendly output.
# Status
DONE
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

---

## Outcomes

- Added a shared ANSI theme module at `.bilu/cli/commands/board/ui/ansi.sh` (status/priority mappings, `NO_COLOR`, `--no-color`, and non-TTY auto-disable).
- Applied token-only styling in `.bilu/cli/commands/board/render/{table.sh,kanban.sh}` without breaking alignment.
- Documented `--no-color` in `.bilu/cli/commands/board.sh` and `.bilu/cli/bilu-cli.md`; updated stderr warn/error prefixes in `.bilu/cli/commands/board/lib/log.sh`.
- Extended `tests/board.test.sh` to assert stable, ANSI-free output in non-TTY and `NO_COLOR=1` runs.
