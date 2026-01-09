#!/usr/bin/env sh

board_detect_paths() {
  script_dir=${1:-}
  if [ -z "$script_dir" ]; then
    return 1
  fi

  d=$script_dir
  i=0
  while [ "$i" -lt 8 ]; do
    if [ -f "$d/board/default.json" ] && [ -f "$d/cli/commands/board.sh" ]; then
      BOARD_ROOT=$d
      BOARD_CONFIG_PATH=$d/board/config.json
      BOARD_DEFAULT_JSON_PATH=$d/board/default.json
      BOARD_TASKS_DIR=$d/board/tasks
      if [ -d "$d/storage" ]; then
        BOARD_STORAGE_DIR=$d/storage
      elif [ -d "$d/board/storage" ]; then
        BOARD_STORAGE_DIR=$d/board/storage
      else
        BOARD_STORAGE_DIR=$d/storage
      fi

      export BOARD_ROOT BOARD_CONFIG_PATH BOARD_DEFAULT_JSON_PATH BOARD_TASKS_DIR BOARD_STORAGE_DIR
      return 0
    fi

    d=$(
      CDPATH= cd -- "$d/.." >/dev/null 2>&1
      pwd
    )
    i=$((i + 1))
  done

  return 1
}

