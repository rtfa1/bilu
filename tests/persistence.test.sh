#!/usr/bin/env sh
set -eu

REPO_ROOT=$(
  CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1
  pwd
)

mktemp_dir() {
  if command -v mktemp >/dev/null 2>&1; then
    d=$(mktemp -d 2>/dev/null || true)
    if [ -n "${d:-}" ] && [ -d "$d" ]; then
      printf "%s\n" "$d"
      return 0
    fi
  fi
  d="$REPO_ROOT/.tmp-persistence-test.$$"
  mkdir -p "$d"
  printf "%s\n" "$d"
}

tmp="$(mktemp_dir)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

# Copy bilu structure
cp -R "$REPO_ROOT/.bilu" "$tmp/.bilu"

# Create sample task
mkdir -p "$tmp/.bilu/board/tasks"
cat > "$tmp/.bilu/board/tasks/01-01-test-task.md" <<'EOF'
# Phase 01 — Test task

## Goal

Test persistence.

## Checklist

- [ ] Test item

## Acceptance

Done when tested.

## Implementation plan

Do it.

# Description
Test

# Status
TODO

# Priority
MEDIUM

# Kind
task

# Tags
- test

# depends_on
EOF

# Change to temp dir
cd "$tmp"

# Test set-status updates only status section
before=$(cat ".bilu/board/tasks/01-01-test-task.md")
NO_COLOR=1 sh ".bilu/cli/bilu" board --set-status 01-01-test-task DONE
after=$(cat ".bilu/board/tasks/01-01-test-task.md")

# Check status changed
printf "%s" "$after" | grep -F "# Status" | grep -F "DONE" >/dev/null

# Check other parts unchanged (normalize by removing status line)
before_normalized=$(printf "%s" "$before" | awk '/^# Status$/ {getline; next} 1')
after_normalized=$(printf "%s" "$after" | awk '/^# Status$/ {getline; next} 1')
test "$before_normalized" = "$after_normalized"

# Test set-priority
NO_COLOR=1 sh ".bilu/cli/bilu" board --set-priority 01-01-test-task HIGH
after_priority=$(cat ".bilu/board/tasks/01-01-test-task.md")

# Check priority changed
printf "%s" "$after_priority" | grep -F "# Priority" | grep -F "HIGH" >/dev/null

# Check status still DONE
printf "%s" "$after_priority" | grep -F "# Status" | grep -F "DONE" >/dev/null

# Test list reflects changes
out=$(NO_COLOR=1 sh ".bilu/cli/bilu" board --list)
printf "%s" "$out" | grep -F "DONE" >/dev/null
printf "%s" "$out" | grep -F "HIGH" >/dev/null

# Test atomic write: file exists and valid
test -f ".bilu/board/tasks/01-01-test-task.md"
printf "%s" "$after_priority" | grep -F "# Status" >/dev/null
printf "%s" "$after_priority" | grep -F "# Priority" >/dev/null