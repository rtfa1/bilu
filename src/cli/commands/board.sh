#!/usr/bin/env sh
set -eu

err() {
  printf "%s\n" "bilu board: $*" >&2
}

usage() {
  cat <<'EOF'
Usage: bilu board --list [--filter <name> --filter-value <value>]

Options:
  --list, -l                 List board items
  --filter, -f <name>        Filter field name (e.g. status)
  --filter-value, -fv <val>  Filter value (e.g. todo)
  --help, -h                 Show this help
EOF
}

list=0
filter=""
filter_value=""

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
    --filter|-f)
      shift
      if [ $# -lt 1 ]; then
        err "missing value for $arg"
        exit 2
      fi
      filter=$1
      shift
      ;;
    --filter=*|-f=*)
      filter=${arg#*=}
      shift
      ;;
    --filter-value|-fv)
      shift
      if [ $# -lt 1 ]; then
        err "missing value for $arg"
        exit 2
      fi
      filter_value=$1
      shift
      ;;
    --filter-value=*|-fv=*)
      filter_value=${arg#*=}
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      err "unknown option: $arg"
      usage >&2
      exit 2
      ;;
    *)
      err "unexpected argument: $arg"
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$list" -ne 1 ]; then
  err "missing action (use --list)"
  usage >&2
  exit 2
fi

if [ -n "$filter" ] && [ -z "$filter_value" ]; then
  err "--filter-value is required when --filter is set"
  exit 2
fi
if [ -z "$filter" ] && [ -n "$filter_value" ]; then
  err "--filter is required when --filter-value is set"
  exit 2
fi

if [ -n "$filter" ]; then
  printf "board listing (filter: %s=%s)\n" "$filter" "$filter_value"
else
  printf "%s\n" "board listing"
fi
