# Product Requirements Document (PRD)

Project: **bilu** (shell-only CLI + board UX)

Last updated: 2026-01-10

## 1) Summary

`bilu` is a lightweight, shell-first CLI that installs a project-local `.bilu/` folder and provides “board” utilities for managing tasks stored as Markdown files.

Core design:

- **Source of truth:** `.bilu/board/tasks/*.md` (human-editable, diff-friendly)
- **Derived index:** `.bilu/board/default.json` (regeneratable)
- **Config/schema:** `.bilu/board/config.json`
- **Render pipeline:** normalize task data into **TSV v1** records; renderers consume TSV.

This PRD defines the product contract for the CLI, the board data model, the TUI, persistence rules, and acceptance criteria.

## 2) Goals

- Provide a **portable**, maintainable board CLI with **no required third-party runtime dependencies**.
- Use **POSIX `sh`** for non-interactive commands; allow **`bash` for the interactive TUI**.
- Make board operations safe and predictable:
  - strict CLI parsing
  - stable exit codes
  - deterministic rebuild/migration
  - atomic file writes
  - concurrent edit locking
- Keep rendering fast by using `awk` for transforms and producing output in a small number of writes.

## 3) Non-goals

- No required tools like `jq`, `fzf`, `gum`, `dialog`, `whiptail`.
- No general-purpose JSON parser implemented in shell.
- No always-on daemon, DB, or server.
- No guarantee that `default.json` stays in sync automatically after arbitrary Markdown edits; explicit rebuild is the supported workflow.

## 4) Users & use cases

Primary users:

- Developers managing tasks locally inside a repo.
- Maintainers who want a testable, dependency-light shell CLI.

Use cases:

- Install `.bilu/` into a project and start using `bilu`.
- List tasks in table or kanban format, optionally filtering.
- Validate configuration and board data.
- Migrate tasks to canonical metadata sections.
- Rebuild the derived JSON index from Markdown.
- Use a TUI to browse/search/filter/sort and edit status/priority.

## 5) Constraints & guardrails (shell-only)

Runtime constraints:

- Non-interactive: POSIX `sh`
- TUI: `bash` (arrays and key decoding)
- Assume base tools: `awk`, `sed`, `tr`, `sort`, `grep`, `stty`, `mktemp`.

Portability constraints:

- Avoid GNU-only flags (`grep -P`, `sed -r`, etc.).
- Behave consistently on macOS and Linux.

## 6) Success criteria

- `bilu init` installs `.bilu/` in a new directory and refuses to overwrite.
- `bilu board --list` works in default table view and kanban view.
- `NO_COLOR=1` and `--no-color` produce no ANSI escape codes.
- `bilu board --validate` returns `ok` on success and exits `1` on fatal validation errors.
- `bilu board --migrate` and `--rebuild-index` work deterministically and support `--dry-run`.
- Editing commands (`--set-status`, `--set-priority`) update only the intended section and write atomically.
- All behavior is covered by repo shell tests.

## 7) Exit codes (contract)

- `0`: success
- `1`: runtime/data/config failure
- `2`: usage error (invalid flags, bad combos, missing required args)

## 8) Data model

### 8.1 Board files

- `.bilu/board/config.json` — canonical sets and UI defaults
- `.bilu/board/default.json` — derived task index (regeneratable)
- `.bilu/board/tasks/*.md` — source-of-truth task documents

### 8.2 Task Markdown canonical metadata sections

Each task Markdown must contain (or be made to contain via `--migrate`) these headers and values:

- `# Description` (single-line summary text; may be empty)
- `# Status` (single line)
- `# Priority` (single line)
- `# Kind` (single line)
- `# Tags` (0+ lines like `- frontend`)
- `# depends_on` (0+ lines like `- board/tasks/xx.md` or IDs per repo convention)

Edits performed by the CLI operate on these sections.

### 8.3 Normalization rules

- **Status**: normalize common variants (e.g. `Done`, `in-progress`) to canonical values.
- **Priority**: case-insensitive normalization to canonical values.
- **Kind**: normalize to canonical values (default: `task|bug|feature|improvement`).
- **Tags**: warn on unknown tags but preserve them.
- **Invalid values**: do not crash; warn and fall back to safe defaults.

### 8.4 Internal record format: TSV v1

All renderers and TUI loaders operate on TSV records with **exactly 10 fields**:

1. `id`
2. `status`
3. `priority_weight`
4. `priority`
5. `kind`
6. `title`
7. `path` (absolute filesystem path)
8. `tags_csv` (comma-separated)
9. `depends_csv` (comma-separated)
10. `link` (relative, e.g. `board/tasks/<id>.md`)

TSV escaping rules:

- Fields must not contain literal tab or newline characters.
- Free-text fields are normalized by replacing `\t`, `\r`, `\n` with spaces.

## 9) CLI surface

### 9.1 `bilu` top-level commands

- `bilu init` — install `.bilu/` into the current directory
- `bilu board ...` — board utilities
- `bilu version` — print version
- `bilu help` — print help

### 9.2 `bilu init`

Requirements:

