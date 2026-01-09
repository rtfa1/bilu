#!/usr/bin/env sh
set -eu

REPO_ROOT=$(
  CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1
  pwd
)

if ! command -v bash >/dev/null 2>&1; then
  echo "skip: bash not found"
  exit 0
fi

tmp="$(mktemp -d 2>/dev/null || true)"
if [ -z "${tmp:-}" ] || [ ! -d "$tmp" ]; then
  tmp="$REPO_ROOT/.tmp-install.$$"
  mkdir -p "$tmp"
fi
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

(cd "$tmp" && BILU_SRC_DIR="$REPO_ROOT" bash "$REPO_ROOT/scripts/install.sh")

test -d "$tmp/.bilu"
test -d "$tmp/.bilu/board"
test -d "$tmp/.bilu/prompts"
test -d "$tmp/.bilu/skills"
test -d "$tmp/.bilu/storage"
test -d "$tmp/.bilu/cli"
test -x "$tmp/.bilu/cli/bilu"
test -x "$tmp/bilu"

"$tmp/bilu" version >/dev/null

out="$("$tmp/bilu" board --list)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
