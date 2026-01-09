#!/usr/bin/env sh
set -eu

filter=${1:-}
filter_value=${2:-}

if [ -n "$filter" ]; then
  printf "board listing (filter: %s=%s)\n" "$filter" "$filter_value"
else
  printf "%s\n" "board listing"
fi

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

records_sh="$SCRIPT_DIR/records_tsv.sh"
render_table_sh="$SCRIPT_DIR/render/table.sh"

if [ ! -f "$records_sh" ] || [ ! -f "$render_table_sh" ]; then
  exit 0
fi

case "$filter" in
  "" )
    sh "$records_sh" "${BOARD_ROOT:-}" | sh "$render_table_sh"
    ;;
  status)
    sh "$records_sh" "${BOARD_ROOT:-}" |
      awk -F '\t' -v V="$filter_value" 'BEGIN{v=tolower(V)} tolower($2)==v {print}' |
      sh "$render_table_sh"
    ;;
  priority)
    sh "$records_sh" "${BOARD_ROOT:-}" |
      awk -F '\t' -v V="$filter_value" 'BEGIN{v=tolower(V)} tolower($4)==v {print}' |
      sh "$render_table_sh"
    ;;
  kind)
    sh "$records_sh" "${BOARD_ROOT:-}" |
      awk -F '\t' -v V="$filter_value" 'BEGIN{v=tolower(V)} tolower($5)==v {print}' |
      sh "$render_table_sh"
    ;;
  *)
    sh "$records_sh" "${BOARD_ROOT:-}" | sh "$render_table_sh"
    ;;
esac
