#!/usr/bin/env sh
set -eu

board_render_table() {
  # TSV v1 columns:
  # 1 id, 2 status, 3 priority_weight, 4 priority, 5 kind, 6 title,
  # 7 path, 8 tags_csv, 9 depends_csv, 10 link
  awk -F '\t' '
    BEGIN { printf "%-28s %-12s %-9s %s\n", "id", "status", "priority", "title" }
    NF==10 { printf "%-28s %-12s %-9s %s\n", $1, $2, $4, $6 }
  '
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_render_table

