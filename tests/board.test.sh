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
  d="$REPO_ROOT/.tmp-board-test.$$"
  mkdir -p "$d"
  printf "%s\n" "$d"
}

tmp="$(mktemp_dir)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

out="$(sh "$REPO_ROOT/.bilu/cli/bilu" board --list)"
printf "%s" "$out" | grep -F "board listing" >/dev/null

out="$(sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter=status --filter-value=todo)"
printf "%s" "$out" | grep -F "status=todo" >/dev/null

out="$(sh "$REPO_ROOT/.bilu/cli/bilu" board -l -f status -fv todo)"
printf "%s" "$out" | grep -F "status=todo" >/dev/null

set +e
sh "$REPO_ROOT/.bilu/cli/bilu" board -x 2>/dev/null
status=$?
set -e
test "$status" -ne 0
