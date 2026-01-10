#!/usr/bin/env sh
set -eu

REPO_ROOT=$(
  CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1
  pwd
)

assert_no_ansi() {
  # Basic check for SGR escape sequences: ESC[
  awk 'index($0, sprintf("%c[", 27)) { found=1 } END { exit found ? 1 : 0 }'
}

out="$(NO_COLOR=1 COLUMNS=120 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --view=table)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | grep -F "STATUS" >/dev/null
printf "%s" "$out" | grep -F "TITLE" >/dev/null
printf "%s" "$out" | grep -F "Phase 00 — Scope and constraints" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 COLUMNS=120 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --view=kanban)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | grep -F "Backlog" >/dev/null
printf "%s" "$out" | grep -F "In Progress" >/dev/null
printf "%s" "$out" | grep -F "Review" >/dev/null
printf "%s" "$out" | grep -F "Done" >/dev/null
printf "%s" "$out" | assert_no_ansi

out="$(NO_COLOR=1 COLUMNS=60 sh "$REPO_ROOT/.bilu/cli/bilu" board --list --view=kanban)"
printf "%s" "$out" | grep -F "board listing" >/dev/null
printf "%s" "$out" | grep -F "== Backlog" >/dev/null
printf "%s" "$out" | grep -F "== In Progress" >/dev/null
printf "%s" "$out" | grep -F "== Review" >/dev/null
printf "%s" "$out" | grep -F "== Done" >/dev/null
printf "%s" "$out" | assert_no_ansi
