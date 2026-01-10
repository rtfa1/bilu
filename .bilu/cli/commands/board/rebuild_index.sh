#!/usr/bin/env sh
set -eu

error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

mktemp_file() {
  if command -v mktemp >/dev/null 2>&1; then
    f=$(mktemp 2>/dev/null || true)
    if [ -n "${f:-}" ]; then
      printf "%s\n" "$f"
      return 0
    fi
  fi
  ts=$(date +%s 2>/dev/null || echo "$$")
  printf "%s\n" "/tmp/bilu-board-rebuild.$$.$ts"
}

json_escape() {
  printf "%s" "$1" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); gsub(/\r/,""); print}'
}

trim() {
  printf "%s" "$1" | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print}'
}

template_root=${1:-}
dry_run=${2:-0}

if [ -z "$template_root" ]; then
  error "missing template_root"
  exit 2
fi

tasks_dir="$template_root/board/tasks"
config_path="$template_root/board/config.json"
index_path="$template_root/board/default.json"
normalize_sh="$(dirname -- "$0")/normalize.sh"
lock_sh="$(dirname -- "$0")/lib/lock.sh"

. "$lock_sh" 2>/dev/null || true

if [ ! -d "$tasks_dir" ]; then
  error "missing tasks dir: $tasks_dir"
  exit 1
fi
if [ ! -f "$config_path" ]; then
  error "missing config: $config_path"
  exit 1
fi

files_file=$(mktemp_file)
find "$tasks_dir" -maxdepth 1 -type f -name '*.md' -print >"$files_file"

sorted_file=$(mktemp_file)
awk -v TD="$tasks_dir/" '
  {
    f=$0
    gsub(TD, "", f)
    base=f
    nkey="999999"
    if (match(base, /^[0-9]+/)) {
      nkey=sprintf("%06d", substr(base, RSTART, RLENGTH) + 0)
    }
    printf "%s\t%s\n", nkey, base
  }
' "$files_file" | LC_ALL=C sort -k1,1 -k2,2 | awk -F '\t' '{print $2}' >"$sorted_file"

rm -f "$files_file" 2>/dev/null || true

total=$(awk 'NF{c++} END{print c+0}' "$sorted_file")

export BILU_BOARD_CONFIG_PATH=$config_path

out_tmp=$(mktemp_file)
printf "%s\n" "[" >"$out_tmp"

idx=0
fatal=0

