#!/usr/bin/env sh
set -eu

REPO_ROOT=$(
  CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1
  pwd
)

records_sh="$REPO_ROOT/.bilu/cli/commands/board/records_tsv.sh"

sh "$records_sh" "$REPO_ROOT/.bilu" |
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
  '

