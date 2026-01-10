#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

for t in "$SCRIPT_DIR"/*.test.sh; do
  sh "$t"
done

echo "ok"