while IFS= read -r base; do
  [ -z "$base" ] && continue
  idx=$((idx + 1))

  path="$tasks_dir/$base"
  link="board/tasks/$base"

  title=$(awk 'NR==1 { sub(/^#[[:space:]]+/, "", $0); print; exit }' "$path")
  desc=$(awk '
    BEGIN { in_section=0 }
    /^#[[:space:]]+Description[[:space:]]*$/ { in_section=1; next }
    in_section {
      if ($0 ~ /^# /) exit
      if ($0 ~ /^[[:space:]]*$/) next
      print
      exit
    }
  ' "$path")
  status=$(awk '
    BEGIN { in_section=0 }
    /^#[[:space:]]+Status[[:space:]]*$/ { in_section=1; next }
    in_section {
      if ($0 ~ /^# /) exit
      if ($0 ~ /^[[:space:]]*$/) next
      print
      exit
    }
  ' "$path")
  priority=$(awk '
    BEGIN { in_section=0 }
    /^#[[:space:]]+Priority[[:space:]]*$/ { in_section=1; next }
    in_section {
      if ($0 ~ /^# /) exit
      if ($0 ~ /^[[:space:]]*$/) next
      print
      exit
    }
  ' "$path")
  kind=$(awk '
    BEGIN { in_section=0 }
    /^#[[:space:]]+Kind[[:space:]]*$/ { in_section=1; next }
    in_section {
      if ($0 ~ /^# /) exit
      if ($0 ~ /^[[:space:]]*$/) next
      print
      exit
    }
  ' "$path")
  tags_csv=$(awk '
    BEGIN { in_section=0; out="" }
    /^#[[:space:]]+Tags[[:space:]]*$/ { in_section=1; next }
    in_section {
      if ($0 ~ /^# /) exit
      if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
        v=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", v)
        sub(/[[:space:]]*$/, "", v)
        if (out=="") out=v
        else out=out "," v
      }
    }
    END { print out }
  ' "$path")
  deps_csv=$(awk '
    BEGIN { in_section=0; out="" }
    /^#[[:space:]]+depends_on[[:space:]]*$/ { in_section=1; next }
    in_section {
      if ($0 ~ /^# /) exit
      if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
        v=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", v)
        sub(/[[:space:]]*$/, "", v)
        if (out=="") out=v
        else out=out "," v
      }
    }
    END { print out }
  ' "$path")

  if [ -z "$title" ]; then
    error "missing title in: $link"
    fatal=1
    break
  fi

  n_status=$status
  n_priority=$priority
  n_kind=$kind
  n_tags=$tags_csv

  if [ -f "$normalize_sh" ]; then
    n_status=$(sh "$normalize_sh" status "$status" "$link")
    n_priority=$(sh "$normalize_sh" priority "$priority" "$link")
    n_kind=$(sh "$normalize_sh" kind "$kind" "$link")
    n_tags=$(sh "$normalize_sh" tags "$tags_csv" "$link")
  fi

  printf "%s\n" "  {" >>"$out_tmp"
  printf "%s\n" "    \"title\": \"$(json_escape "$title")\"," >>"$out_tmp"
  printf "%s\n" "    \"description\": \"$(json_escape "$desc")\"," >>"$out_tmp"
  printf "%s\n" "    \"priority\": \"$(json_escape "$n_priority")\"," >>"$out_tmp"
  printf "%s\n" "    \"kind\": \"$(json_escape "$n_kind")\"," >>"$out_tmp"
  printf "%s\n" "    \"status\": \"$(json_escape "$n_status")\"," >>"$out_tmp"

  printf "%s\n" "    \"depends_on\": [" >>"$out_tmp"
  if [ -n "$deps_csv" ]; then
    old_ifs=$IFS
    IFS=','
    set -- $deps_csv
    IFS=$old_ifs
    dep_total=0
    for dep in "$@"; do
      dep=$(trim "$dep")
      [ -z "$dep" ] && continue
      dep_total=$((dep_total + 1))
    done
    dep_idx=0
    for dep in "$@"; do
      dep=$(trim "$dep")
      [ -z "$dep" ] && continue
      dep_idx=$((dep_idx + 1))
      if [ "$dep_idx" -lt "$dep_total" ]; then
        printf "%s\n" "      \"$(json_escape "$dep")\"," >>"$out_tmp"
      else
        printf "%s\n" "      \"$(json_escape "$dep")\"" >>"$out_tmp"
      fi
    done
  fi
  printf "%s\n" "    ]," >>"$out_tmp"

  printf "%s\n" "    \"tags\": [" >>"$out_tmp"
  if [ -n "$n_tags" ]; then
    old_ifs=$IFS
    IFS=','
    set -- $n_tags
    IFS=$old_ifs
    tag_total=0
    for tag in "$@"; do
      tag=$(trim "$tag")
      [ -z "$tag" ] && continue
      tag_total=$((tag_total + 1))
    done
    tag_idx=0
    for tag in "$@"; do
      tag=$(trim "$tag")
      [ -z "$tag" ] && continue
      tag_idx=$((tag_idx + 1))
      if [ "$tag_idx" -lt "$tag_total" ]; then
        printf "%s\n" "      \"$(json_escape "$tag")\"," >>"$out_tmp"
      else
        printf "%s\n" "      \"$(json_escape "$tag")\"" >>"$out_tmp"
      fi
    done
  fi
  printf "%s\n" "    ]," >>"$out_tmp"

  printf "%s\n" "    \"link\": \"$link\"" >>"$out_tmp"
  if [ "$idx" -lt "$total" ]; then
    printf "%s\n" "  }," >>"$out_tmp"
  else
    printf "%s\n" "  }" >>"$out_tmp"
  fi
done <"$sorted_file"

rm -f "$sorted_file" 2>/dev/null || true
printf "%s\n" "]" >>"$out_tmp"

if [ "$fatal" -ne 0 ]; then
  rm -f "$out_tmp" 2>/dev/null || true
  exit 1
fi

LOCK_DIR="$template_root/storage/lock"

if [ "$dry_run" -eq 1 ]; then
  changed=1
  if [ -f "$index_path" ] && cmp -s "$index_path" "$out_tmp"; then
    changed=0
  fi
  rm -f "$out_tmp" 2>/dev/null || true
  printf "%s\n" "ok"
  printf "%s\n" "tasks: $total"
  printf "%s\n" "changed: $changed"
  printf "%s\n" "dry-run: true"
  exit 0
fi

board_lock_acquire "$LOCK_DIR" 10 || { rm -f "$out_tmp"; exit 1; }
trap 'board_lock_release "$LOCK_DIR"' EXIT INT TERM HUP

if ! mv "$out_tmp" "$index_path"; then
  rm -f "$out_tmp" 2>/dev/null || true
  error "failed to write: $index_path"
  exit 1
fi

board_lock_release "$LOCK_DIR"
trap - EXIT

printf "%s\n" "ok"
printf "%s\n" "tasks: $total"
printf "%s\n" "written: $index_path"

