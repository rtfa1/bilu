#!/usr/bin/env bash
set -euo pipefail

TUI_STTY_SAVED=""
TUI_CLEANED=0

tui_read_key() {
  local key k1 k2 k3

  key=""
  IFS= read -rsn1 -t 0.05 key || true
  if [[ -z "$key" ]]; then
    printf '%s\n' "NONE"
    return 0
  fi

  case "$key" in
    $'\r'|$'\n') printf '%s\n' "ENTER"; return 0 ;;
    $'\x7f'|$'\b') printf '%s\n' "BACKSPACE"; return 0 ;;
  esac

  if [[ "$key" != $'\e' ]]; then
    printf '%s\n' "$key"
    return 0
  fi

  k1=""
  k2=""
  k3=""
  IFS= read -rsn1 -t 0.001 k1 || true
  IFS= read -rsn1 -t 0.001 k2 || true

  case "${k1}${k2}" in
    "[A") printf '%s\n' "UP"; return 0 ;;
    "[B") printf '%s\n' "DOWN"; return 0 ;;
    "[C") printf '%s\n' "RIGHT"; return 0 ;;
    "[D") printf '%s\n' "LEFT"; return 0 ;;
    "OA") printf '%s\n' "UP"; return 0 ;;
    "OB") printf '%s\n' "DOWN"; return 0 ;;
    "OC") printf '%s\n' "RIGHT"; return 0 ;;
    "OD") printf '%s\n' "LEFT"; return 0 ;;
    "[H") printf '%s\n' "HOME"; return 0 ;;
    "[F") printf '%s\n' "END"; return 0 ;;
  esac

  if [[ "$k1" = "[" ]]; then
    case "$k2" in
      1|4|5|6)
        IFS= read -rsn1 -t 0.001 k3 || true
        if [[ "$k3" = "~" ]]; then
          case "$k2" in
            1) printf '%s\n' "HOME"; return 0 ;;
            4) printf '%s\n' "END"; return 0 ;;
            5) printf '%s\n' "PAGEUP"; return 0 ;;
            6) printf '%s\n' "PAGEDOWN"; return 0 ;;
          esac
        fi
        ;;
    esac
  fi

  printf '%s\n' "ESC"
}

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
  local key last_key row col
  last_key="NONE"
  row=0
  col=0
  while true; do
    board_tui_draw

    key="$(tui_read_key)"
    if [[ "$key" != "NONE" ]]; then
      last_key="$key"
    fi
    case "$key" in
      q) return 0 ;;
      UP|k) (( row -= 1 )) || true ;;
      DOWN|j) (( row += 1 )) || true ;;
      LEFT|h) (( col -= 1 )) || true ;;
      RIGHT|l) (( col += 1 )) || true ;;
    esac

    if [[ "$row" -lt 0 ]]; then row=0; fi
    if [[ "$col" -lt 0 ]]; then col=0; fi

    printf '\e[3;1H'
    printf 'Last key: %-10s  Cursor: (%s,%s)\r\n' "$last_key" "$col" "$row"
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
