#!/usr/bin/env sh
set -eu

board_usage() {
  cat <<'EOF'
Usage:
  bilu board --list [--view <table|kanban>] [--filter <name> --filter-value <value>] [--no-color]
  bilu board --tui [--no-color]
  bilu board --validate [--no-color]
  bilu board --migrate [--dry-run] [--no-color]
  bilu board --rebuild-index [--dry-run] [--no-color]
  bilu board --rebuild-cache [--dry-run] [--no-color]
  bilu board --set-status <task-id> <status> [--dry-run] [--no-color]
  bilu board --set-priority <task-id> <priority> [--dry-run] [--no-color]

Options:
  --list, -l                 List board items
  --tui                      Interactive full-screen kanban UI (bash)
  --view <table|kanban>      Select list view (default: table)
  --filter, -f <name>        Filter field name (e.g. status)
  --filter-value, -fv <val>  Filter value (e.g. todo)
  --no-color                 Disable ANSI colors (also respects NO_COLOR)
  --validate                 Validate board config/data
  --migrate                  Migrate task markdown metadata sections
  --rebuild-index            Rebuild derived board index from markdown
  --rebuild-cache            Rebuild derived TSV cache (board/records.tsv)
  --set-status               Set status of a task
  --set-priority             Set priority of a task
  --dry-run                  Print changes without writing
  --                         End of options
  --help, -h                 Show this help

Examples:
  bilu board --list
  bilu board --list --view=kanban
  bilu board --list --filter=status --filter-value=todo
  bilu board --list -f status -fv todo
  bilu board --tui
  bilu board --validate
  bilu board --set-status 05-06-persistence-tests DONE
EOF
}

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

BOARD_LIB_DIR="$SCRIPT_DIR/board"

. "$BOARD_LIB_DIR/ui/ansi.sh" 2>/dev/null || true
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
  tui)
    exec bash "$BOARD_LIB_DIR/render/tui.sh" "$BOARD_ROOT"
    ;;
  rebuild-index)
    exec sh "$BOARD_LIB_DIR/rebuild_index.sh" "$BOARD_ROOT" "$BOARD_DRY_RUN"
    ;;
  rebuild-cache)
    exec sh "$BOARD_LIB_DIR/rebuild_cache.sh" "$BOARD_ROOT" "$BOARD_DRY_RUN"
    ;;
   migrate)
     exec sh "$BOARD_LIB_DIR/migrate.sh" "$BOARD_ROOT" "$BOARD_DRY_RUN"
     ;;
   set-status)
     task_path="$BOARD_TASKS_DIR/$BOARD_SET_TASK_ID.md"
     if [ ! -f "$task_path" ]; then
       die "task not found: $BOARD_SET_TASK_ID"
     fi
     exec bash "$BOARD_LIB_DIR/actions/set_status.sh" "$task_path" "$BOARD_SET_VALUE"
     ;;
   set-priority)
     task_path="$BOARD_TASKS_DIR/$BOARD_SET_TASK_ID.md"
     if [ ! -f "$task_path" ]; then
       die "task not found: $BOARD_SET_TASK_ID"
     fi
     exec bash "$BOARD_LIB_DIR/actions/set_priority.sh" "$task_path" "$BOARD_SET_VALUE"
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
