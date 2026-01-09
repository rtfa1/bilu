# Board UI (Shell-only) — Overview

Goal: a beautiful, keyboard-driven board viewer/editor in the terminal, implemented using shell scripts only.

## Constraints

- Shell-only:
  - Non-interactive commands: **POSIX `sh`** (no bashisms).
  - Interactive mode (`--tui`): **`bash` allowed** (assume macOS default bash is OK; avoid bash 4+ only features).
- Runtime deps:
  - No required third-party dependencies (no `fzf`, `gum`, `dialog`, `jq`, etc).
  - OK baseline: POSIX shell + common Unix tools (`awk`, `sed`, `sort`, `cut`, `printf`, `stty`, `date`, `mktemp`).
  - If JSON must be parsed at runtime, prefer schema-specific parsing; `python3` may be used only as an optional helper when present (never required).
- Platforms: macOS and Linux (WSL is supported when the same assumptions hold).
- Terminal assumptions:
  - VT100/ANSI escape sequences available.
  - Interactive mode may use alternate screen (`\\e[?1049h` / `\\e[?1049l`).
  - Must not rely on GNU-only flags (`grep -P`, `sed -r`, etc).
- Environment:
  - `NO_COLOR` disables ANSI color when set and non-empty (and `--no-color` forces it off).
  - If stdout is not a TTY, default to no color.
  - `$EDITOR` is used for “open in editor”; if unset, fall back to `less` when available, else `more`.
- Network: no network access at runtime (no `curl`, remote reads, or fetches).
- Layouts: must work both from repo layout (`src/board/...`) and installed layout (`.bilu/board/...`).

## Inputs (current repo state)

- `src/board/config.json`: enums and UI defaults (status order, priorities, labels).
- `src/board/default.json`: task index (task cards with `title`, `status`, `priority`, etc).
- `src/board/tasks/*.md`: task detail files (human readable, editable).

## Outputs (CLI)

- `bilu board --list` (table output)
- `bilu board --list --view=kanban` (non-interactive kanban)
- `bilu board --tui` (interactive UI)

## Phases

1. Define data contract + normalization (`01-data-contract.md`)
2. Modularize `bilu board` (`02-cli-and-modules.md`)
3. Table + kanban renderers (`03-rendering-table-and-kanban.md`)
4. Interactive TUI (`04-interactive-tui.md`)
5. Persistence/editing (`05-persistence-and-editing.md`)
6. Tests + documentation (`06-testing-and-docs.md`)

## Phase 00 tasks

See `src/board/tasks/` for Phase 00 planning tasks.
