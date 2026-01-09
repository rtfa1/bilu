# Phase 00 — Scope and constraints

## Goal

Lock the project constraints and define what “shell-only board UI” means for this repo.

## Decisions

- Interactive UI is allowed to use `bash` (still shell-only).
- Non-interactive commands remain POSIX `sh`.
- No required third-party dependencies (no `fzf`, `gum`, `dialog`, `jq`).
- Must work in both layouts:
  - repo layout: `src/board/...`
  - installed layout: `.bilu/board/...`

## Checklist

- [x] Confirm the minimum supported shells for each mode (POSIX `sh` for non-interactive; `bash` for `--tui`).
- [x] Confirm supported platforms (macOS/Linux/WSL) and any terminal assumptions (VT100 escapes).
- [x] Confirm required environment variables (`NO_COLOR`, `$EDITOR`) and default behavior when absent.
- [x] Confirm “no network” runtime requirement (UI must not fetch anything).

## Acceptance

- A short summary of constraints is agreed and won’t change during implementation.
- Canonical policy lives in `.bilu/board/phases/00-board-ui-overview.md` under “Constraints”.

## Work done

- Locked constraints policy in `.bilu/board/phases/00-board-ui-overview.md` (shell split, runtime deps, platforms/terminal assumptions, env vars, and no-network runtime).

## References

- `.bilu/board/phases/00-board-ui-overview.md`

---

## Implementation plan

# Phase 00 Task Implementation Plan — Scope and constraints

Task: `src/board/tasks/00-01-scope-and-constraints.md`

This implementation plan turns the Phase 00 “scope and constraints” checklist into concrete repo policies and acceptance checks, using guidance from `src/storage/research/shell-only-cli-advanced-notes.md`.

## Outcome (what “done” means)

A short, stable, repo-wide constraints policy exists and is referenced by the board implementation. The policy is specific enough that future work can’t accidentally introduce runtime dependencies or portability regressions.

## Decisions to lock (write these down explicitly)

### 1) Runtime dependencies

- Runtime dependency policy: **no required third-party deps**.
  - Disallow at runtime: `jq`, `fzf`, `gum`, `dialog`, `whiptail`, etc.
  - Allowed runtime baseline: POSIX shell + common Unix tools (`awk`, `sed`, `sort`, `cut`, `printf`, `stty`, `date`, `mktemp`).
- Optional runtime helpers (if allowed): decide now whether `python3` is permitted as an *optional* JSON parser fallback.
  - If allowed, document: “use `python3` when present; fall back gracefully when absent”.

### 2) Shell versions and where each is allowed

- Non-interactive commands (including `bilu board --list`, `--view=kanban`, `--validate`): **POSIX `sh` only**.
  - Avoid bashisms here.
  - Avoid reliance on `pipefail` and subtle `set -e` behavior; use explicit error checks.
- Interactive mode (`bilu board --tui`): **`bash` allowed**.
  - Avoid bash 4+ features unless you commit to requiring them; assume macOS may ship older bash.
  - Prefer simple arrays and string parsing over associative arrays.

### 3) Platforms + terminal assumptions

- Supported platforms (minimum): macOS + Linux (and WSL if desired).
- Terminal features assumed:
  - VT100-compatible ANSI escape sequences
  - alternate screen buffer support (`\e[?1049h`/`\e[?1049l`)
- Portability guardrails (important for macOS vs GNU):
  - avoid `grep -P`, `sed -r`, GNU-only flags
  - favor `awk` for structured parsing

### 4) “No network” at runtime

- Runtime network policy: the board UI does not call out to the network (no `curl`, no remote reads).
- Any “research” or inspiration is docs-only and not part of runtime behavior.

### 5) Environment variables and defaults

- `NO_COLOR` support:
  - If `NO_COLOR` is set and non-empty, disable ANSI color by default.
  - Add `--no-color` flag which always disables colors.
  - Auto-disable colors when stdout is not a TTY (`[ -t 1 ]` false).
- `$EDITOR` support:
  - If set: use it to open task files.
  - If not: fallback to `less` if available, else `more`.

## Implementation steps (what to do in the repo)

1) Add a single “constraints policy” section to docs:
   - Preferred location: `src/board/phases/00-board-ui-overview.md` (or `src/docs/README.md`), with bullet-point non-negotiables.
2) Ensure all phase docs reference the same constraints (no drift):
   - `00-board-ui-overview.md` is the canonical source; other docs link to it.
3) Add explicit “allowed tools” and “forbidden runtime deps” list:
   - Keep it short; link to the research note for rationale.
4) Decide and document the JSON strategy now:
   - Prefer the research recommendation: avoid runtime JSON parsing in shell when possible.
   - If JSON must be read at runtime, explicitly document whether `python3` is allowed as an optional helper or whether the schema-specific `awk` approach is the committed path.
5) Add acceptance checks that can be enforced:
   - Tests run with `NO_COLOR=1` for stable output assertions.
   - CI/dev tooling policy (if you adopt it): ShellCheck + shfmt are allowed as *dev-only* tools (not runtime deps).

## Acceptance checks (how to verify this task is done)

- The constraints policy is documented in one canonical place and linked from the Phase 00 task.
- The policy explicitly answers:
  - which shells are required where (POSIX `sh` vs `bash`)
  - platforms supported
  - terminal assumptions (ANSI/VT100)
  - runtime no-network
  - NO_COLOR and `$EDITOR` behavior
  - JSON strategy decision (and whether optional `python3` is allowed)

## Inputs used

- `src/board/phases/00-board-ui-overview.md`
- `src/board/tasks/00-01-scope-and-constraints.md`
- `src/storage/research/shell-only-cli-advanced-notes.md`
