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
  d="$REPO_ROOT/.tmp-test.$$"
  mkdir -p "$d"
  printf "%s\n" "$d"
}

tmp="$(mktemp_dir)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

(cd "$tmp" && sh "$REPO_ROOT/src/cli/bilu" init)

test -d "$tmp/.bilu"
for name in board prompts skills storage cli bin; do
  test -d "$tmp/.bilu/$name"
done
test -f "$tmp/.bilu/storage/config.json"

mkdir -p "$tmp/dir2/.bilu"
echo keep >"$tmp/dir2/.bilu/keep.txt"
set +e
out="$(cd "$tmp/dir2" && sh "$REPO_ROOT/src/cli/bilu" init 2>&1)"
status=$?
set -e
test "$status" -ne 0
printf "%s" "$out" | grep -Ei "\.bilu.*refusing to overwrite" >/dev/null
test -f "$tmp/dir2/.bilu/keep.txt"
