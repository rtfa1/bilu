---
name: task-creator
description: Create and maintain one Markdown task file per task under docs/tasks/ (research/implementation/fix), with clear scope, acceptance criteria, and status updates.
metadata:
  short-description: Create tasks as docs/tasks/*.md
---

# Task Creator

## Goal

Every time work needs to be done, create (or update) a single task file so the work can be executed, tracked, and handed off to another agent.

Tasks are Markdown files, one per task, stored in `docs/tasks/`.

## When to use

Use this skill whenever the agent is about to:
- Start meaningful work (research, design, implementation, refactor, bugfix)
- Split work into multiple steps
- Hand off work to another agent

Do **not** create a task for tiny edits (e.g., “fix a typo”) unless the user asks.

## Workflow

### 1) Decide whether to create a new task or update an existing one

- If the user references an existing task file, update that file.
- If no task exists yet, create a new one.
- Prefer splitting into multiple tasks only when truly parallelizable or separately deliverable (usually 1–5 tasks).

### 2) Create the task file

Create a new Markdown file in `docs/tasks/` using the template in `assets/task-template.md`.

**File naming**

Use a stable, sortable name:
- `docs/tasks/YYYYMMDD-<slug>.md` (default), or
- `docs/tasks/<slug>.md` (if the repo already uses non-dated slugs)

Slug rules: lowercase, hyphens, no special characters.

### 3) Keep task state updated as you work

Whenever work progresses, update the same task file:
- Set `status` to `in_progress` when starting
- Add findings, decisions, links, and artifacts as you go
- Mark `done` when complete, and record what changed

### 4) If delegating, write a handoff block

If another agent will pick it up, add a short “Handoff” section:
- Current state
- What’s left
- Exact commands/files to touch
- Known gotchas

## Task content rules

- Scope is explicit and bounded.
- Acceptance criteria are checkable.
- Dependencies and blockers are listed.
- If it’s a research task, include concrete questions + sources/queries to check.
- If it’s an implementation task, include files likely to be touched and a minimal test plan.

## Files

- Tasks live in `docs/tasks/`.
- Only create additional files if the user asks or the task requires it.

## Examples

- “Use `task-creator`: create a task to do technical research on CRDT libraries for a local-first app.”
- “Use `task-creator`: create 3 tasks (research, prototype, evaluation) for adding OIDC login.”
- “Use `task-creator`: update `docs/tasks/20260108-crdt-research.md` with progress and next steps.”
