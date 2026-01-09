# Phase 2 — CLI and modules

This phase restructures `bilu board` into a small shell “module” with clear responsibilities.

## Folder layout

- `src/cli/commands/board.sh`: entrypoint for `bilu board` (dispatch only).
- `src/cli/commands/board/`
  - `paths.sh`: locate board root in repo vs installed layout.
  - `args.sh`: parse flags, support short/long aliases.
  - `normalize.sh`: normalize enums + enforce internal TSV escaping.
  - `load/`
    - `config.sh`: load `config.json` into shell-friendly values.
    - `tasks_md.sh`: parse `tasks/*.md` into normalized TSV records.
    - `tasks_index.sh`: read `default.json` (if used as input).
  - `render/`
    - `table.sh`: non-interactive list/table.
    - `kanban.sh`: non-interactive kanban.
    - `tui.sh`: interactive (keyboard) UI (bash only).
  - `actions/`
    - `open.sh`: open a task file in `$EDITOR` or pager.
    - `set_status.sh`: edit task status safely (temp + atomic mv).
    - `set_priority.sh`: edit task priority safely.
    - `rebuild_index.sh`: rebuild derived artifacts (`default.json`, compiled TSV).
  - `ui/`
    - `ansi.sh`: color/styling helpers; `NO_COLOR` support.
    - `layout.sh`: width/wrapping helpers shared by renderers.
  - `lib/`
    - `log.sh`: `die`/`warn`/`info`, consistent exit codes.
    - `lock.sh`: optional mkdir-based locking for edit actions.

## CLI surface (proposed)

- `bilu board --list` / `-l`
- `bilu board --list --filter status --filter-value TODO`
  - aliases: `--filter/-f`, `--filter-value/-fv`
- `bilu board --list --search "text"`
- `bilu board --list --sort priority --order desc`
- `bilu board --list --view table|kanban`
- `bilu board --tui`
- `bilu board --validate`

## Parsing rules

- Support both:
  - `--flag value`
  - `--flag=value`
- Reject unknown options with exit code `2` and show usage.
- Do not accept positional args unless explicitly defined.

## Phase 02 tasks

See `.bilu/board/tasks/` for Phase 02 tasks.
