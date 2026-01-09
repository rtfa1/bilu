# Phase 03 — Renderer performance rules

## Goal

Keep rendering snappy in shell.

## Checklist

- [ ] Avoid calling `tput` repeatedly per cell/card.
- [ ] Prefer building one output buffer per frame and printing once.
- [ ] Cache terminal size and only recalc on resize (TUI later).
- [ ] Avoid external processes inside hot loops where possible.

## Acceptance

- Rendering is fast enough for 100+ tasks without visible lag.
---

## Implementation plan

# Phase 03 Task Implementation Plan — Renderer performance rules

Task: `src/board/tasks/03-06-renderer-performance.md`

This implementation plan turns the performance checklist into concrete engineering rules for shell renderers (table + kanban now, TUI later). It aligns with `src/storage/research/shell-only-cli-advanced-notes.md` and the kanban algorithm plan: avoid `tput` in hot loops, minimize external processes, and build output buffers.

## Outcome (what “done” means)

1) Table and kanban renderers are fast and do not visibly lag at 100+ tasks.
2) Rendering code follows a set of performance rules that are testable and reviewable.
3) The TUI design remains compatible with these rules (framebuffer redraw).

## Performance rules (authoritative)

### 1) Avoid `tput` in hot paths

- Do not call `tput` per row/card/cell.
- Prefer raw ANSI escapes (when needed) or plain text output.

Non-interactive renderers should avoid cursor movement entirely.

### 2) Minimize subprocesses inside loops

- Avoid calling external commands inside a per-task loop (e.g. `basename`, `cut`, `sed`, `awk` repeatedly).
- Prefer:
  - a single `awk` pass that formats all lines, or
  - precomputing derived fields once before rendering.

### 3) Build output in chunks

- For non-interactive table/kanban:
  - build a large output buffer (string) and print once, or
  - print per “section” (e.g. header + all rows) rather than per character.

### 4) Cache terminal size (where applicable)

- Non-interactive `--view=kanban`:
  - compute terminal width once per invocation via `stty size`.
- Interactive TUI (later):
  - compute size once and update only on `WINCH`.

### 5) Prefer `awk` as the compute engine

For POSIX `sh` renderers:
- feed normalized TSV to `awk -F '\t'` for:
  - alignment
  - truncation
  - grouping/splitting tags

This reduces shell string manipulation overhead and improves portability.

### 6) Keep data flow simple: TSV in, text out

- Renderers should consume normalized TSV v1 only (Phase 02-06).
- No JSON parsing in renderers.
- No markdown parsing in renderers.

## “Fast enough” definition (practical)

In shell projects, “fast enough” is “no visible lag”:
- table view prints instantly for 100 tasks
- kanban view prints quickly enough that it doesn’t feel like it’s “drawing”

If you want an explicit target:
- under ~100ms for 100 tasks on a typical laptop terminal

(This can be measured later, but not required for the initial spec.)

## Implementation guidance (how to follow the rules)

### Table renderer

- One `awk` pass:
  - compute display columns
  - truncate tokens
  - apply optional ANSI to small tokens only

### Kanban renderer

- Group tasks once (awk or shell arrays precomputed).
- Pre-render each card into lines once per task.
- Print per-row (card index) to avoid complex cursor control.

### Shared helpers

- Put ANSI enable/disable in `ui/ansi.sh` so you don’t repeat checks.
- Put width/truncation helpers in `ui/layout.sh` if needed (but keep them small).

## Review checklist (what reviewers should look for)

- No `tput` in render loops.
- No external commands inside per-task loops.
- Normalized TSV is the only renderer input.
- Any width calculations happen once per invocation.

## Acceptance checks

- A code review can confirm the above rules are followed.
- Manual run with an artificially duplicated task list still feels responsive.

## References

- `src/board/tasks/03-06-renderer-performance.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
- `src/board/tasks/03-03-kanban-layout-algorithm.md`
- `src/board/tasks/02-06-internal-record-format.md`

## Outcomes

- Updated the non-interactive kanban renderer to stream lines directly from `awk` (avoid building a huge concatenated output buffer in memory).
- Confirmed renderers avoid `tput` in hot paths and avoid subprocesses inside per-task loops.
- Tests: `sh bilu/tests/run.sh`

# Description
Define performance rules for shell renderers: avoid per-cell tput calls, build one output buffer per frame, cache terminal size, and minimize external processes in hot loops so 100+ tasks render without lag.
# Status
DONE
# Priority
MEDIUM
# Kind
task
# Tags
- design
- frontend
- performance
- planning
- usability
# depends_on
