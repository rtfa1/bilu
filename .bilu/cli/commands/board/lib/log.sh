#!/usr/bin/env sh

board_error() {
  if command -v board_ansi_enabled_fd >/dev/null 2>&1 && board_ansi_enabled_fd 2; then
    pre="$(board_ansi_sgr_fd 2 '1;31')bilu board: error:$(board_ansi_reset_fd 2)"
    printf "%s %s\n" "$pre" "$*" >&2
    return 0
  fi

  printf "%s\n" "bilu board: error: $*" >&2
}

warn() {
  if command -v board_ansi_enabled_fd >/dev/null 2>&1 && board_ansi_enabled_fd 2; then
    pre="$(board_ansi_sgr_fd 2 '1;33')bilu board: warn:$(board_ansi_reset_fd 2)"
    printf "%s %s\n" "$pre" "$*" >&2
    return 0
  fi

  printf "%s\n" "bilu board: warn: $*" >&2
}

die() {
  board_error "$*"
  exit 1
}

usage_error() {
  board_error "$*"
  if command -v board_usage >/dev/null 2>&1; then
    board_usage >&2
  fi
  exit 2
}
