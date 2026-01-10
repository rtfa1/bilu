#!/usr/bin/env sh
set -eu

error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

warn() {
  printf "%s\n" "bilu board: warn: $*" >&2
}

tsv_escape() {
  # Hard rule: TSV fields must not contain literal tabs/newlines.
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
      in_prio && $0 ~ /^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]*,?[[:space:]]*$/ {
        line=$0
        sub(/^[[:space:]]*"/, "", line)
        key=line
        sub(/".*$/, "", key)
        val=line
        sub(/^.*:[[:space:]]*/, "", val)
        sub(/[[:space:]]*,?[[:space:]]*$/, "", val)
        if (key == KEY) { print val; exit }
      }
    ' "$config_path" 2>/dev/null || true
  )
  if [ -z "${w:-}" ]; then
    printf "%s\n" "0"
  else
    printf "%s\n" "$w"
  fi
}

board_root=${1:-}
if [ -z "$board_root" ]; then
  error "missing board_root"
  exit 2
fi

config_path="$board_root/board/config.json"
index_path="$board_root/board/default.json"
normalize_sh="$(dirname -- "$0")/normalize.sh"

if [ ! -f "$config_path" ]; then
  error "missing config: $config_path"
  exit 1
fi
if [ ! -f "$index_path" ]; then
  error "missing index: $index_path"
  exit 1
fi

awk '
  BEGIN {
    in_obj=0
    in_dep=0
    in_tags=0
    idx=0
  }
  function reset_obj() {
    title=""
    status=""
    priority=""
    kind=""
    link=""
    deps=""
    tags=""
    in_dep=0
    in_tags=0
  }
  /^[[:space:]]*{[[:space:]]*$/ { in_obj=1; reset_obj(); next }
  in_obj && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ {
    idx++
    printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", idx, title, status, priority, kind, link, tags, deps
    in_obj=0
    next
  }
  !in_obj { next }
  {
    line=$0
    if (line ~ /^[[:space:]]*"title"[[:space:]]*:/) {
      v=line; sub(/^[[:space:]]*"title"[[:space:]]*:[[:space:]]*"/, "", v); sub(/".*$/, "", v); title=v
    }
    if (line ~ /^[[:space:]]*"status"[[:space:]]*:/) {
      v=line; sub(/^[[:space:]]*"status"[[:space:]]*:[[:space:]]*"/, "", v); sub(/".*$/, "", v); status=v
    }
    if (line ~ /^[[:space:]]*"priority"[[:space:]]*:/) {
      v=line; sub(/^[[:space:]]*"priority"[[:space:]]*:[[:space:]]*"/, "", v); sub(/".*$/, "", v); priority=v
    }
    if (line ~ /^[[:space:]]*"kind"[[:space:]]*:/) {
      v=line; sub(/^[[:space:]]*"kind"[[:space:]]*:[[:space:]]*"/, "", v); sub(/".*$/, "", v); kind=v
    }
    if (line ~ /^[[:space:]]*"link"[[:space:]]*:/) {
      v=line; sub(/^[[:space:]]*"link"[[:space:]]*:[[:space:]]*"/, "", v); sub(/".*$/, "", v); link=v
    }

    if (match(line, /^[[:space:]]*"tags"[[:space:]]*:[[:space:]]*[[]/)) {
      in_tags=1
      if (index(line, "]") > 0) in_tags=0
      next
    }
    if (in_tags && match(line, /"[^"]+"/)) {
      v=substr(line, RSTART+1, RLENGTH-2)
      if (tags == "") tags=v
      else tags=tags "," v
    }
    if (in_tags && index(line, "]") > 0) { in_tags=0 }

    if (match(line, /^[[:space:]]*"depends_on"[[:space:]]*:[[:space:]]*[[]/)) {
      in_dep=1
      if (index(line, "]") > 0) in_dep=0
      next
    }
    if (in_dep && match(line, /"[^"]+"/)) {
      v=substr(line, RSTART+1, RLENGTH-2)
      if (deps == "") deps=v
      else deps=deps "," v
    }
    if (in_dep && index(line, "]") > 0) { in_dep=0 }
  }
' "$index_path" |
  while IFS='	' read -r idx title status priority kind link tags_csv deps_csv; do
    context="index[$idx]"
    if [ -n "${link:-}" ]; then
      context=$link
    fi

    if [ -z "${title:-}" ]; then
      warn "missing title ($context); skipping"
      continue
    fi
    if [ -z "${link:-}" ]; then
      warn "missing link ($context); skipping"
      continue
    fi

    id=${link##*/}
    id=${id%.md}
    path="$board_root/$link"

    n_status=$status
    n_priority=$priority
    n_kind=$kind
    n_tags=$tags_csv

    if [ -f "$normalize_sh" ]; then
      n_status=$(sh "$normalize_sh" status "${status:-}" "$context")
      n_priority=$(sh "$normalize_sh" priority "${priority:-}" "$context")
      n_kind=$(sh "$normalize_sh" kind "${kind:-}" "$context")
      n_tags=$(sh "$normalize_sh" tags "${tags_csv:-}" "$context")
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

