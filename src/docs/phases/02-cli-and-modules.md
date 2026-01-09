# Phase 2 — CLI and modules

This phase restructures `bilu board` into a small shell “module” with clear responsibilities.

## Folder layout

- `src/cli/commands/board.sh`: entrypoint for `bilu board` (dispatch only).
- `src/cli/commands/board/`
  - `paths.sh`: locate board root in repo vs installed layout.
  - `args.sh`: parse flags, support short/long aliases.
  - `load_config.sh`: read config (`config.json`) into shell-friendly maps.
  - `load_tasks_json.sh`: read index (`default.json`).
  - `load_tasks_md.sh`: parse markdown sections.
  - `normalize.sh`: produce stable internal TSV records.
  - `render/table.sh`: non-interactive list/table.
  - `render/kanban.sh`: non-interactive kanban.
  - `render/tui.sh`: interactive (keyboard) UI.
  - `actions/*.sh`: edit/status changes, open in editor, rebuild index.

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

See `src/docs/phases/tasks/` for Phase 02 tasks.

