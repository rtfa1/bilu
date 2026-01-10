#!/usr/bin/env bash
set -euo pipefail

# Set status in task markdown
# Usage: actions/set_status.sh <task_path> <new_status>

task_path="$1"
new_status="$2"

if [[ -z "$task_path" || -z "$new_status" ]]; then
  echo "error: usage: set_status.sh <task_path> <new_status>" >&2
  exit 1
fi

if [[ ! -f "$task_path" ]]; then
  echo "error: task file missing: $task_path" >&2
  exit 1
fi

# Validate normalized status (basic check)
case "$new_status" in
  TODO|INPROGRESS|REVIEW|DONE|BLOCKED|ARCHIVED|CANCELLED) ;;
  *) echo "error: invalid status: $new_status" >&2; exit 1 ;;
esac

# Create temp file
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Read and modify the file
found_status=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "# Status" ]]; then
    echo "$line" >> "$temp_file"
    # Skip the next line (old status value)
    read -r next_line || true
    echo "$new_status" >> "$temp_file"
    found_status=1
  else
    echo "$line" >> "$temp_file"
  fi
done < "$task_path"

if [[ $found_status -eq 0 ]]; then
  echo "error: # Status section not found in $task_path" >&2
  exit 1
fi

# Atomic move
mv "$temp_file" "$task_path"
trap - EXIT