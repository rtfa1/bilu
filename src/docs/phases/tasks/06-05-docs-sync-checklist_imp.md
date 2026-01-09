# Phase 06 Task Implementation Plan — Docs sync checklist

Task: `src/docs/phases/tasks/06-05-docs-sync-checklist.md`

This plan defines a lightweight, repeatable “docs stay true” process for the project. The goal is that `src/docs/` remains the primary user/developer guide as the CLI evolves, without adding runtime dependencies.

## Outcome (what “done” means)

1) Docs are structured, discoverable, and consistent:
- `src/docs/README.md` is the index.
- each phase doc links to its tasks.
2) `src/docs/bilu-cli.md` reflects actual CLI behavior (commands, flags, aliases).
3) A simple checklist exists for every meaningful CLI change to keep docs in sync.

## Authoritative sources + sync rules

Rules:
- Command behavior is authoritative in code, but documentation must match the implemented behavior at release time.
- Task/phase docs define intended behavior; if code diverges, update either the code or the docs intentionally (never “accidentally stale”).

Recommended “single source” policy for CLI surface:
- Treat `bilu --help` and `bilu board --help` output as the canonical contract.
- Ensure docs mirror help text and examples.

## Checklist to run when changing CLI behavior

When you add/change any command/flag/output:

1) Update help text:
- `src/cli/bilu` usage (global)
- `src/cli/commands/board.sh` usage (board module)

2) Update user docs:
- `src/docs/bilu-cli.md`:
  - install flow
  - `bilu board` examples
  - flags/aliases (including short forms like `-l`, `-f`, `-fv`)
  - `--no-color` / `NO_COLOR` behavior (once implemented)
  - `--tui` mode + keybindings (once implemented)

3) Update phase docs as needed:
- `src/docs/phases/02-cli-and-modules.md` (command/module structure)
- `src/docs/phases/03-rendering-table-and-kanban.md` (views + rendering contracts)
- `src/docs/phases/04-interactive-tui.md` (TUI behaviors)
- `src/docs/phases/05-persistence-and-editing.md` (writes, locks, atomic edits)
- `src/docs/phases/06-testing-and-docs.md` (test policy)

4) Ensure tasks link correctly:
- each `src/docs/phases/*.md` should link to the relevant `src/docs/phases/tasks/*.md` entries

5) Run tests:
- `sh tests/run.sh`

## Minimal “docs are complete” validations

Add a simple, non-failing script (optional, dev-only) or manual checklist that verifies:
- `src/docs/README.md` lists:
  - all phase docs under `src/docs/phases/`
  - research docs under `src/docs/research/`
- every phase doc includes a “Phase NN tasks” section pointing to `src/docs/phases/tasks/`
- `src/docs/bilu-cli.md` includes examples for:
  - `bilu init`
  - `bilu run`
  - `bilu board --list` (and aliases)
  - filtering examples

If you choose to automate:
- keep it POSIX `sh`
- avoid network calls and external deps
- keep it tolerant (warn, don’t fail CI) unless you intentionally enforce strict docs checks later

## Acceptance checks

- A new contributor can navigate `src/docs/README.md` to find phases/tasks quickly.
- `src/docs/bilu-cli.md` matches actual `--help` output and examples work.
- Phase docs link to task docs consistently.

## References

- `src/docs/phases/tasks/06-05-docs-sync-checklist.md`
- `src/docs/README.md`
- `src/docs/bilu-cli.md`
- `src/docs/phases/06-testing-and-docs.md`
