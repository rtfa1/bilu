#!/usr/bin/env sh
set -eu

board_render_table() {
  SCRIPT_DIR=$(
    CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
    pwd
  )

  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/../ui/ansi.sh" 2>/dev/null || true

  ANSI_RESET=""
  ANSI_ST_BACKLOG=""
  ANSI_ST_TODO=""
  ANSI_ST_INPROGRESS=""
  ANSI_ST_BLOCKED=""
  ANSI_ST_REVIEW=""
  ANSI_ST_DONE=""
  ANSI_ST_ARCHIVED=""
  ANSI_ST_CANCELLED=""

  ANSI_PR_CRITICAL=""
  ANSI_PR_HIGH=""
  ANSI_PR_MEDIUM=""
  ANSI_PR_LOW=""
  ANSI_PR_TRIVIAL=""

  if command -v board_ansi_enabled_fd >/dev/null 2>&1 && board_ansi_enabled_fd 1; then
    ANSI_RESET="$(board_ansi_reset_fd 1)"

    ANSI_ST_BACKLOG="$(board_ansi_status_prefix_fd 1 BACKLOG)"
    ANSI_ST_TODO="$(board_ansi_status_prefix_fd 1 TODO)"
    ANSI_ST_INPROGRESS="$(board_ansi_status_prefix_fd 1 INPROGRESS)"
    ANSI_ST_BLOCKED="$(board_ansi_status_prefix_fd 1 BLOCKED)"
    ANSI_ST_REVIEW="$(board_ansi_status_prefix_fd 1 REVIEW)"
    ANSI_ST_DONE="$(board_ansi_status_prefix_fd 1 DONE)"
    ANSI_ST_ARCHIVED="$(board_ansi_status_prefix_fd 1 ARCHIVED)"
    ANSI_ST_CANCELLED="$(board_ansi_status_prefix_fd 1 CANCELLED)"

    ANSI_PR_CRITICAL="$(board_ansi_priority_prefix_fd 1 CRITICAL)"
    ANSI_PR_HIGH="$(board_ansi_priority_prefix_fd 1 HIGH)"
    ANSI_PR_MEDIUM="$(board_ansi_priority_prefix_fd 1 MEDIUM)"
    ANSI_PR_LOW="$(board_ansi_priority_prefix_fd 1 LOW)"
    ANSI_PR_TRIVIAL="$(board_ansi_priority_prefix_fd 1 TRIVIAL)"
  fi

  # TSV v1 columns:
  # 1 id, 2 status, 3 priority_weight, 4 priority, 5 kind, 6 title,
  # 7 path, 8 tags_csv, 9 depends_csv, 10 link
  columns=${COLUMNS:-}
  case "$columns" in
    ""|*[!0-9]*)
      columns=80
      ;;
  esac
  if [ "$columns" -lt 40 ]; then
    columns=40
  fi

  awk -F '\t' \
    -v W="$columns" \
    -v R="$ANSI_RESET" \
    -v ST_BACKLOG="$ANSI_ST_BACKLOG" \
    -v ST_TODO="$ANSI_ST_TODO" \
    -v ST_INPROGRESS="$ANSI_ST_INPROGRESS" \
    -v ST_BLOCKED="$ANSI_ST_BLOCKED" \
    -v ST_REVIEW="$ANSI_ST_REVIEW" \
    -v ST_DONE="$ANSI_ST_DONE" \
    -v ST_ARCHIVED="$ANSI_ST_ARCHIVED" \
    -v ST_CANCELLED="$ANSI_ST_CANCELLED" \
    -v PR_CRITICAL="$ANSI_PR_CRITICAL" \
    -v PR_HIGH="$ANSI_PR_HIGH" \
    -v PR_MEDIUM="$ANSI_PR_MEDIUM" \
    -v PR_LOW="$ANSI_PR_LOW" \
    -v PR_TRIVIAL="$ANSI_PR_TRIVIAL" \
    '
    function repeat(ch, n,    out, i) {
      out=""
      for (i=0; i<n; i++) out = out ch
      return out
    }
    function trunc(s, w,    n) {
      if (w <= 0) return ""
      n = length(s)
      if (n <= w) return s
      if (w <= 3) return substr(s, 1, w)
      return substr(s, 1, w-3) "..."
    }
    function basename(p,    b) {
      b = p
      sub(/^.*\//, "", b)
      return b
    }
    function status_pre(status) {
      if (status == "BACKLOG") return ST_BACKLOG
      if (status == "TODO") return ST_TODO
      if (status == "INPROGRESS") return ST_INPROGRESS
      if (status == "BLOCKED") return ST_BLOCKED
      if (status == "REVIEW") return ST_REVIEW
      if (status == "DONE") return ST_DONE
      if (status == "ARCHIVED") return ST_ARCHIVED
      if (status == "CANCELLED") return ST_CANCELLED
      return ""
    }
    function prio_pre(prio) {
      if (prio == "CRITICAL") return PR_CRITICAL
      if (prio == "HIGH") return PR_HIGH
      if (prio == "MEDIUM") return PR_MEDIUM
      if (prio == "LOW") return PR_LOW
      if (prio == "TRIVIAL") return PR_TRIVIAL
      return ""
    }
    function emit_token(token, width, pre,    padlen) {
      padlen = width - length(token)
      if (padlen < 0) padlen = 0
      if (pre != "" && R != "") {
        return pre token R repeat(" ", padlen)
      }
      return token repeat(" ", padlen)
    }
    BEGIN {
      sep="  "
      status_w=11
      prio_w=8
      tags_w=18
      path_w=22

      min_title_w=10
      min_tags_w=10
      min_path_w=12

      title_w = W - (status_w + prio_w + tags_w + path_w + 4*length(sep))

      if (title_w < min_title_w) {
        need = min_title_w - title_w

        shrink_p = path_w - min_path_w
        if (shrink_p < 0) shrink_p = 0
        if (shrink_p > need) shrink_p = need
        path_w -= shrink_p
        title_w += shrink_p
        need -= shrink_p

        shrink_t = tags_w - min_tags_w
        if (shrink_t < 0) shrink_t = 0
        if (shrink_t > need) shrink_t = need
        tags_w -= shrink_t
        title_w += shrink_t
        need -= shrink_t
      }

      printf "%-*s%s%-*s%s%-*s%s%-*s%s%-*s\n", status_w, "STATUS", sep, prio_w, "PRIO", sep, title_w, "TITLE", sep, tags_w, "TAGS", sep, path_w, "PATH"
      printf "%s%s%s%s%s%s%s%s%s\n", repeat("-", status_w), sep, repeat("-", prio_w), sep, repeat("-", title_w), sep, repeat("-", tags_w), sep, repeat("-", path_w)
    }

    NF==10 {
      status=$2
      prio=$4
      title=$6
      tags=$8
      path=basename($7)

      if (tags == "") tags="-"

      status_tok = trunc(status, status_w)
      prio_tok = trunc(prio, prio_w)

      printf "%s%s%s%s%-*s%s%-*s%s%s\n", \
        emit_token(status_tok, status_w, status_pre(status)), sep, \
        emit_token(prio_tok, prio_w, prio_pre(prio)), sep, \
        title_w, trunc(title, title_w), sep, \
        tags_w, trunc(tags, tags_w), sep, \
        trunc(path, path_w)
    }
  '
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_render_table
