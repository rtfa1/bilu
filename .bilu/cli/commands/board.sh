#!/usr/bin/env sh
set -eu

board_usage() {
  cat <<'EOF'
Usage:
  bilu board --list [--filter <name> --filter-value <value>]
  bilu board --validate
  bilu board --migrate [--dry-run]
  bilu board --rebuild-index [--dry-run]

Options:
  --list, -l                 List board items
  --filter, -f <name>        Filter field name (e.g. status)
  --filter-value, -fv <val>  Filter value (e.g. todo)
  --validate                 Validate board config/data
  --migrate                  Migrate task markdown metadata sections
  --rebuild-index            Rebuild derived board index from markdown
  --dry-run                  Print changes without writing
  --                         End of options
  --help, -h                 Show this help

Examples:
  bilu board --list
  bilu board --list --filter=status --filter-value=todo
  bilu board --list -f status -fv todo
  bilu board --validate
EOF
}

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

BOARD_LIB_DIR="$SCRIPT_DIR/board"

. "$BOARD_LIB_DIR/lib/log.sh"
. "$BOARD_LIB_DIR/paths.sh"
. "$BOARD_LIB_DIR/args.sh"

board_parse_args "$@"

if [ "$BOARD_ACTION" = "help" ]; then
  board_usage
  exit 0
fi

if ! board_detect_paths "$SCRIPT_DIR"; then
  die "could not locate board root (expected .bilu/board or src/board)"
fi

case "$BOARD_ACTION" in
  validate)
    exec sh "$BOARD_LIB_DIR/validate.sh" "$BOARD_ROOT"
    ;;
  rebuild-index)
    exec sh "$BOARD_LIB_DIR/rebuild_index.sh" "$BOARD_ROOT" "$BOARD_DRY_RUN"
    ;;
  migrate)
    exec sh "$BOARD_LIB_DIR/migrate.sh" "$BOARD_ROOT" "$BOARD_DRY_RUN"
    ;;
  list)
    if [ -n "$BOARD_FILTER_NAME" ]; then
      exec sh "$BOARD_LIB_DIR/list.sh" "$BOARD_FILTER_NAME" "$BOARD_FILTER_VALUE"
    fi
    exec sh "$BOARD_LIB_DIR/list.sh"
    ;;
  *)
    usage_error "unknown action: $BOARD_ACTION"
    ;;
esac