- Creates `./.bilu/` in the current directory.
- Copies bundled template directories: `board/`, `prompts/`, `skills/`, `cli/`.
- Refuses to overwrite if `./.bilu` exists (exit `2`).
- Writes `./.bilu/storage/config.json` marking install time.

### 9.3 `bilu board` actions

Exactly one action must be selected:

- `--list` (`-l`)
- `--tui` (interactive full-screen; bash)
- `--validate`
- `--migrate [--dry-run]`
- `--rebuild-index [--dry-run]`
- `--set-status <task-id> <status>`
- `--set-priority <task-id> <priority>`

Options:

- `--view <table|kanban>` (valid only with `--list`)
- `--filter <name>` / `--filter-value <value>` (valid only with `--list`; must be provided together)
- `--no-color` (also respects `NO_COLOR`)
- `--dry-run` (valid only with `--migrate` and `--rebuild-index`)
- `--` end-of-options

Parser requirements:

- Support `--flag value` and `--flag=value`.
- Support short aliases: `-l`, `-h`, `-f`, `-fv`.
- Reject unknown options and unexpected positionals with exit `2`.
- Reject invalid combinations with exit `2`:
  - `--view` without `--list`
  - `--filter`/`--filter-value` without `--list`
  - `--filter` without `--filter-value` (and vice versa)
  - multiple `--filter` or `--filter-value` values
  - multiple actions at once

### 9.4 Listing & filtering

`bilu board --list` renders normalized TSV records.

Views:

- `table` (default): header + aligned columns sized using `COLUMNS`.
- `kanban`: 4 columns when wide enough; narrow stacked output when terminal is narrow.

Filters (v1):

- `status` (case-insensitive)
- `priority` (case-insensitive)
- `kind` (case-insensitive)

## 10) Color & NO_COLOR

Requirements:

- ANSI color output is enabled only when stdout is a TTY.
- If `NO_COLOR` is set and non-empty, do not emit ANSI.
- If `--no-color` is provided, do not emit ANSI.

Testing requirement:

- Render outputs must contain no SGR escapes when `NO_COLOR=1`.

## 11) Validation

`bilu board --validate` requirements:

- Validate `config.json` presence and required top-level keys (`statuses`, `priorities`, `kind`; warn if `tags` missing).
- Validate uniqueness of numeric map values for `statuses` and `priorities`.
- Validate index entries have required fields.
- Validate normalization for status/priority/kind does not crash.
- Validate depends_on targets exist in the index (warn if missing).
- Validate TSV invariants:
  - exactly 10 fields
  - required fields non-empty

Output contract:

- On success: first line is `ok` (and may include summary lines like `tasks: N`).
- On fatal error: exit `1` and print errors to stderr; stdout must not contain `ok`.

## 12) Migration and rebuild

### 12.1 `bilu board --migrate [--dry-run]`

- Reads `default.json` and updates each task Markdown to ensure canonical metadata sections exist and are normalized.
- Must be deterministic.
- `--dry-run` prints success summary without writing.

### 12.2 `bilu board --rebuild-index [--dry-run]`

- Reads task Markdown canonical metadata sections and regenerates `default.json` deterministically.
- Must be deterministic and stable under repeated runs.
- `--dry-run` reports whether the output would change.

## 13) Persistence & concurrency

Editing requirements:

- `--set-status` updates only the value under `# Status`.
- `--set-priority` updates only the value under `# Priority`.
- Writes must be atomic: temp file + `mv`.

Locking requirements:

- Use a mkdir-based lock under `.bilu/storage/lock`.
- Lock acquisition has a bounded wait/timeout and emits actionable errors.

## 14) Interactive TUI (`bilu board --tui`)

Implementation:

- `bash` is required/allowed.

Requirements:

- Full-screen mode with cleanup on exit (restore terminal state via traps).
- Handle window resize (WINCH) and redraw.
- Render using a framebuffer approach (compose string, print once per frame).

Keybindings (baseline):

- `q`: quit
- `?`: toggle help overlay
- arrow keys or `h/j/k/l`: navigate
- `Enter` / `e`: open task
- `S`: cycle status
- `P`: cycle priority
- `/`: search
- `f`: filter
- `s`: sort
- `a`: clear filter/search/sort
- `r`: refresh from disk

## 15) Installation (curl | bash)

Requirements:

- Install script downloads a source archive (no `git` required).
- Copies `.bilu/{board,prompts,skills,cli}` into a target directory (default: `./.bilu`).
- Creates an executable shortcut script (default: `./bilu`) forwarding to `.bilu/cli/bilu`.
- Refuses to overwrite existing install target (exit `2`).

## 16) Test matrix (acceptance)

Acceptance is validated by shell tests that cover:

- init behavior (create and refuse overwrite)
- board listing in both views
- NO_COLOR and `--no-color`
- CLI parsing errors (exit `2`)
- validation success/failure cases
- TSV invariants
- persistence edits for status/priority

## 17) Future improvements (optional)

- Richer filtering (tags) and multi-filter composition.
- Optional “auto rebuild index” toggle after edits.
Product Requirements Document