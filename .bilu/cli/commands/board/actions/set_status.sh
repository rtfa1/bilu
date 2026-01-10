#!/usr/bin/env bash
set -euo pipefail

# Set status in task markdown
# Usage: actions/set_status.sh <task_path> <new_status>

SCRIPT_DIR=$(dirname "$0")

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

# Normalize the status
normalized=$(sh "$SCRIPT_DIR/../normalize.sh" status "$new_status") || {
  echo "error: failed to normalize status: $?" >&2
  exit 1
}

# Check if input was invalid (normalized to TODO but input not equivalent to TODO)
input_lc=$(echo "$new_status" | tr '[:upper:]' '[:lower:]')
if [ "$normalized" = "TODO" ] && [ "$input_lc" != "todo" ]; then
  echo "error: invalid status: $new_status" >&2
  exit 1
fi

new_status="$normalized"

# Create temp file
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Read and modify the file
found_status=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "# Status" ]]; then
    echo "$line" >> "$temp_file"
    # Find the next non-empty line to replace
    while IFS= read -r next_line || [[ -n "$next_line" ]]; do
      if [[ -n "$next_line" ]]; then
        echo "$new_status" >> "$temp_file"
        found_status=1
        break
      else
        echo "$next_line" >> "$temp_file"
      fi
    done
    if [[ $found_status -eq 0 ]]; then
      # No non-empty line found, append the status
      echo "$new_status" >> "$temp_file"
      found_status=1
    fi
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