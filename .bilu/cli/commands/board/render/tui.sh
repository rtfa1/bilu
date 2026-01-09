#!/usr/bin/env bash
set -euo pipefail

TUI_STTY_SAVED=""
TUI_CLEANED=0

board_tui_setup_terminal() {
  TUI_STTY_SAVED="$(stty -g 2>/dev/null || true)"

  printf '\e[?1049h'
  printf '\e[?7l'
  printf '\e[?25l'

  if ! stty -echo -icanon time 0 min 0 2>/dev/null; then
    stty -echo 2>/dev/null || true
  fi

  printf '\e[2J\e[H'
}

board_tui_cleanup_terminal() {
  if [[ "$TUI_CLEANED" -eq 1 ]]; then
    return 0
  fi
  TUI_CLEANED=1

  if [[ -n "$TUI_STTY_SAVED" ]]; then
    stty "$TUI_STTY_SAVED" 2>/dev/null || true
  else
    stty echo icanon 2>/dev/null || true
  fi

  printf '\e[?7h'
  printf '\e[?25h'
  printf '\e[?1049l'
}

board_tui_draw() {
  local rows cols
  rows=${LINES:-0}
  cols=${COLUMNS:-0}
  if [[ "$rows" -le 0 ]]; then rows=24; fi
  if [[ "$cols" -le 0 ]]; then cols=80; fi

  printf '\e[H'
  printf 'bilu board --tui (stub)  %sx%s\r\n' "$cols" "$rows"
  printf '%s\r\n' 'Press q to quit. Ctrl-C is safe.'
}

board_tui_main_loop() {
  local key
  while true; do
    board_tui_draw

    key=""
    IFS= read -rsn1 -t 0.1 key || true
    case "$key" in
      q) return 0 ;;
    esac
  done
}

board_tui_main() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    printf "%s\n" "bilu board --tui requires a TTY" >&2
    return 1
  fi

  trap board_tui_cleanup_terminal EXIT INT TERM
  board_tui_setup_terminal
  board_tui_main_loop
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  board_tui_main "$@"
fi
