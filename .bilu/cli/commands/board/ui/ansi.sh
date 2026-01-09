#!/usr/bin/env sh

board_ansi_enabled_fd() {
  fd=${1:-1}

  if [ "${BOARD_NO_COLOR:-0}" = "1" ]; then
    return 1
  fi
  if [ -n "${NO_COLOR:-}" ]; then
    return 1
  fi
  if [ ! -t "$fd" ]; then
    return 1
  fi

  return 0
}

board_ansi_sgr_fd() {
  fd=${1:-1}
  codes=${2:-0}

  if board_ansi_enabled_fd "$fd"; then
    # shellcheck disable=SC2059
    printf '\033[%sm' "$codes"
  fi
}

board_ansi_reset_fd() {
  board_ansi_sgr_fd "${1:-1}" 0
}

board_ansi_dim_fd() {
  board_ansi_sgr_fd "${1:-1}" 2
}

board_ansi_status_prefix_fd() {
  fd=${1:-1}
  status=${2:-}

  case "$status" in
    BACKLOG|ARCHIVED|CANCELLED)
      board_ansi_dim_fd "$fd"
      ;;
    TODO)
      board_ansi_sgr_fd "$fd" 33
      ;;
    INPROGRESS)
      board_ansi_sgr_fd "$fd" 34
      ;;
    BLOCKED)
      board_ansi_sgr_fd "$fd" 31
      ;;
    REVIEW)
      board_ansi_sgr_fd "$fd" 35
      ;;
    DONE)
      board_ansi_sgr_fd "$fd" 32
      ;;
    *)
      printf "%s" ""
      ;;
  esac
}

board_ansi_priority_prefix_fd() {
  fd=${1:-1}
  priority=${2:-}

  case "$priority" in
    CRITICAL)
      board_ansi_sgr_fd "$fd" "1;31"
      ;;
    HIGH)
      board_ansi_sgr_fd "$fd" "1;33"
      ;;
    MEDIUM)
      board_ansi_sgr_fd "$fd" 33
      ;;
    LOW)
      board_ansi_sgr_fd "$fd" 36
      ;;
    TRIVIAL)
      board_ansi_dim_fd "$fd"
      ;;
    *)
      printf "%s" ""
      ;;
  esac
}

