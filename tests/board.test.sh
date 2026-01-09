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

assert_no_ansi() {
  # Basic check for SGR escape sequences: ESC[
  awk 'index($0, sprintf("%c[", 27)) { found=1 } END { exit found ? 1 : 0 }'
}

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(sh "$REPO_ROOT/.bilu/cli/bilu" board --list)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 COLUMNS=120 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --view=kanban)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | grep -F "Backlog" >/dev/null
printf "%s" "$out" | grep -F "In Progress" >/dev/null
printf "%s" "$out" | grep -F "Review" >/dev/null
printf "%s" "$out" | grep -F "Done" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(
  cd "$REPO_ROOT/storage"
  NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list
)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter=status --filter-value=todo)"
printf "%s" "$out" | grep -F "status=todo" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board -l -f status -fv todo)"
printf "%s" "$out" | grep -F "status=todo" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --help)"
printf "%s" "$out" | grep -F "Usage:" >/dev/null
printf "%s" "$out" | grep -F "bilu board --list" >/dev/null
printf "%s" "$out" | grep -F -- "--no-color" >/dev/null

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --no-color)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --validate)"
printf "%s\n" "$out" | awk 'NR==1 { exit $0=="ok" ? 0 : 1 }'

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board -x >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "unknown option" "$tmp/err" >/dev/null
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter=status >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F -- "--filter-value is required" "$tmp/err" >/dev/null
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter-value=todo >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F -- "--filter is required" "$tmp/err" >/dev/null
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter status >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F -- "--filter-value is required" "$tmp/err" >/dev/null
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --filter-value todo >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F -- "--filter is required" "$tmp/err" >/dev/null
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --filter=status --filter-value=todo >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "Usage:" "$tmp/err" >/dev/null

set +e
NO_COLOR=1 sh "$REPO_ROOT/.bilu/cli/bilu" board --list -- --help >"$tmp/out" 2>"$tmp/err"
status=$?
set -e
test "$status" -eq 2
grep -F "Usage:" "$tmp/err" >/dev/null

# Fatal validation error: duplicate config values should exit 1 and not print "ok".
rm -rf "$tmp/.bilu"
cp -R "$REPO_ROOT/.bilu" "$tmp/.bilu"
sed 's/"TODO": 1/"TODO": 0/' "$tmp/.bilu/board/config.json" >"$tmp/config.json"
mv "$tmp/config.json" "$tmp/.bilu/board/config.json"

set +e
(
  cd "$tmp"
  NO_COLOR=1 sh "$tmp/.bilu/cli/bilu" board --validate >"$tmp/out" 2>"$tmp/err"
)
status=$?
set -e
test "$status" -eq 1
test ! -s "$tmp/out"
grep -F "config statuses values must be unique" "$tmp/err" >/dev/null

# Layout detection should prefer a local project .bilu over the caller's script_dir.
mkdir -p "$tmp/proj/sub"
cp -R "$REPO_ROOT/.bilu" "$tmp/proj/.bilu"
default_json_path="$(
  cd "$tmp/proj/sub"
  sh -c '
    . "$1/.bilu/cli/commands/board/paths.sh"
    board_detect_paths "$1/.bilu/cli/commands"
    board_default_json_path
  ' sh "$REPO_ROOT"
)"
test "$default_json_path" = "$tmp/proj/.bilu/board/default.json"

# Smoke check: board CLI should not require extra deps.
if grep -R -n -E '(^|[^[:alnum:]_])(jq|fzf|gum|dialog|whiptail)([^[:alnum:]_]|$)' "$REPO_ROOT/.bilu/cli" >/dev/null 2>&1; then
  echo "unexpected dependency referenced in .bilu/cli" >&2
  exit 1
fi
