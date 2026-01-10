#!/usr/bin/env sh
set -eu

error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

mktemp_file() {
  if command -v mktemp >/dev/null 2>&1; then
    f=$(mktemp 2>/dev/null || true)
    if [ -n "${f:-}" ]; then
      printf "%s\n" "$f"
      return 0
    fi
  fi
  ts=$(date +%s 2>/dev/null || echo "$$")
  printf "%s\n" "/tmp/bilu-board-rebuild-cache.$$.$ts"
}

template_root=${1:-}
dry_run=${2:-0}

if [ -z "$template_root" ]; then
  error "missing template_root"
  exit 2
fi

records_sh="$(dirname -- "$0")/records_tsv.sh"
lock_sh="$(dirname -- "$0")/lib/lock.sh"
out_path="$template_root/board/records.tsv"

if [ ! -f "$records_sh" ]; then
  error "missing records generator: $records_sh"
  exit 1
fi
if [ ! -d "$template_root/board" ]; then
  error "missing board dir: $template_root/board"
  exit 1
fi

# Best-effort lock support (same mechanism used for edits/rebuild-index).
. "$lock_sh" 2>/dev/null || true

tmp=$(mktemp_file)
if ! sh "$records_sh" "$template_root" >"$tmp"; then
  rm -f "$tmp" 2>/dev/null || true
  error "failed to generate TSV records"
  exit 1
fi

count=$(awk 'NF{c++} END{print c+0}' "$tmp")

if [ "$dry_run" -eq 1 ]; then
  changed=1
  if [ -f "$out_path" ] && cmp -s "$out_path" "$tmp"; then
    changed=0
  fi
  rm -f "$tmp" 2>/dev/null || true
  printf "%s\n" "ok"
  printf "%s\n" "records: $count"
  printf "%s\n" "changed: $changed"
  exit 0
fi

lock_dir="$template_root/storage/lock"
if command -v board_lock_acquire >/dev/null 2>&1; then
  board_lock_acquire "$lock_dir" 10 || {
    rm -f "$tmp" 2>/dev/null || true
    exit 1
  }
  trap 'board_lock_release "$lock_dir"; rm -f "$tmp"' EXIT INT TERM HUP
fi

if ! mv "$tmp" "$out_path"; then
  error "failed to write cache: $out_path"
  exit 1
fi

if command -v board_lock_release >/dev/null 2>&1; then
  board_lock_release "$lock_dir" || true
  trap - EXIT
fi

printf "%s\n" "ok"
printf "%s\n" "records: $count"
printf "%s\n" "path: $out_path"
