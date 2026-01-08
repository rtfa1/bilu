#!/usr/bin/env bash
set -euo pipefail
# BILU_SRC_DIR="/Users/rtfa/lab/bilu"
REPO_SLUG="${BILU_REPO_SLUG:-rtfa1/bilu}"
REF="${BILU_REF:-main}"
https://github.com/rtfa1/bilu
TARGET_DIR="${BILU_DIR:-$PWD/.bilu}"
SHORTCUT_PATH="${BILU_SHORTCUT_PATH:-$PWD/bilu}"
SHORTCUT_FORCE="${BILU_SHORTCUT_FORCE:-0}"

if [[ -e "$TARGET_DIR" ]]; then
  echo "bilu install: $TARGET_DIR exists; refusing to overwrite" >&2
  exit 2
fi

tmp_dir="$(mktemp -d 2>/dev/null || true)"
if [[ -z "${tmp_dir:-}" || ! -d "$tmp_dir" ]]; then
  echo "bilu install: mktemp -d failed" >&2
  exit 1
fi
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

repo_dir=""
if [[ -n "${BILU_SRC_DIR:-}" ]]; then
  repo_dir="$BILU_SRC_DIR"
else
  archive_url="${BILU_ARCHIVE_URL:-https://codeload.github.com/$REPO_SLUG/tar.gz/$REF}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$archive_url" | tar -xzf - -C "$tmp_dir"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$archive_url" | tar -xzf - -C "$tmp_dir"
  else
    echo "bilu install: need curl or wget to download source" >&2
    exit 1
  fi

  extracted="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "${extracted:-}" || ! -d "$extracted" ]]; then
    echo "bilu install: failed to extract source archive" >&2
    exit 1
  fi
  repo_dir="$extracted"
fi

for p in "$repo_dir/src/board" "$repo_dir/src/prompts" "$repo_dir/src/skills" "$repo_dir/src/cli"; do
  if [[ ! -d "$p" ]]; then
    echo "bilu install: missing expected path: $p" >&2
    exit 1
  fi
done

mkdir -p "$TARGET_DIR"

cp -R "$repo_dir/src/board" "$TARGET_DIR/board"
cp -R "$repo_dir/src/prompts" "$TARGET_DIR/prompts"
cp -R "$repo_dir/src/skills" "$TARGET_DIR/skills"
cp -R "$repo_dir/src/cli" "$TARGET_DIR/cli"

mkdir -p "$TARGET_DIR/storage"
chmod +x "$TARGET_DIR/cli/bilu" || true

if [[ "${BILU_SHORTCUT:-1}" != "0" ]]; then
  if [[ -e "$SHORTCUT_PATH" && "$SHORTCUT_FORCE" != "1" ]]; then
    echo "bilu install: shortcut exists; skipping: $SHORTCUT_PATH" >&2
  else
    shortcut_dir="$(cd -- "$(dirname -- "$SHORTCUT_PATH")" >/dev/null 2>&1 && pwd)"
    mkdir -p "$shortcut_dir"

    target_abs="$(cd -- "$TARGET_DIR" >/dev/null 2>&1 && pwd)"
    if [[ "$target_abs" = "$shortcut_dir/.bilu" ]]; then
      cat >"$SHORTCUT_PATH" <<'EOF'
#!/usr/bin/env sh
set -eu
exec "$(dirname -- "$0")/.bilu/cli/bilu" "$@"
EOF
    else
      cat >"$SHORTCUT_PATH" <<EOF
#!/usr/bin/env sh
set -eu
exec "$target_abs/cli/bilu" "\$@"
EOF
    fi
    chmod +x "$SHORTCUT_PATH" || true
  fi
fi

installed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cat >"$TARGET_DIR/storage/config.json" <<EOF
{
  "installed": true,
  "installed_at": "$installed_at"
}
EOF

echo "Installed bilu into: $TARGET_DIR"
echo "Run: $TARGET_DIR/cli/bilu help"
