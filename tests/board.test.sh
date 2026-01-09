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

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list)"
printf "%s" "$out" | grep -F "board listing" >/dev/null

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter=status --filter-value=todo)"
printf "%s" "$out" | grep -F "status=todo" >/dev/null

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board -l -f status -fv todo)"
printf "%s" "$out" | grep -F "status=todo" >/dev/null

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --help)"
printf "%s" "$out" | grep -F "bilu board --list" >/dev/null

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --validate)"
printf "%s\n" "$out" | awk 'NR==1 { exit $0=="ok" ? 0 : 1 }'

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board -x >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "bilu board --list" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "bilu board --list" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter=status >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "bilu board --list" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter-value=todo >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "bilu board --list" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list -- --help >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "bilu board --list" "$tmp/err" >/dev/null

# Fatal validation error: duplicate config values should exit 1 and not print "ok".
rm -rf "$tmp/.bilu"
cp -R "$REPO_ROOT/.bilu" "$tmp/.bilu"
sed 's/"TODO": 1/"TODO": 0/' "$tmp/.bilu/board/config.json" >"$tmp/config.json"
mv "$tmp/config.json" "$tmp/.bilu/board/config.json"

set +e
NO_COLOR=1 sh "$tmp/.bilu/cli/bilu" board --validate >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 1
test ! -s "$tmp/out"
grep -F "config statuses values must be unique" "$tmp/err" >/dev/null

# Smoke check: board CLI should not require extra deps.
if grep -R -n -E '(^|[^[:alnum:]_])(jq|fzf|gum|dialog|whiptail)([^[:alnum:]_]|$)' "$REPO_ROOT/.bilu/cli" >/dev/null 2>&1; then
  echo "unexpected dependency referenced in .bilu/cli" >&2
  exit 1
fi
