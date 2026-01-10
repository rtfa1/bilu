#!/usr/bin/env sh
set -eu

REPO_ROOT=$(
  CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1
  pwd
)

mktemp_dir() {
  if command -v mktemp >/dev/null 2>&1; then
    d=$(mktemp -d 2>/dev/null || true)
    if [ -n "${d:-}" ] && [ -d "$d" ]; then
      printf "%s\n" "$d"
      return 0
    fi
  fi
  d="$REPO_ROOT/.tmp-cache-test.$$"
  mkdir -p "$d"
  printf "%s\n" "$d"
}

tmp="$(mktemp_dir)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

# Copy bilu structure to avoid mutating the repo.
cp -R "$REPO_ROOT/.bilu" "$tmp/.bilu"

out="$(NO_COLOR=1 sh "$tmp/.bilu/cli/bilu" board --rebuild-cache --dry-run)"
printf "%s" "$out" | grep -F "ok" >/dev/null
printf "%s" "$out" | grep -F "records:" >/dev/null

NO_COLOR=1 sh "$tmp/.bilu/cli/bilu" board --rebuild-cache >/dev/null
test -f "$tmp/.bilu/board/records.tsv"

awk -F '\t' '
  BEGIN { n=0; fatal=0 }
  {
    n++
    if (NF != 10) fatal=1
    if ($1=="" || $2=="" || $4=="" || $6=="" || $7=="" || $10=="") fatal=1
    if ($7 !~ /^\//) fatal=1
    if ($10 !~ /^board\/tasks\/.+\.md$/) fatal=1
  }
  END {
    if (n == 0) exit 1
    exit fatal ? 1 : 0
  }
' "$tmp/.bilu/board/records.tsv"
