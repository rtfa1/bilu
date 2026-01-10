#!/usr/bin/env sh

board_parse_args() {
  BOARD_ACTION=""
  BOARD_DRY_RUN=0
  BOARD_FILTER_NAME=""
  BOARD_FILTER_VALUE=""
  BOARD_NO_COLOR=0
  BOARD_VIEW="table"
  BOARD_SET_TASK_ID=""
  BOARD_SET_VALUE=""

  while [ $# -gt 0 ]; do
    arg=$1
    case "$arg" in
      --help|-h)
        BOARD_ACTION="help"
        export BOARD_ACTION BOARD_DRY_RUN BOARD_FILTER_NAME BOARD_FILTER_VALUE
        return 0
        ;;
      --list|-l)
        if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
          usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
        fi
        BOARD_ACTION="list"
        shift
        ;;
       --tui)
         if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
           usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
         fi
         BOARD_ACTION="tui"
         shift
         ;;
       --validate)
         if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
           usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
         fi
         BOARD_ACTION="validate"
         shift
         ;;
       --rebuild-index)
         if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
           usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
         fi
         BOARD_ACTION="rebuild-index"
         shift
         ;;
      --rebuild-cache)
        if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
          usage_error "choose a single action (--list, --tui, --rebuild-index, --rebuild-cache, --migrate, --validate, --set-status, or --set-priority)"
        fi
        BOARD_ACTION="rebuild-cache"
        shift
        ;;
       --migrate)
         if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
           usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
         fi
         BOARD_ACTION="migrate"
         shift
         ;;
       --set-status)
         if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
           usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
         fi
         BOARD_ACTION="set-status"
         shift
         if [ $# -lt 2 ]; then
           usage_error "missing arguments for --set-status: <task-id> <status>"
         fi
         BOARD_SET_TASK_ID=$1
         BOARD_SET_VALUE=$2
         shift 2
         ;;
       --set-priority)
         if [ -n "$BOARD_ACTION" ] && [ "$BOARD_ACTION" != "help" ]; then
           usage_error "choose a single action (--list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
         fi
         BOARD_ACTION="set-priority"
         shift
         if [ $# -lt 2 ]; then
           usage_error "missing arguments for --set-priority: <task-id> <priority>"
         fi
         BOARD_SET_TASK_ID=$1
         BOARD_SET_VALUE=$2
         shift 2
         ;;
       --dry-run)
        BOARD_DRY_RUN=1
        shift
        ;;
      --no-color)
        BOARD_NO_COLOR=1
        shift
        ;;
      --view)
        shift
        if [ $# -lt 1 ]; then
          usage_error "missing value for $arg"
        fi
        if [ -n "${BOARD_VIEW_SET:-}" ]; then
          usage_error "multiple --view values are not supported"
        fi
        BOARD_VIEW=$1
        BOARD_VIEW_SET=1
        shift
        ;;
      --view=*)
        if [ -n "${BOARD_VIEW_SET:-}" ]; then
          usage_error "multiple --view values are not supported"
        fi
        BOARD_VIEW=${arg#*=}
        BOARD_VIEW_SET=1
        shift
        ;;
      --filter|-f)
        shift
        if [ $# -lt 1 ]; then
          usage_error "missing value for $arg"
        fi
        if [ -n "$BOARD_FILTER_NAME" ]; then
          usage_error "multiple --filter values are not supported"
        fi
        BOARD_FILTER_NAME=$1
        shift
        ;;
      --filter=*|-f=*)
        if [ -n "$BOARD_FILTER_NAME" ]; then
          usage_error "multiple --filter values are not supported"
        fi
        BOARD_FILTER_NAME=${arg#*=}
        shift
        ;;
      --filter-value|-fv)
        shift
        if [ $# -lt 1 ]; then
          usage_error "missing value for $arg"
        fi
        if [ -n "$BOARD_FILTER_VALUE" ]; then
          usage_error "multiple --filter-value values are not supported"
        fi
        BOARD_FILTER_VALUE=$1
        shift
        ;;
      --filter-value=*|-fv=*)
        if [ -n "$BOARD_FILTER_VALUE" ]; then
          usage_error "multiple --filter-value values are not supported"
        fi
        BOARD_FILTER_VALUE=${arg#*=}
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        usage_error "unknown option: $arg"
        ;;
      *)
        usage_error "unexpected argument: $arg"
        ;;
    esac
  done

  if [ $# -gt 0 ]; then
    usage_error "unexpected argument: $1"
  fi

  if [ -z "$BOARD_ACTION" ]; then
    usage_error "missing action (use --list, --tui, --rebuild-index, --migrate, --validate, --set-status, or --set-priority)"
  fi

  if [ "$BOARD_ACTION" != "list" ]; then
    if [ -n "$BOARD_FILTER_NAME" ] || [ -n "$BOARD_FILTER_VALUE" ]; then
      usage_error "--filter/--filter-value are only valid with --list"
    fi
    if [ -n "${BOARD_VIEW_SET:-}" ]; then
      usage_error "--view is only valid with --list"
    fi
  fi

  if [ "$BOARD_ACTION" = "validate" ]; then
    if [ "$BOARD_DRY_RUN" -eq 1 ]; then
      usage_error "--dry-run is not valid with --validate"
    fi
  fi
  if [ "$BOARD_ACTION" = "tui" ]; then
    if [ "$BOARD_DRY_RUN" -eq 1 ]; then
      usage_error "--dry-run is not valid with --tui"
    fi
  fi
  if [ "$BOARD_ACTION" = "set-status" ] || [ "$BOARD_ACTION" = "set-priority" ]; then
    if [ "$BOARD_DRY_RUN" -eq 1 ]; then
      usage_error "--dry-run is not valid with --set-status or --set-priority"
    fi
  fi

  if [ -n "$BOARD_FILTER_NAME" ] && [ -z "$BOARD_FILTER_VALUE" ]; then
    usage_error "--filter-value is required when --filter is set"
  fi
  if [ -z "$BOARD_FILTER_NAME" ] && [ -n "$BOARD_FILTER_VALUE" ]; then
    usage_error "--filter is required when --filter-value is set"
  fi

  case "$BOARD_VIEW" in
    table|kanban) ;;
    *)
      usage_error "invalid --view value: $BOARD_VIEW (expected table or kanban)"
      ;;
  esac

  export BOARD_ACTION BOARD_DRY_RUN BOARD_FILTER_NAME BOARD_FILTER_VALUE BOARD_NO_COLOR BOARD_VIEW BOARD_SET_TASK_ID BOARD_SET_VALUE
}

