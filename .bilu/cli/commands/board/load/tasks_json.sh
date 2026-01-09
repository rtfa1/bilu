#!/usr/bin/env sh

board_load_tasks_from_json() {
  index_path=${1:-}
  if [ -z "$index_path" ] || [ ! -f "$index_path" ]; then
    return 1
  fi
  cat "$index_path"
}

