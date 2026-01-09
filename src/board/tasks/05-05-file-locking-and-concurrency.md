# Phase 05 — File locking and concurrency

## Goal

Avoid corrupting task files when multiple commands run concurrently.

## Checklist

- [ ] Decide whether a lock is needed (recommended if edits are supported).
- [ ] If implementing a lock:
  - [ ] lock file under `board/storage/` or `.bilu/storage/`
  - [ ] lock acquisition is atomic (mkdir-based lock)
  - [ ] lock release on exit via `trap`
  - [ ] lock timeout or stale lock handling

## Acceptance

- Two concurrent edits do not corrupt files; lock behavior is documented.

