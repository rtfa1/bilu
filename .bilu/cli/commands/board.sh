#!/usr/bin/env sh
set -eu

error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

warn() {
  printf "%s\n" "bilu board: warn: $*" >&2
}

usage() {
  cat <<'EOF'
Usage:
  bilu board --list [--filter <name>|--filter=<name> --filter-value <value>|--filter-value=<value>]
  bilu board --rebuild-index [--dry-run]
  bilu board --migrate [--dry-run]
  bilu board --validate

Options:
  --list, -l                 List board items
  --filter, -f <name>        Filter field name (e.g. status)
  --filter-value, -fv <val>  Filter value (e.g. todo)
  --rebuild-index            Rebuild derived board index from markdown
  --migrate                  Migrate existing data into markdown metadata sections
  --dry-run                  Print changes without writing
  --validate                 Validate board config/data
  --                         End of options
  --help, -h                 Show this help

Exit codes:
  0 success
  1 runtime/data/config error
  2 usage error
EOF
}

list=0
validate=0
rebuild_index=0
migrate=0
dry_run=0
filter=""
filter_value=""

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

find_template_root() {
  d=$SCRIPT_DIR
  i=0
  while [ "$i" -lt 8 ]; do
    if [ -f "$d/board/default.json" ] && [ -f "$d/cli/commands/board.sh" ]; then
      printf "%s\n" "$d"
      return 0
    fi
    d=$(
      CDPATH= cd -- "$d/.." >/dev/null 2>&1
      pwd
    )
    i=$((i + 1))
  done
  return 1
}

while [ $# -gt 0 ]; do
  arg=$1
  case "$arg" in
    --help|-h)
      usage
      exit 0
      ;;
    --list|-l)
      list=1
      shift
      ;;
    --validate)
      validate=1
      shift
      ;;
    --rebuild-index)
      rebuild_index=1
      shift
      ;;
    --migrate)
      migrate=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --filter|-f)
      shift
      if [ $# -lt 1 ]; then
        error "missing value for $arg"
        usage >&2
        exit 2
      fi
      if [ -n "$filter" ]; then
        error "multiple --filter values are not supported"
        usage >&2
        exit 2
      fi
      filter=$1
      shift
      ;;
    --filter=*|-f=*)
      if [ -n "$filter" ]; then
        error "multiple --filter values are not supported"
        usage >&2
        exit 2
      fi
      filter=${arg#*=}
      shift
      ;;
    --filter-value|-fv)
      shift
      if [ $# -lt 1 ]; then
        error "missing value for $arg"
        usage >&2
        exit 2
      fi
      if [ -n "$filter_value" ]; then
        error "multiple --filter-value values are not supported"
        usage >&2
        exit 2
      fi
      filter_value=$1
      shift
      ;;
    --filter-value=*|-fv=*)
      if [ -n "$filter_value" ]; then
        error "multiple --filter-value values are not supported"
        usage >&2
        exit 2
      fi
      filter_value=${arg#*=}
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      error "unknown option: $arg"
      usage >&2
      exit 2
      ;;
    *)
      error "unexpected argument: $arg"
      usage >&2
      exit 2
      ;;
  esac
done

if [ $# -gt 0 ]; then
  error "unexpected argument: $1"
  usage >&2
  exit 2
fi

if [ "$list" -eq 1 ] && [ "$validate" -eq 1 ]; then
  error "choose a single action (--list or --validate)"
  usage >&2
  exit 2
fi

actions=$((list + validate + rebuild_index + migrate))
if [ "$actions" -gt 1 ]; then
  error "choose a single action (--list, --rebuild-index, --migrate, or --validate)"
  usage >&2
  exit 2
fi

if [ "$actions" -eq 0 ]; then
  error "missing action (use --list, --rebuild-index, --migrate, or --validate)"
  usage >&2
  exit 2
fi

if [ "$validate" -eq 1 ]; then
  if [ -n "$filter" ] || [ -n "$filter_value" ]; then
    error "--filter/--filter-value are only valid with --list"
    usage >&2
    exit 2
  fi
  if [ "$dry_run" -eq 1 ]; then
    error "--dry-run is not valid with --validate"
    usage >&2
    exit 2
  fi

  template_root=$(find_template_root || true)
  if [ -z "$template_root" ]; then
    error "could not locate bilu template root"
    exit 1
  fi
  exec sh "$SCRIPT_DIR/board/validate.sh" "$template_root"
fi

if [ "$rebuild_index" -eq 1 ] || [ "$migrate" -eq 1 ]; then
  if [ -n "$filter" ] || [ -n "$filter_value" ]; then
    error "--filter/--filter-value are only valid with --list"
    usage >&2
    exit 2
  fi

  template_root=$(find_template_root || true)
  if [ -z "$template_root" ]; then
    error "could not locate bilu template root"
    exit 1
  fi

  if [ "$rebuild_index" -eq 1 ]; then
    exec sh "$SCRIPT_DIR/board/rebuild_index.sh" "$template_root" "$dry_run"
  fi
  exec sh "$SCRIPT_DIR/board/migrate.sh" "$template_root" "$dry_run"
fi

if [ -n "$filter" ] && [ -z "$filter_value" ]; then
  error "--filter-value is required when --filter is set"
  usage >&2
  exit 2
fi
if [ -z "$filter" ] && [ -n "$filter_value" ]; then
  error "--filter is required when --filter-value is set"
  usage >&2
  exit 2
fi

if [ -n "$filter" ]; then
  exec sh "$SCRIPT_DIR/board/list.sh" "$filter" "$filter_value"
fi
exec sh "$SCRIPT_DIR/board/list.sh"
