# Phase 02 — Module skeleton

## Goal

Create the module directory structure under `src/cli/commands/board/` and wire imports in a consistent way.

## Checklist

- [ ] Create module directories:
  - [ ] `src/cli/commands/board/`
  - [ ] `src/cli/commands/board/render/`
  - [ ] `src/cli/commands/board/actions/`
  - [ ] `src/cli/commands/board/ui/`
- [ ] Add placeholder modules with clear interfaces:
  - [ ] `paths.sh`, `args.sh`, `normalize.sh`
  - [ ] `load_config.sh`, `load_tasks_json.sh`, `load_tasks_md.sh`
- [ ] Decide module sourcing convention:
  - [ ] `SCRIPT_DIR` + `. "$SCRIPT_DIR/..."` includes
  - [ ] no reliance on `$PWD`

## Acceptance

- `board.sh` can source modules reliably from any working directory.

