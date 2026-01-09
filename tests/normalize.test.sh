#!/usr/bin/env sh
set -eu

REPO_ROOT=$(
  CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1
  pwd
)

norm="$REPO_ROOT/.bilu/cli/commands/board/normalize.sh"

out="$(sh "$norm" status Done)"
test "$out" = "DONE"

out="$(sh "$norm" status in-progress)"
test "$out" = "INPROGRESS"

out="$(sh "$norm" priority High)"
test "$out" = "HIGH"

out="$(sh "$norm" kind Feature)"
test "$out" = "feature"

set +e
out="$(sh "$norm" status Doing 2>"$REPO_ROOT/.tmp-norm-err")"
status=$?
set -e
test "$status" -eq 0
test "$out" = "TODO"
grep -F "bilu board: warn: unknown status" "$REPO_ROOT/.tmp-norm-err" >/dev/null
rm -f "$REPO_ROOT/.tmp-norm-err"

export BILU_BOARD_CONFIG_PATH="$REPO_ROOT/.bilu/board/config.json"
set +e
out="$(sh "$norm" tags "frontend,unknown" 2>"$REPO_ROOT/.tmp-norm-err")"
status=$?
set -e
test "$status" -eq 0
test "$out" = "frontend,unknown"
grep -F "bilu board: warn: unknown tag" "$REPO_ROOT/.tmp-norm-err" >/dev/null
rm -f "$REPO_ROOT/.tmp-norm-err"
