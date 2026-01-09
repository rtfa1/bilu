#!/usr/bin/env sh

board_columns__read_bool_key() {
  file_path=${1:-}
  key=${2:-}
  if [ -z "$file_path" ] || [ -z "$key" ] || [ ! -f "$file_path" ]; then
    return 1
  fi

  # Schema-specific extractor; avoids general JSON parsing.
  #
  # Expected shapes (pretty-printed):
  #   "showCompletedTasks": true,
  val=$(sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\\(true\\|false\\).*/\\1/p" "$file_path" | head -n 1)
  case "$val" in
    true) printf "%s\n" 1 ;;
    false) printf "%s\n" 0 ;;
    *) return 1 ;;
  esac
}

board_columns_init() {
  : "${BOARD_COLUMN_BACKLOG_STATUSES:=BACKLOG TODO}"
  : "${BOARD_COLUMN_INPROGRESS_STATUSES:=INPROGRESS BLOCKED}"
  : "${BOARD_COLUMN_REVIEW_STATUSES:=REVIEW}"
  : "${BOARD_COLUMN_DONE_STATUSES:=DONE}"

  : "${BOARD_UI_SHOW_ARCHIVED:=0}"
  : "${BOARD_UI_SHOW_CANCELLED:=0}"

  if [ -z "${BOARD_UI_SHOW_COMPLETED_TASKS:-}" ]; then
    BOARD_UI_SHOW_COMPLETED_TASKS=1
    if [ -n "${BOARD_CONFIG_PATH:-}" ]; then
      v=$(board_columns__read_bool_key "$BOARD_CONFIG_PATH" "showCompletedTasks" 2>/dev/null || true)
      case "$v" in
        0|1) BOARD_UI_SHOW_COMPLETED_TASKS=$v ;;
      esac
    fi
  fi

  export \
    BOARD_COLUMN_BACKLOG_STATUSES \
    BOARD_COLUMN_INPROGRESS_STATUSES \
    BOARD_COLUMN_REVIEW_STATUSES \
    BOARD_COLUMN_DONE_STATUSES \
    BOARD_UI_SHOW_COMPLETED_TASKS \
    BOARD_UI_SHOW_ARCHIVED \
    BOARD_UI_SHOW_CANCELLED
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi
