# bilu CLI

See `src/docs/README.md` for the docs index.

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

- `sh src/cli/bilu init`

After install:

- `./bilu help` (or `./.bilu/cli/bilu help`)
