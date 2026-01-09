# Docs

This folder documents the `bilu` project and its CLI/board UX.

## Contents

- `.bilu/cli/bilu-cli.md`: CLI usage and installation notes.
- `.bilu/board/phases/00-board-ui-overview.md`: Overall plan for the shell-only board UI.
- `.bilu/board/phases/01-data-contract.md`: Board data model, normalization rules, and precedence.
- `.bilu/board/phases/02-cli-and-modules.md`: Shell module layout for `bilu board` and argument parsing.
- `.bilu/board/phases/03-rendering-table-and-kanban.md`: Non-interactive renderers (table + kanban).
- `.bilu/board/phases/04-interactive-tui.md`: Interactive keyboard-driven TUI design (shell only).
- `.bilu/board/phases/05-persistence-and-editing.md`: How edits are persisted safely to disk.
- `.bilu/board/phases/06-testing-and-docs.md`: Test strategy and documentation checklist.

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rtfa1/bilu/refs/heads/main/scripts/install.sh)"
