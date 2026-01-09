# Phase 6 — Testing and docs

## Tests (shell)

Keep tests focused on non-interactive outputs:
- Filtering works (status filter returns only matching).
- Normalization works (`Done` → `DONE`, `High` → `HIGH`).
- `--validate` returns non-zero on broken data.

Avoid testing full-screen TUI behavior in automated tests.

## Documentation checklist

- Update `src/docs/bilu-cli.md`:
  - add `bilu board` usage examples
  - list key flags and aliases
  - mention `--tui` mode and keybindings
- Keep `src/docs/README.md` as the index of docs.

## Phase 06 tasks

See `src/docs/phases/tasks/` for Phase 06 tasks.
