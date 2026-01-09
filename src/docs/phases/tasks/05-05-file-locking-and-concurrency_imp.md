# Phase 05 Task Implementation Plan — File locking and concurrency

Task: `src/docs/phases/tasks/05-05-file-locking-and-concurrency.md`

This plan defines a simple, portable lock strategy to prevent concurrent commands from corrupting files. It follows the guidance in `src/docs/research/shell-only-cli-advanced-notes.md`: use mkdir-based locks, always release via `trap`, and keep writes atomic (temp file + `mv`).

## Outcome (what “done” means)

1) Editing commands and `--rebuild-index --write` are protected by a lock.
2) Lock acquisition is atomic and portable (POSIX `sh`).
3) On crash/CTRL-C, locks are released and the terminal is not left broken.
4) Stale lock handling is defined and documented.

## Lock scope (what we protect)

Lock must be held for any operation that can write:
- task markdown files (`board/tasks/*.md`)
- derived artifacts when writing (`default.json`, `board.tsv`, etc.)

Read-only commands (`--list`, `--validate`) must not require the lock.

## Lock location (authoritative)

Lock directory lives under the board installation, not `$PWD`:

- repo layout (recommended): `src/board/storage/lock`
- installed layout (recommended): `.bilu/storage/lock`

Rules:
- Lock is a directory, not a file (atomic `mkdir`).
- Ensure parent storage directory exists before acquiring.

## API (authoritative module)

Add a reusable lock helper in POSIX `sh`:
- `src/cli/commands/board/lib/lock.sh`

Functions:
- `board_lock_acquire <lock_dir> <timeout_seconds>`
- `board_lock_release <lock_dir>`

Conventions:
- If acquired, set a global flag so release is idempotent.
- Always register a `trap` in the calling command to release on `EXIT INT TERM HUP`.

Exit codes:
- `0` acquired / released
- `1` runtime error (cannot create storage dir, cannot create lock, timeout)

## Acquisition algorithm (mkdir-based)

Inputs:
- `lock_dir` (e.g. `.bilu/storage/lock`)
- `timeout_seconds` (e.g. `10`; allow `0` for “no wait”)

Algorithm:
1) Attempt `mkdir "$lock_dir"`:
   - success → lock acquired
2) If it fails because it exists:
   - if timeout is 0 → fail with a clear message and exit `1`
   - else loop with short sleeps until timeout expires
3) When acquired, write metadata inside the lock dir (best-effort, not required):
   - `pid` (current PID)
   - `ts` (epoch if available; otherwise date string)
   - `cmd` (argv summary)

Portability notes:
- Prefer `sleep 0.1` only if you can; otherwise use `sleep 1` (portable).
- Do not rely on GNU-only `stat` flags; keep stale detection simple.

## Stale lock handling (defined behavior)

Minimum viable behavior:
- If lock exists and timeout expires, error:
  - `bilu board: error: lock busy: <path>`
  - include a hint: “If you are sure no bilu process is running, remove the lock directory.”

Optional (recommended) improvement for stale locks:
- If a `pid` file exists inside the lock dir:
  - check `kill -0 "$pid" 2>/dev/null`
  - if the process is not running, treat lock as stale:
    - remove lock dir and retry acquisition

Safety rule:
- Only auto-remove stale locks when you can prove PID is dead; never remove otherwise.

## Release algorithm

Release must:
- remove metadata files (best-effort)
- remove the lock dir itself (`rmdir` preferred)
- be safe to call multiple times

Always release via `trap` in writers:
- `trap 'board_lock_release "$LOCK_DIR"' EXIT INT TERM HUP`

## Documentation requirements

Update `bilu board --help` (Phase 02-05) to document:
- which commands acquire a lock (writers only)
- lock location
- what “busy” means and how to resolve it

## Tests (non-interactive)

Add tests that simulate concurrency using background jobs:
1) Start a process that acquires the lock and sleeps.
2) In parallel, run an edit/rebuild write action with a short timeout and assert it fails with exit `1`.
3) After the first releases, rerun and assert success.

Keep tests portable:
- avoid sub-second sleeps unless necessary
- avoid external tools beyond POSIX sh + coreutils

## Acceptance checks

- Two concurrent writes do not corrupt files; the second waits (or fails) predictably.
- `CTRL-C` during a write releases the lock.
- Busy lock error message is clear and points to the lock path.
- Stale lock handling is documented (and implemented if chosen).

## References

- `src/docs/phases/tasks/05-05-file-locking-and-concurrency.md`
- `src/docs/phases/05-persistence-and-editing.md`
- `src/docs/phases/tasks/05-04-rebuild-index-command_imp.md`
- `src/docs/research/shell-only-cli-advanced-notes.md`
