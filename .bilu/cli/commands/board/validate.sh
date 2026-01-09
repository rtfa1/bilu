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
  printf "%s\n" "/tmp/bilu-board-validate.$$.$ts"
}

validate_config() {
  config_path=$1
  if [ ! -f "$config_path" ]; then
    error "missing config: $config_path"
    return 1
  fi

  # Validate required top-level keys and uniqueness of map values.
  awk '
    function bump_depth(line,    tmp, o, c) {
      tmp=line
      o=gsub(/{/, "{", tmp)
      c=gsub(/}/, "}", tmp)
      depth += (o - c)
    }
    BEGIN {
      depth=0
      saw_statuses=0
      saw_priorities=0
      saw_kind=0
      saw_tags=0
      in_statuses=0
      in_priorities=0
      fatal=0
    }
    {
      line=$0

      # Detect top-level keys when inside the root object.
      if (depth==1) {
        if (match(line, /^[[:space:]]*"statuses"[[:space:]]*:/)) saw_statuses=1
        if (match(line, /^[[:space:]]*"priorities"[[:space:]]*:/)) saw_priorities=1
        if (match(line, /^[[:space:]]*"kind"[[:space:]]*:/)) saw_kind=1
        if (match(line, /^[[:space:]]*"tags"[[:space:]]*:/)) saw_tags=1
      }

      # Enter/exit the statuses/priorities objects.
      if (match(line, /^[[:space:]]*"statuses"[[:space:]]*:[[:space:]]*{[[:space:]]*$/)) in_statuses=1
      if (match(line, /^[[:space:]]*"priorities"[[:space:]]*:[[:space:]]*{[[:space:]]*$/)) in_priorities=1
      if (in_statuses) {
        if (match(line, /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/)) in_statuses=0
        if (match(line, /^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]*,?[[:space:]]*$/, m)) {
          v=m[2]
          if (seen_status[v]++) {
            print "bilu board: error: config statuses values must be unique (duplicate: " v ")" >"/dev/stderr"
            fatal=1
          }
        }
      }
      if (in_priorities) {
        if (match(line, /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/)) in_priorities=0
        if (match(line, /^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]*,?[[:space:]]*$/, m)) {
          v=m[2]
          if (seen_prio[v]++) {
            print "bilu board: error: config priorities values must be unique (duplicate: " v ")" >"/dev/stderr"
            fatal=1
          }
        }
      }

      bump_depth(line)
    }
    END {
      if (!saw_statuses) { print "bilu board: error: config missing top-level key: statuses" >"/dev/stderr"; fatal=1 }
      if (!saw_priorities) { print "bilu board: error: config missing top-level key: priorities" >"/dev/stderr"; fatal=1 }
      if (!saw_kind) { print "bilu board: error: config missing top-level key: kind" >"/dev/stderr"; fatal=1 }
      if (!saw_tags) { print "bilu board: warn: config missing top-level key: tags" >"/dev/stderr" }
      exit fatal ? 1 : 0
    }
  ' "$config_path"
}

