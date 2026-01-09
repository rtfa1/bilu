---
name: task-executer
description: Execute tasks from the bilu board (.bilu/board/tasks + .bilu/board/default.json), following the embedded implementation plan and keeping the board status updated.
metadata:
  short-description: Execute tasks from board located in .bilu/board/default.json
---

# Task Executer (bilu board)

## Goal

Execute a specific bilu “board task” end-to-end using the task markdown as the source of truth for requirements and the embedded “Implementation plan” section as the procedure.

Board tasks live as Markdown files under:
- `.bilu/board/tasks/*.md`

The board index is:
- `.bilu/board/default.json`

## When to use

Use this skill whenever the user asks to “do task X” or “execute the next task” using the project’s board/tasks system, or when the user asks you to find a task to work on.

Do not use it for unrelated quick edits unless the user explicitly ties them to a board task.

## Workflow

### 1) Identify the task

Pick the task by one of:
- direct path: `.bilu/board/tasks/<id>-<slug>.md`
- title/link from `.bilu/board/default.json` (match on `"link"`)

If ambiguous, ask the user which task to execute.

### 2) Read the task file first

Open the task markdown and treat it as the authoritative spec.

Minimum sections to review:
- Goal
- Checklist
- Acceptance
- Implementation plan (this is embedded in the same `.md` file)

If the task lacks an “Implementation plan” section, propose one (briefly) before coding.

### 3) Execute the task (follow the embedded plan)

Execute in small, verifiable steps:
- implement only what the task requires (use existing project docs/guides; do not do extra research/design at this stage)
- keep everything shell-only (POSIX `sh` for non-interactive; bash only where explicitly allowed, e.g. TUI)
- avoid runtime deps not allowed by the project (no jq/fzf/gum/dialog)
- run the relevant tests (`sh tests/run.sh`) when changes affect behavior

Testing guideline (when it will pay off):
- If the change affects CLI parsing, output format, or persistence behavior: add/update a test under `tests/` and ensure `sh tests/run.sh` covers it.
- Prefer deterministic tests: set `NO_COLOR=1`, avoid terminal-size dependence, assert on stable tokens rather than alignment.
- If the change is interactive-only (`--tui`), keep automated tests minimal and add/expand a manual checklist in the task markdown.

If you get blocked by an unknown bug or need high-signal external references:
- Use the `web-search` skill (shell-only) to find links and excerpts:
  - `sh .bilu/skills/web-search/scripts/web-search.sh "<query>"`
  - `sh .bilu/skills/web-search/scripts/web-fetch.sh "<url>"`

### 4) Update the board status (default.json)

After meaningful progress, update the corresponding entry in `default.json`:
- set `"status"` to one of the canonical values from `.bilu/board/config.json.statuses` (e.g. `TODO`, `INPROGRESS`, `DONE`, `BLOCKED`)

Guidelines:
- `TODO` → `INPROGRESS` when you start
- `INPROGRESS` → `DONE` when acceptance criteria are met
- use `BLOCKED` only with a clear blocker note (prefer adding the blocker into the task markdown)

### 5) Capture outcomes (inside the task markdown)

Append a short section to the task file (near the end):
- What changed (files/commands)
- Decisions made
- Remaining work / follow-ups (if any)

Keep it brief and specific.

## Files

- Tasks: `.bilu/board/tasks/*.md`
- Board index: `.bilu/board/default.json`
- Tag/status enums: `.bilu/board/config.json`

## Examples

- “Execute task `.bilu/board/tasks/02-04-args-parser.md` and mark it DONE in `.bilu/board/default.json`.”
- “Run the next Phase 03 task and update its status + add a short outcomes section to the task file.”
- "Find a TODO task related to shell CLI and implement it end-to-end."
