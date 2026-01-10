#!/usr/bin/env bash
set -euo pipefail

# Set priority in task markdown
# Usage: actions/set_priority.sh <task_path> <new_priority>

task_path="$1"
new_priority="$2"

if [[ -z "$task_path" || -z "$new_priority" ]]; then
  echo "error: usage: set_priority.sh <task_path> <new_priority>" >&2
  exit 1
fi

if [[ ! -f "$task_path" ]]; then
  echo "error: task file missing: $task_path" >&2
  exit 1
fi

# Validate normalized priority (basic check)
case "$new_priority" in
  TRIVIAL|LOW|MEDIUM|HIGH|CRITICAL) ;;
  *) echo "error: invalid priority: $new_priority" >&2; exit 1 ;;
esac

# Create temp file
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Read and modify the file
found_priority=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "# Priority" ]]; then
    echo "$line" >> "$temp_file"
    # Skip the next line (old priority value)
    read -r next_line || true
    echo "$new_priority" >> "$temp_file"
    found_priority=1
  else
    echo "$line" >> "$temp_file"
  fi
done < "$task_path"

if [[ $found_priority -eq 0 ]]; then
  echo "error: # Priority section not found in $task_path" >&2
  exit 1
fi

# Atomic move
mv "$temp_file" "$task_path"
trap - EXIT