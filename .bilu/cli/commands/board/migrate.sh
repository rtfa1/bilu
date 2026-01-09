#!/usr/bin/env sh
set -eu

error() {
  printf "%s\n" "bilu board: error: $*" >&2
}

warn() {
  printf "%s\n" "bilu board: warn: $*" >&2
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
  printf "%s\n" "/tmp/bilu-board-migrate.$$.$ts"
}

template_root=${1:-}
dry_run=${2:-0}

if [ -z "$template_root" ]; then
  error "missing template_root"
  exit 2
fi

index_path="$template_root/board/default.json"
tasks_dir="$template_root/board/tasks"
config_path="$template_root/board/config.json"
normalize_sh="$(dirname -- "$0")/normalize.sh"

if [ ! -f "$index_path" ]; then
  error "missing index: $index_path"
  exit 1
fi
if [ ! -d "$tasks_dir" ]; then
  error "missing tasks dir: $tasks_dir"
  exit 1
fi

records_file=$(mktemp_file)

awk '
  BEGIN {
    in_obj=0
    in_dep=0
    in_tags=0
    idx=0
  }
  function reset_obj() {
    title=""
    desc=""
    status=""
    priority=""
    kind=""
    link=""
    deps=""
    tags=""
    in_dep=0
    in_tags=0
  }
  /^[[:space:]]*{[[:space:]]*$/ {
    in_obj=1
    reset_obj()
    next
  }
  in_obj && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ {
    idx++
    printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", idx, link, title, desc, status, priority, kind, tags, deps
    in_obj=0
    next
  }
  !in_obj { next }
  {
    line=$0
    if (match(line, /^[[:space:]]*"title"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) title=m[1]
    if (match(line, /^[[:space:]]*"description"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) desc=m[1]
    if (match(line, /^[[:space:]]*"status"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) status=m[1]
    if (match(line, /^[[:space:]]*"priority"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) priority=m[1]
    if (match(line, /^[[:space:]]*"kind"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) kind=m[1]
    if (match(line, /^[[:space:]]*"link"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) link=m[1]

    if (match(line, /^[[:space:]]*"tags"[[:space:]]*:[[:space:]]*[[]/)) {
      in_tags=1
      if (index(line, "]") > 0) in_tags=0
      next
    }
    if (in_tags && match(line, /"([^"]+)"/, m)) {
      if (tags == "") tags=m[1]
      else tags=tags "," m[1]
    }
    if (in_tags && index(line, "]") > 0) { in_tags=0 }

    if (match(line, /^[[:space:]]*"depends_on"[[:space:]]*:[[:space:]]*[[]/)) {
      in_dep=1
      if (index(line, "]") > 0) in_dep=0
      next
    }
    if (in_dep && match(line, /"([^"]+)"/, m)) {
      if (deps == "") deps=m[1]
      else deps=deps "," m[1]
    }
    if (in_dep && index(line, "]") > 0) { in_dep=0 }
  }
' "$index_path" >"$records_file"

changed=0
fatal=0
count=0

export BILU_BOARD_CONFIG_PATH=$config_path

while IFS='	' read -r idx link title desc status priority kind tags_csv deps_csv; do
  count=$((count + 1))
  if [ -z "$link" ]; then
    warn "missing link (index[$idx]); skipping"
    continue
  fi

  path="$template_root/$link"
  if [ ! -f "$path" ]; then
    warn "link target missing: $link (index[$idx])"
    continue
  fi

  context=$link
  n_status=$status
  n_priority=$priority
  n_kind=$kind
  n_tags=$tags_csv

  if [ -f "$normalize_sh" ]; then
    n_status=$(sh "$normalize_sh" status "$status" "$context")
    n_priority=$(sh "$normalize_sh" priority "$priority" "$context")
    n_kind=$(sh "$normalize_sh" kind "$kind" "$context")
    n_tags=$(sh "$normalize_sh" tags "$tags_csv" "$context")
  fi

  tmp=$(mktemp_file)

  awk -v DESC="$desc" -v STATUS="$n_status" -v PRIORITY="$n_priority" -v KIND="$n_kind" -v TAGS_CSV="$n_tags" -v DEPS_CSV="$deps_csv" '
      function emit_block(name,    csv, n, i, v) {
        if (name == "Description") {
          print "# Description"
          if (DESC != "") print DESC
          else print ""
          return
        }
        if (name == "Status") { print "# Status"; print STATUS; return }
        if (name == "Priority") { print "# Priority"; print PRIORITY; return }
        if (name == "Kind") { print "# Kind"; print KIND; return }
        if (name == "Tags") {
          print "# Tags"
          csv=TAGS_CSV
          if (csv == "") return
          n=split(csv, a, ",")
          for (i=1; i<=n; i++) {
            v=a[i]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            if (v != "") print "- " v
          }
          return
        }
        if (name == "depends_on") {
          print "# depends_on"
          csv=DEPS_CSV
          if (csv == "") return
          n=split(csv, a, ",")
          for (i=1; i<=n; i++) {
            v=a[i]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            if (v != "") print "- " v
          }
          return
        }
      }

      function is_managed_header(line,    h) {
        if (match(line, /^# (Description|Status|Priority|Kind|Tags|depends_on)[[:space:]]*$/, h)) {
          managed=h[1]
          return 1
        }
        managed=""
        return 0
      }

      BEGIN {
        skipping=0
        saw_desc=0
        saw_status=0
        saw_priority=0
        saw_kind=0
        saw_tags=0
        saw_deps=0
      }
      {
        line=$0

        if (skipping) {
          if (line ~ /^# /) {
            skipping=0
          } else {
            next
          }
        }

        if (is_managed_header(line)) {
          if (managed == "Description") saw_desc=1
          if (managed == "Status") saw_status=1
          if (managed == "Priority") saw_priority=1
          if (managed == "Kind") saw_kind=1
          if (managed == "Tags") saw_tags=1
          if (managed == "depends_on") saw_deps=1

          emit_block(managed)
          skipping=1
          next
        }

        print line
      }
      END {
        if (!saw_desc) { print ""; emit_block("Description") }
        if (!saw_status) { print ""; emit_block("Status") }
        if (!saw_priority) { print ""; emit_block("Priority") }
        if (!saw_kind) { print ""; emit_block("Kind") }
        if (!saw_tags) { print ""; emit_block("Tags") }
        if (!saw_deps) { print ""; emit_block("depends_on") }
      }
    ' "$path" >"$tmp"

  if cmp -s "$path" "$tmp"; then
    rm -f "$tmp" 2>/dev/null || true
    continue
  fi

  changed=$((changed + 1))
  if [ "$dry_run" -eq 1 ]; then
    rm -f "$tmp" 2>/dev/null || true
    continue
  fi

  if ! mv "$tmp" "$path"; then
    rm -f "$tmp" 2>/dev/null || true
    error "failed to write: $path"
    fatal=1
    break
  fi
done <"$records_file"

rm -f "$records_file" 2>/dev/null || true

if [ "$fatal" -ne 0 ]; then
  exit 1
fi

printf "%s\n" "ok"
printf "%s\n" "tasks: $count"
printf "%s\n" "changed: $changed"
if [ "$dry_run" -eq 1 ]; then
  printf "%s\n" "dry-run: true"
fi
