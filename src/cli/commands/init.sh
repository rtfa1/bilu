#!/usr/bin/env sh
set -eu

err() {
  printf "%s\n" "bilu: $*" >&2
}

TEMPLATE_ROOT=${BILU_TEMPLATE_ROOT:-""}
if [ -z "$TEMPLATE_ROOT" ]; then
  err "BILU_TEMPLATE_ROOT is not set"
  exit 1
fi

TARGET_ROOT="${PWD}/.bilu"

if [ -e "$TARGET_ROOT" ]; then
  err "$TARGET_ROOT exists; refusing to overwrite"
  exit 2
fi

for d in board prompts skills cli; do
  if [ ! -d "$TEMPLATE_ROOT/$d" ]; then
    err "missing template directory: $TEMPLATE_ROOT/$d"
    exit 1
  fi
done

mkdir -p "$TARGET_ROOT"
cp -R "$TEMPLATE_ROOT/board" "$TARGET_ROOT/board"
cp -R "$TEMPLATE_ROOT/prompts" "$TARGET_ROOT/prompts"
cp -R "$TEMPLATE_ROOT/skills" "$TARGET_ROOT/skills"
cp -R "$TEMPLATE_ROOT/cli" "$TARGET_ROOT/cli"

installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mkdir -p "$TARGET_ROOT/storage" "$TARGET_ROOT/bin"
cp "$TARGET_ROOT/cli/bilu" "$TARGET_ROOT/bin/bilu"
chmod +x "$TARGET_ROOT/bin/bilu" >/dev/null 2>&1 || true
cat >"$TARGET_ROOT/storage/config.json" <<EOF
{
  "installed": true,
  "installed_at": "$installed_at"
}
EOF
