#!/usr/bin/env bash
set -euo pipefail

# Open a task file with editor or pager
# Usage: actions/open.sh <task_path>

task_path="$1"

if [[ -z "$task_path" ]]; then
  echo "error: no task path provided" >&2
  exit 1
fi

if [[ ! -f "$task_path" ]]; then
  echo "error: task file missing: $task_path" >&2
  exit 1
fi

if [[ -n "${EDITOR:-}" ]]; then
  "$EDITOR" "$task_path"
elif command -v less >/dev/null 2>&1; then
  less "$task_path"
elif command -v more >/dev/null 2>&1; then
  more "$task_path"
else
  echo "error: no editor or pager available" >&2
  exit 1
fi