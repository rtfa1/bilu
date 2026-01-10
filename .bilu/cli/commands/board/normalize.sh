#!/usr/bin/env sh
set -eu

warn() {
  printf "%s\n" "bilu board: warn: $*" >&2
}

lc() {
  LC_ALL=C printf "%s" "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_status() {
  raw=${1:-}
  context=${2:-}

  v=$(lc "$raw")
  case "$v" in
    done) printf "%s\n" "DONE" ;;
    "in progress"|"in-progress"|inprogress) printf "%s\n" "INPROGRESS" ;;
    "to do"|todo) printf "%s\n" "TODO" ;;
    backlog) printf "%s\n" "BACKLOG" ;;
    blocked) printf "%s\n" "BLOCKED" ;;
    review) printf "%s\n" "REVIEW" ;;
    archived) printf "%s\n" "ARCHIVED" ;;
    cancelled|canceled) printf "%s\n" "CANCELLED" ;;
    "")
      if [ -n "$context" ]; then
        warn "missing status; defaulting to TODO ($context)"
      else
        warn "missing status; defaulting to TODO"
      fi
      printf "%s\n" "TODO"
      ;;
    *)
      if [ -n "$context" ]; then
        warn "unknown status \"$raw\"; defaulting to TODO ($context)"
      else
        warn "unknown status \"$raw\"; defaulting to TODO"
      fi
      printf "%s\n" "TODO"
      ;;
  esac
}

normalize_priority() {
  raw=${1:-}
  context=${2:-}

  v=$(lc "$raw")
  case "$v" in
    critical) printf "%s\n" "CRITICAL" ;;
    high) printf "%s\n" "HIGH" ;;
    medium) printf "%s\n" "MEDIUM" ;;
    low) printf "%s\n" "LOW" ;;
    trivial) printf "%s\n" "TRIVIAL" ;;
    "")
      if [ -n "$context" ]; then
        warn "missing priority; defaulting to MEDIUM ($context)"
      else
        warn "missing priority; defaulting to MEDIUM"
      fi
      printf "%s\n" "MEDIUM"
      ;;
    *)
      if [ -n "$context" ]; then
        warn "unknown priority \"$raw\"; defaulting to MEDIUM ($context)"
      else
        warn "unknown priority \"$raw\"; defaulting to MEDIUM"
      fi
      printf "%s\n" "MEDIUM"
      ;;
  esac
}

normalize_kind() {
  raw=${1:-}
  context=${2:-}

  v=$(lc "$raw")
  case "$v" in
    task|bug|feature|improvement) printf "%s\n" "$v" ;;
    "")
      printf "%s\n" "task"
      ;;
    *)
      if [ -n "$context" ]; then
        warn "unknown kind \"$raw\"; defaulting to task ($context)"
      else
        warn "unknown kind \"$raw\"; defaulting to task"
      fi
      printf "%s\n" "task"
      ;;
  esac
}

tsv_escape() {
  LC_ALL=C printf "%s" "$1" | tr '\t\r\n' '   '
}

extract_known_tags_from_config() {
  config_path=${1:-}
  if [ -z "$config_path" ] || [ ! -f "$config_path" ]; then
    return 0
  fi

  awk '
    BEGIN { in_tags=0 }
    /^[[:space:]]*"tags"[[:space:]]*:[[:space:]]*{[[:space:]]*$/ { in_tags=1; next }
    in_tags && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ { in_tags=0; next }
    in_tags {
      if ($0 ~ /^[[:space:]]*"[^"]+"[[:space:]]*:/) {
        line=$0
        sub(/^[[:space:]]*"/, "", line)
        sub(/".*$/, "", line)
        print line
      }
    }
  ' "$config_path"
}

normalize_tags_csv() {
  raw=${1:-}
  context=${2:-}
  config_path=${BILU_BOARD_CONFIG_PATH:-}

  csv=$(LC_ALL=C printf "%s" "$raw" | awk -v RS= -v ORS= '
    {
      gsub(/\r/, "", $0)
      gsub(/[[:space:]]*,[[:space:]]*/, ",", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print
    }
  ')

  if [ -n "$csv" ] && [ -n "$config_path" ] && [ -f "$config_path" ]; then
    known=$(extract_known_tags_from_config "$config_path" | awk '{print}' | tr '\n' ' ')
    old_ifs=$IFS
    IFS=','
    set -- $csv
    IFS=$old_ifs
    for t in "$@"; do
      tag=$(LC_ALL=C printf "%s" "$t" | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print}')
      [ -z "$tag" ] && continue
      if ! printf "%s" " $known " | grep -F " $tag " >/dev/null 2>&1; then
        if [ -n "$context" ]; then
          warn "unknown tag \"$tag\"; keeping as-is ($context)"
        else
          warn "unknown tag \"$tag\"; keeping as-is"
        fi
      fi
    done
  fi

  printf "%s\n" "$csv"
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

cmd=${1:-}
shift 1 2>/dev/null || true

case "$cmd" in
  status)
    normalize_status "${1:-}" "${2:-}"
    ;;
  priority)
    normalize_priority "${1:-}" "${2:-}"
    ;;
  kind)
    normalize_kind "${1:-}" "${2:-}"
    ;;
  tags)
    normalize_tags_csv "${1:-}" "${2:-}"
    ;;
  tsv-escape)
    tsv_escape "${1:-}"
    printf "\n"
    ;;
  *)
    printf "%s\n" "Usage: normalize.sh {status|priority|kind|tags|tsv-escape} <value> [context]" >&2
    exit 2
    ;;
esac
