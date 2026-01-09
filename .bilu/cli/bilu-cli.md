# bilu CLI

See `.bilu/README.md` for the docs index.

## `bilu init`

Runs in the current folder:

- Creates `./.bilu/`.
- Copies the bundled bilu template into `./.bilu/` (`board/`, `core/`, `docs/`, `prompts/`, `skills/`, `storage/`).
- If `./.bilu` already exists, it refuses to overwrite and exits.
- Marks bilu as installed by writing `./.bilu/storage/config.json`.

## `bilu board`

Board commands (shell only):

- `bilu board --list` (`-l`)
- `bilu board --list --filter=status --filter-value=todo`
- `bilu board --list -f status -fv todo`
- `bilu board --validate`
- `bilu board --migrate [--dry-run]`
- `bilu board --rebuild-index [--dry-run]`
- `bilu board --help` (`-h`)

Data policy:

- Task metadata is sourced from `.bilu/board/tasks/*.md`; `.bilu/board/default.json` is a derived index and may be regenerated (`.bilu/board/phases/01-data-contract.md`).

Parsing:

- Render paths parse task markdown with a small `awk`-based extractor (limited headers/sections) and normalize into internal TSV records.
- Avoid runtime JSON parsing; treat JSON as derived/compiled artifacts or use tightly scoped, schema-specific `awk` extraction for small config shapes (no required external JSON parser; no required `python3`).
- Parsing details live in `.bilu/board/tasks/01-04-json-and-markdown-parsing-strategy.md`.

Contract:

- Flags must appear after `board` (e.g. `bilu board --list`).
- Exactly one `--filter` and one `--filter-value` are supported (no repeats).
- `--filter` and `--filter-value` must be provided together (usage error, exit `2`).
- Supported syntaxes: `--flag value`, `--flag=value`, and `--` to end option parsing.
- Exit codes: `0` success, `1` runtime/data/config error, `2` usage error.

## Cross-platform (macOS/Linux/Windows)

This CLI is a POSIX shell script. On Windows, use a shell environment like Git Bash, MSYS2, Cygwin, or WSL.

## Install script (curl | bash)

Example (replace `<owner>/<repo>` and `main`):

- `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install.sh)"`
  - Creates `./.bilu/` in the current directory
  - Installs the CLI at `./.bilu/cli/bilu`
  - Creates a shortcut `./bilu` that runs `./.bilu/cli/bilu`
  - Downloads a source tarball (no `git` required)

Local dev (from this repo):

- `sh .bilu/cli/bilu init`

After install:

- `./bilu help` (or `./.bilu/cli/bilu help`)
