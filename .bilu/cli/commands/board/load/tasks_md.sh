#!/usr/bin/env sh

board_load_tasks_from_md() {
  tasks_dir=${1:-}
  if [ -z "$tasks_dir" ] || [ ! -d "$tasks_dir" ]; then
    return 1
  fi
  # Placeholder: later tasks will emit normalized TSV from markdown metadata sections.
  return 0
}

