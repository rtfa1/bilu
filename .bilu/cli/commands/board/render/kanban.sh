#!/usr/bin/env sh
set -eu

board_render_kanban() {
  SCRIPT_DIR=$(
    CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
    pwd
  )

  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/../ui/ansi.sh" 2>/dev/null || true

  ANSI_RESET=""
  ANSI_ST_BACKLOG=""
  ANSI_ST_TODO=""
  ANSI_ST_INPROGRESS=""
  ANSI_ST_BLOCKED=""
  ANSI_ST_REVIEW=""
  ANSI_ST_DONE=""
  ANSI_ST_ARCHIVED=""
  ANSI_ST_CANCELLED=""

  if command -v board_ansi_enabled_fd >/dev/null 2>&1 && board_ansi_enabled_fd 1; then
    ANSI_RESET="$(board_ansi_reset_fd 1)"
    ANSI_ST_BACKLOG="$(board_ansi_status_prefix_fd 1 BACKLOG)"
    ANSI_ST_TODO="$(board_ansi_status_prefix_fd 1 TODO)"
    ANSI_ST_INPROGRESS="$(board_ansi_status_prefix_fd 1 INPROGRESS)"
    ANSI_ST_BLOCKED="$(board_ansi_status_prefix_fd 1 BLOCKED)"
    ANSI_ST_REVIEW="$(board_ansi_status_prefix_fd 1 REVIEW)"
    ANSI_ST_DONE="$(board_ansi_status_prefix_fd 1 DONE)"
    ANSI_ST_ARCHIVED="$(board_ansi_status_prefix_fd 1 ARCHIVED)"
    ANSI_ST_CANCELLED="$(board_ansi_status_prefix_fd 1 CANCELLED)"
  fi

  awk -F '\t' \
    -v R="$ANSI_RESET" \
    -v ST_BACKLOG="$ANSI_ST_BACKLOG" \
    -v ST_TODO="$ANSI_ST_TODO" \
    -v ST_INPROGRESS="$ANSI_ST_INPROGRESS" \
    -v ST_BLOCKED="$ANSI_ST_BLOCKED" \
    -v ST_REVIEW="$ANSI_ST_REVIEW" \
    -v ST_DONE="$ANSI_ST_DONE" \
    -v ST_ARCHIVED="$ANSI_ST_ARCHIVED" \
    -v ST_CANCELLED="$ANSI_ST_CANCELLED" \
    '
    function status_pre(status) {
      if (status == "BACKLOG") return ST_BACKLOG
      if (status == "TODO") return ST_TODO
      if (status == "INPROGRESS") return ST_INPROGRESS
      if (status == "BLOCKED") return ST_BLOCKED
      if (status == "REVIEW") return ST_REVIEW
      if (status == "DONE") return ST_DONE
      if (status == "ARCHIVED") return ST_ARCHIVED
      if (status == "CANCELLED") return ST_CANCELLED
      return ""
    }
    NF==10 {
      pre = status_pre($2)
      if (pre != "" && R != "") printf "%s%s%s\t%s\t%s\n", pre, $2, R, $1, $6
      else printf "%s\t%s\t%s\n", $2, $1, $6
    }'
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_render_kanban
