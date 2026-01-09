#!/usr/bin/env sh
set -eu

TASKS_DIR=${1:-"src/board/tasks"}
OUT=${2:-"src/board/default.json"}
CONFIG_JSON=${3:-"src/board/config.json"}

if [ ! -d "$TASKS_DIR" ]; then
  echo "rebuild-default-json: tasks dir not found: $TASKS_DIR" >&2
  exit 1
fi

if [ ! -f "$CONFIG_JSON" ]; then
  echo "rebuild-default-json: config.json not found: $CONFIG_JSON" >&2
  exit 1
fi

out_dir=$(dirname -- "$OUT")
mkdir -p "$out_dir"

tmp="$OUT.tmp.$$"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT INT TERM HUP

json_escape() {
  # Escapes a single line for inclusion inside a JSON string.
  # (We keep this strict/simple because titles are first-line headings.)
  printf "%s" "$1" | awk '
    BEGIN { ORS=""; }
    {
      gsub(/\\/,"\\\\");
      gsub(/"/,"\\\"");
      gsub(/\t/,"\\t");
      gsub(/\r/,"");
      print;
    }'
}

extract_description() {
  f=$1
  awk '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    function squash(s) {
      gsub(/[[:space:]]+/, " ", s)
      return trim(s)
    }
    function add_line(dst, line) {
      line = trim(line)
      if (line == "") return dst
      if (dst == "") return line
      return dst " " line
    }
    BEGIN {
      in_goal=0
      goal_started=0
      goal_done=0
      goal=""

      started=0
      done=0
      general=""
    }
    NR == 1 { next } # skip title line
    {
      gsub(/\r/, "", $0)
      gsub(/\t/, " ", $0)
    }
    /^##[[:space:]]+Goal[[:space:]]*$/ { in_goal=1; next }
    /^##[[:space:]]+/ {
      if (in_goal) { goal_done=1 }
      in_goal=0
    }
    # Prefer first paragraph in Goal section.
    in_goal && !goal_done {
      if ($0 ~ /^[[:space:]]*$/) {
        if (goal_started) goal_done=1
        next
      }
      if ($0 ~ /^[[:space:]]*[-*][[:space:]]*\\[[ xX]\\]/) next
      goal = add_line(goal, $0)
      goal_started=1
      next
    }
    # Fallback: first paragraph of non-heading content.
    done { next }
    /^[[:space:]]*$/ {
      if (started) done=1
      next
    }
    /^#/ { next }
    /^[[:space:]]*[-*][[:space:]]*\\[[ xX]\\]/ { next }
    general = add_line(general, $0)
    started=1
    END {
      out = (goal != "" ? goal : general)
      out = squash(out)
      if (length(out) > 260) out = substr(out, 1, 257) "..."
      print out
    }
  ' "$f"
}

config_tag_keys=$(
  awk '
    BEGIN { in_tags=0 }
    /"tags"[[:space:]]*:[[:space:]]*[{]/ { in_tags=1; next }
    in_tags==1 {
      if ($0 ~ /^  \\}/) { exit }
      if ($0 ~ /^[[:space:]]+"[a-z0-9-]+"[[:space:]]*:/) {
        line=$0
        sub(/^[[:space:]]+"/, "", line)
        sub(/"[[:space:]]*:.*/, "", line)
        print line
      }
    }
  ' "$CONFIG_JSON" | sort
)

infer_tags_json() {
  f=$1

  tags="planning"

  # Testing / docs / research
  if grep -Eqi '(^|[^a-z])test(s|ing)?([^a-z]|$)' "$f"; then
    tags="$tags testing"
  fi
  if grep -Eqi '(^|[^a-z])(doc|docs|documentation|readme|usage|help)([^a-z]|$)' "$f"; then
    tags="$tags documentation"
  fi
  if grep -Eqi '(^|[^a-z])research([^a-z]|$)' "$f"; then
    tags="$tags research"
  fi

  # UI / UX / terminal rendering
  if grep -Eqi '(^|[^a-z])(ui|tui|kanban|table|render|renderer|color|theme|keyboard|keybindings|terminal)([^a-z]|$)' "$f"; then
    tags="$tags frontend design usability"
  fi

  # Ops / build / install / concurrency
  if grep -Eqi '(^|[^a-z])(install|build|packag|release|ci|lock|locking|concurrency|atomic)([^a-z]|$)' "$f"; then
    tags="$tags devops"
  fi

  # Security-ish
  if grep -Eqi '(^|[^a-z])(security|privacy|permission)([^a-z]|$)' "$f"; then
    tags="$tags security"
  fi

  # Performance
  if grep -Eqi '(^|[^a-z])performance([^a-z]|$)' "$f"; then
    tags="$tags performance"
  fi

  # Backend (rare in current board tasks, but keep rule)
  if grep -Eqi '(^|[^a-z])(backend|api|server|service)([^a-z]|$)' "$f"; then
    tags="$tags backend"
  fi

  # Filter to allowed tag keys from config.json, de-dup, and render as JSON array.
  # Deterministic order: sort lexicographically.
  printf "%s\n" $tags | awk 'NF{for(i=1;i<=NF;i++)print $i}' | sort -u | while IFS= read -r t; do
    printf "%s\n" "$config_tag_keys" | grep -Fx "$t" >/dev/null 2>&1 && printf "%s\n" "$t"
  done | awk '
    BEGIN{first=1; printf "["}
    {
      if (!first) printf ", "
      first=0
      printf "\"%s\"", $0
    }
    END{printf "]"}
  '
}

{
  printf "[\n"
  first=1

  find "$TASKS_DIR" -maxdepth 1 -type f -name '*.md' | sort | while IFS= read -r f; do
    base=$(basename -- "$f")

    title=$(
      sed -n '1{s/^#[[:space:]]*//p; q;}' "$f"
    )
    if [ -z "${title:-}" ]; then
      title="$base"
    fi

    title_esc=$(json_escape "$title")
    desc=$(extract_description "$f")
    desc_esc=$(json_escape "$desc")
    tags_json=$(infer_tags_json "$f")

    if [ "$first" -eq 0 ]; then
      printf ",\n"
    fi
    first=0

    printf "  {\n"
    printf "    \"title\": \"%s\",\n" "$title_esc"
    printf "    \"description\": \"%s\",\n" "$desc_esc"
    printf "    \"priority\": \"MEDIUM\",\n"
    printf "    \"kind\": \"task\",\n"
    printf "    \"status\": \"TODO\",\n"
    printf "    \"depends_on\": [],\n"
    printf "    \"tags\": %s,\n" "$tags_json"
    printf "    \"link\": \"board/tasks/%s\"\n" "$base"

    printf "  }"
  done

  printf "\n]\n"
} >"$tmp"

mv -f "$tmp" "$OUT"
trap - EXIT INT TERM HUP
