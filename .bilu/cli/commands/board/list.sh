#!/usr/bin/env sh
set -eu

filter=${1:-}
filter_value=${2:-}
view=${BOARD_VIEW:-table}

if [ -n "$filter" ]; then
  printf "board listing (view: %s, filter: %s=%s)\n" "$view" "$filter" "$filter_value"
elif [ "$view" != "table" ]; then
  printf "board listing (view: %s)\n" "$view"
else
  printf "%s\n" "board listing"
fi

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

records_sh="$SCRIPT_DIR/records_tsv.sh"
render_table_sh="$SCRIPT_DIR/render/table.sh"
render_kanban_sh="$SCRIPT_DIR/render/kanban.sh"

render_sh="$render_table_sh"
case "$view" in
  table) render_sh="$render_table_sh" ;;
  kanban) render_sh="$render_kanban_sh" ;;
esac

if [ ! -f "$records_sh" ] || [ ! -f "$render_sh" ]; then
  exit 0
fi

case "$filter" in
  "" )
    sh "$records_sh" "${BOARD_ROOT:-}" | sh "$render_sh"
    ;;
  status)
    sh "$records_sh" "${BOARD_ROOT:-}" |
      awk -F '\t' -v V="$filter_value" 'BEGIN{v=tolower(V)} tolower($2)==v {print}' |
      sh "$render_sh"
    ;;
  priority)
    sh "$records_sh" "${BOARD_ROOT:-}" |
      awk -F '\t' -v V="$filter_value" 'BEGIN{v=tolower(V)} tolower($4)==v {print}' |
      sh "$render_sh"
    ;;
  kind)
    sh "$records_sh" "${BOARD_ROOT:-}" |
      awk -F '\t' -v V="$filter_value" 'BEGIN{v=tolower(V)} tolower($5)==v {print}' |
      sh "$render_sh"
    ;;
  *)
    sh "$records_sh" "${BOARD_ROOT:-}" | sh "$render_sh"
    ;;
esac
