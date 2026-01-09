#!/usr/bin/env sh

board_error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

warn() {
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

