#!/usr/bin/env bash
set -euo pipefail

# Open a task file with editor or pager
# Usage: actions/open.sh <task_path> [mode]
# mode: auto (default), editor, pager

task_path="$1"
mode="${2:-auto}"

if [[ -z "$task_path" ]]; then
  echo "error: no task path provided" >&2
  exit 1
fi

if [[ ! -f "$task_path" ]]; then
  echo "bilu board: error: task file not found: $task_path" >&2
  exit 1
fi

case "$mode" in
  auto)
    if [[ -n "${EDITOR:-}" ]]; then
      "$EDITOR" "$task_path"
    elif command -v less >/dev/null 2>&1; then
      less "$task_path"
    elif command -v more >/dev/null 2>&1; then
      more "$task_path"
    else
      echo "bilu board: error: neither less nor more found" >&2
      exit 1
    fi
    ;;
  editor)
    if [[ -z "${EDITOR:-}" ]]; then
      echo "bilu board: error: EDITOR not set" >&2
      exit 1
    fi
    "$EDITOR" "$task_path"
    ;;
  pager)
    if command -v less >/dev/null 2>&1; then
      less "$task_path"
    elif command -v more >/dev/null 2>&1; then
      more "$task_path"
    else
      echo "bilu board: error: neither less nor more found" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: invalid mode: $mode" >&2
    exit 1
    ;;
esac