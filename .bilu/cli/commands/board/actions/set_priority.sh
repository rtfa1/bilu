#!/usr/bin/env bash
set -euo pipefail

# Set priority in task markdown
# Usage: actions/set_priority.sh <task_path> <new_priority>

SCRIPT_DIR=$(dirname "$0")
BOARD_LIB_DIR="$SCRIPT_DIR/.."

. "$BOARD_LIB_DIR/paths.sh"
. "$BOARD_LIB_DIR/lib/lock.sh"

board_detect_paths "$SCRIPT_DIR" || {
  echo "error: failed to detect board paths" >&2
  exit 1
}

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

# Normalize the priority
normalized=$(sh "$SCRIPT_DIR/../normalize.sh" priority "$new_priority") || {
  echo "error: failed to normalize priority: $?" >&2
  exit 1
}

# Check if input was invalid
input_lc=$(echo "$new_priority" | tr '[:upper:]' '[:lower:]')
case "$input_lc" in
  critical|high|medium|low|trivial)
    # valid
    ;;
  *)
    echo "error: invalid priority: $new_priority" >&2
    exit 1
    ;;
esac

new_priority="$normalized"

# Acquire lock
LOCK_DIR="$BOARD_STORAGE_DIR/lock"
board_lock_acquire "$LOCK_DIR" 10 || exit 1
trap 'board_lock_release "$LOCK_DIR"; rm -f "$temp_file"' EXIT INT TERM HUP

# Create temp file
temp_file=$(mktemp)

# Read and modify the file
found_priority=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "# Priority" ]]; then
    echo "$line" >> "$temp_file"
    # Find the next non-empty line to replace
    while IFS= read -r next_line || [[ -n "$next_line" ]]; do
      if [[ -n "$next_line" ]]; then
        echo "$new_priority" >> "$temp_file"
        found_priority=1
        break
      else
        echo "$next_line" >> "$temp_file"
      fi
    done
    if [[ $found_priority -eq 0 ]]; then
      # No non-empty line found, append the priority
      echo "$new_priority" >> "$temp_file"
      found_priority=1
    fi
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
board_lock_release "$LOCK_DIR"
trap - EXIT