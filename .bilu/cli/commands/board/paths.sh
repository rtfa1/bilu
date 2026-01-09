#!/usr/bin/env sh

board__detect_template_root() {
  start_dir=${1:-}
  if [ -z "$start_dir" ]; then
    return 1
  fi

  d=$start_dir
  i=0
  while [ "$i" -lt 10 ]; do
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

      base=${d##*/}
      if [ "$base" = "src" ]; then
        BOARD_LAYOUT=repo
      else
        BOARD_LAYOUT=installed
      fi
      export BOARD_ROOT BOARD_CONFIG_PATH BOARD_DEFAULT_JSON_PATH BOARD_TASKS_DIR BOARD_STORAGE_DIR BOARD_LAYOUT
      return 0
    fi

    parent=$(
      CDPATH= cd -- "$d/.." >/dev/null 2>&1
      pwd
    )
    if [ "$parent" = "$d" ]; then
      break
    fi
    d=$parent
    i=$((i + 1))
  done

  return 1
}

board__detect_project_bilu() {
  d=$(
    CDPATH= cd -- "." >/dev/null 2>&1
    pwd
  )
  i=0
  while [ "$i" -lt 10 ]; do
    if [ -d "$d/.bilu" ] && [ -f "$d/.bilu/board/default.json" ] && [ -f "$d/.bilu/cli/commands/board.sh" ]; then
      BOARD_PROJECT_ROOT=$d
      BOARD_ROOT=$d/.bilu
      BOARD_CONFIG_PATH=$d/.bilu/board/config.json
      BOARD_DEFAULT_JSON_PATH=$d/.bilu/board/default.json
      BOARD_TASKS_DIR=$d/.bilu/board/tasks
      if [ -d "$d/.bilu/storage" ]; then
        BOARD_STORAGE_DIR=$d/.bilu/storage
      elif [ -d "$d/.bilu/board/storage" ]; then
        BOARD_STORAGE_DIR=$d/.bilu/board/storage
      else
        BOARD_STORAGE_DIR=$d/.bilu/storage
      fi

      BOARD_LAYOUT=installed
      export BOARD_PROJECT_ROOT BOARD_ROOT BOARD_CONFIG_PATH BOARD_DEFAULT_JSON_PATH BOARD_TASKS_DIR BOARD_STORAGE_DIR BOARD_LAYOUT
      return 0
    fi

    parent=$(
      CDPATH= cd -- "$d/.." >/dev/null 2>&1
      pwd
    )
    if [ "$parent" = "$d" ]; then
      break
    fi
    d=$parent
    i=$((i + 1))
  done

  return 1
}

board_detect_paths() {
  script_dir=${1:-}
  if board__detect_project_bilu; then
    return 0
  fi

  if board__detect_template_root "$script_dir"; then
    return 0
  fi

  return 1
}

board_config_path() {
  printf "%s\n" "${BOARD_CONFIG_PATH:-}"
}

board_default_json_path() {
  printf "%s\n" "${BOARD_DEFAULT_JSON_PATH:-}"
}

board_tasks_dir() {
  printf "%s\n" "${BOARD_TASKS_DIR:-}"
}