validate_index() {
  template_root=$1
  index_path=$2
  config_path=$3

  if [ ! -f "$index_path" ]; then
    error "missing index: $index_path"
    return 1
  fi

  links_file=$(mktemp_file)
  records_file=$(mktemp_file)

  awk '
    BEGIN {
      in_obj=0
      in_dep=0
      idx=0
    }
    function reset_obj() {
      title=""
      status=""
      priority=""
      kind=""
      link=""
      deps=""
      in_dep=0
    }
    /^[[:space:]]*{[[:space:]]*$/ {
      in_obj=1
      reset_obj()
      next
    }
    in_obj && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ {
      idx++
      printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\n", idx, title, status, priority, kind, link, deps
      in_obj=0
      next
    }
    !in_obj { next }
    {
      line=$0
      if (match(line, /^[[:space:]]*"title"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) title=m[1]
      if (match(line, /^[[:space:]]*"status"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) status=m[1]
      if (match(line, /^[[:space:]]*"priority"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) priority=m[1]
      if (match(line, /^[[:space:]]*"kind"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) kind=m[1]
      if (match(line, /^[[:space:]]*"link"[[:space:]]*:[[:space:]]*"([^"]*)"/, m)) link=m[1]

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
  ' "$index_path" >"$records_file" || return 1

  # Collect all links for depends_on validation.
  awk '
    BEGIN { in_obj=0 }
    /^[[:space:]]*{[[:space:]]*$/ { in_obj=1; next }
    in_obj && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ { in_obj=0; next }
    in_obj && match($0, /^[[:space:]]*"link"[[:space:]]*:[[:space:]]*"([^"]+)"/, m) { print m[1] }
  ' "$index_path" >"$links_file" || return 1

  index_fatal=0
  count=0

  export BILU_BOARD_CONFIG_PATH=$config_path
  normalize_sh="$(dirname -- "$0")/normalize.sh"

  while IFS='	' read -r idx title status priority kind link deps; do
    count=$((count + 1))
    context="index[$idx]"

    if [ -z "$title" ]; then
      error "missing title ($context)"
      index_fatal=1
    fi
    if [ -z "$status" ]; then
      error "missing status ($context)"
      index_fatal=1
    fi
    if [ -z "$priority" ]; then
      error "missing priority ($context)"
      index_fatal=1
    fi
    if [ -z "$kind" ]; then
      error "missing kind ($context)"
      index_fatal=1
    fi
    if [ -z "$link" ]; then
      error "missing link ($context)"
      index_fatal=1
    fi

    if [ -n "$link" ] && [ ! -f "$template_root/$link" ]; then
      warn "link target missing: $link ($context)"
    fi

    if [ -f "$normalize_sh" ]; then
      sh "$normalize_sh" status "$status" "$link" >/dev/null
      sh "$normalize_sh" priority "$priority" "$link" >/dev/null
      sh "$normalize_sh" kind "$kind" "$link" >/dev/null
    fi

    if [ -n "${deps:-}" ]; then
      old_ifs=$IFS
      IFS=','
      set -- $deps
      IFS=$old_ifs
      for dep in "$@"; do
        [ -z "$dep" ] && continue
        if ! grep -F -x "$dep" "$links_file" >/dev/null 2>&1; then
          warn "depends_on target missing from index: $dep ($context)"
        fi
      done
    fi
  done <"$records_file"

  if [ "$index_fatal" -ne 0 ]; then
    rm -f "$links_file" "$records_file" 2>/dev/null || true
    return 1
  fi

  printf "%s\n" "ok"
  printf "%s\n" "tasks: $count"
  rm -f "$links_file" "$records_file" 2>/dev/null || true
  return 0
}

validate_tsv_records() {
  template_root=$1

  records_sh="$(dirname -- "$0")/records_tsv.sh"
  if [ ! -f "$records_sh" ]; then
    warn "missing TSV records script; skipping TSV invariants check"
    return 0
  fi

  tmp=$(mktemp_file)
  if ! sh "$records_sh" "$template_root" >"$tmp"; then
    rm -f "$tmp" 2>/dev/null || true
    error "failed to generate TSV records"
    return 1
  fi

  awk -F '\t' '
    BEGIN { fatal=0 }
    {
      if (NF != 10) {
        print "bilu board: error: TSV v1 requires exactly 10 fields (got " NF "): " $0 >"/dev/stderr"
        fatal=1
        next
      }
      if ($1=="" || $2=="" || $4=="" || $6=="" || $7=="" || $10=="") {
        print "bilu board: error: TSV v1 missing required fields: " $0 >"/dev/stderr"
        fatal=1
      }
    }
    END { exit fatal ? 1 : 0 }
  ' "$tmp"
  ok=$?
  rm -f "$tmp" 2>/dev/null || true
  return "$ok"
}

template_root=${1:-}
if [ -z "$template_root" ]; then
  error "missing template_root"
  exit 2
fi

config_path="$template_root/board/config.json"
index_path="$template_root/board/default.json"

fatal=0
if ! validate_config "$config_path"; then
  fatal=1
fi

if [ "$fatal" -eq 0 ]; then
  if ! validate_index "$template_root" "$index_path" "$config_path"; then
    fatal=1
  fi
else
  if ! validate_index "$template_root" "$index_path" "$config_path" >/dev/null; then
    fatal=1
  fi
fi

if [ "$fatal" -eq 0 ]; then
  if ! validate_tsv_records "$template_root"; then
    fatal=1
  fi
fi

if [ "$fatal" -ne 0 ]; then
  exit 1
fi
