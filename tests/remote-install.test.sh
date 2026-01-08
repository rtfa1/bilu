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
if ! command -v tar >/dev/null 2>&1; then
  echo "skip: tar not found"
  exit 0
fi

tmp="$(mktemp -d 2>/dev/null || true)"
if [ -z "${tmp:-}" ] || [ ! -d "$tmp" ]; then
  tmp="$REPO_ROOT/.tmp-remote-install.$$"
  mkdir -p "$tmp"
fi
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

# Simulate a "GitHub tarball" locally (top-level folder like bilu-main/).
stage="$tmp/stage/bilu-main"
mkdir -p "$stage"
cp -R "$REPO_ROOT/src" "$stage/src"
cp -R "$REPO_ROOT/scripts" "$stage/scripts"

archive="$tmp/archive.tgz"
tar -czf "$archive" -C "$tmp/stage" bilu-main

install_dir="$tmp/install"
mkdir -p "$install_dir"

# Simulate: /bin/bash -c "$(curl -fsSL .../scripts/install.sh)"
(cd "$install_dir" && BILU_ARCHIVE_URL="file://$archive" /bin/bash -c "$(cat "$REPO_ROOT/scripts/install.sh")")

test -d "$install_dir/.bilu"
test -x "$install_dir/.bilu/cli/bilu"
"$install_dir/.bilu/cli/bilu" version >/dev/null
