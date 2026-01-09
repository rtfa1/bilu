#!/usr/bin/env sh
set -eu

board_load_tasks_from_json() {
  index_path=${1:-}
  if [ -z "$index_path" ] || [ ! -f "$index_path" ]; then
    return 1
  fi

  board_root=$2
  if [ -z "${board_root:-}" ]; then
    board_root=$(
      CDPATH= cd -- "$(dirname -- "$index_path")/.." >/dev/null 2>&1
      pwd
    )
  fi

  sh "$(dirname -- "$0")/../records_tsv.sh" "$board_root"
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_load_tasks_from_json "$@"
