#!/usr/bin/env sh
set -eu

error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

tsv_escape() {
  LC_ALL=C printf "%s" "${1:-}" | tr '\t\r\n' '   '
}

priority_weight() {
  config_path=$1
  key=$2
  w=$(
    awk -v KEY="$key" '
      BEGIN { in_prio=0 }
      /^[[:space:]]*"priorities"[[:space:]]*:[[:space:]]*{[[:space:]]*$/ { in_prio=1; next }
      in_prio && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ { in_prio=0; next }
      in_prio && match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]*,?[[:space:]]*$/, m) {
        if (m[1] == KEY) { print m[2]; exit }
      }
    ' "$config_path" 2>/dev/null || true
  )
  if [ -z "${w:-}" ]; then
    printf "%s\n" "0"
  else
    printf "%s\n" "$w"
  fi
}

board_load_tasks_from_md() {
  tasks_dir=${1:-}
  if [ -z "$tasks_dir" ] || [ ! -d "$tasks_dir" ]; then
    return 1
  fi

  abs_tasks_dir=$(
    CDPATH= cd -- "$tasks_dir" >/dev/null 2>&1
    pwd
  )
  board_root=$(
    CDPATH= cd -- "$abs_tasks_dir/.." >/dev/null 2>&1
    cd -- ".." >/dev/null 2>&1
    pwd
  )

  config_path="$board_root/board/config.json"
  normalize_sh="$(dirname -- "$0")/../normalize.sh"

  if [ ! -f "$config_path" ]; then
    error "missing config: $config_path"
    return 1
  fi

  find "$abs_tasks_dir" -maxdepth 1 -type f -name '*.md' -print |
    LC_ALL=C sort |
    while IFS= read -r path; do
      [ -z "$path" ] && continue
      base=${path##*/}
      id=${base%.md}
      link="board/tasks/$base"

      title=$(awk 'NR==1 && match($0, /^#[[:space:]]+(.*)$/, m) { print m[1]; exit }' "$path")
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
          if (match($0, /^[[:space:]]*-[[:space:]]*(.+)[[:space:]]*$/, m)) {
            v=m[1]
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
          if (match($0, /^[[:space:]]*-[[:space:]]*(.+)[[:space:]]*$/, m)) {
            v=m[1]
            if (out=="") out=v
            else out=out "," v
          }
        }
        END { print out }
      ' "$path")

      if [ -z "${title:-}" ]; then
        error "missing title in: $link"
        return 1
      fi

      n_status=$status
      n_priority=$priority
      n_kind=$kind
      n_tags=$tags_csv
      if [ -f "$normalize_sh" ]; then
        n_status=$(sh "$normalize_sh" status "${status:-}" "$link")
        n_priority=$(sh "$normalize_sh" priority "${priority:-}" "$link")
        n_kind=$(sh "$normalize_sh" kind "${kind:-}" "$link")
        n_tags=$(sh "$normalize_sh" tags "${tags_csv:-}" "$link")
      fi

      w=$(priority_weight "$config_path" "$n_priority")

      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$(tsv_escape "$id")" \
        "$(tsv_escape "$n_status")" \
        "$(tsv_escape "$w")" \
        "$(tsv_escape "$n_priority")" \
        "$(tsv_escape "$n_kind")" \
        "$(tsv_escape "$title")" \
        "$(tsv_escape "$path")" \
        "$(tsv_escape "$n_tags")" \
        "$(tsv_escape "${deps_csv:-}")" \
        "$(tsv_escape "$link")"
    done
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_load_tasks_from_md "$@"
