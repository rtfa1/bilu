#!/usr/bin/env sh
set -eu

board_render_kanban() {
  awk -F '\t' 'NF==10 { printf "%s\t%s\t%s\n", $2, $1, $6 }'
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_render_kanban

