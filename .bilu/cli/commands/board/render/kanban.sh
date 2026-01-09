#!/usr/bin/env sh
set -eu

board_render_kanban() {
  SCRIPT_DIR=$(
    CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
    pwd
  )

  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/../ui/ansi.sh" 2>/dev/null || true
  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/../ui/columns.sh" 2>/dev/null || true

  if command -v board_columns_init >/dev/null 2>&1; then
    board_columns_init
  fi

  ANSI_RESET=""
  ANSI_PR_CRITICAL=""
  ANSI_PR_HIGH=""
  ANSI_PR_MEDIUM=""
  ANSI_PR_LOW=""
  ANSI_PR_TRIVIAL=""

  if command -v board_ansi_enabled_fd >/dev/null 2>&1 && board_ansi_enabled_fd 1; then
    ANSI_RESET="$(board_ansi_reset_fd 1)"

    ANSI_PR_CRITICAL="$(board_ansi_priority_prefix_fd 1 CRITICAL)"
    ANSI_PR_HIGH="$(board_ansi_priority_prefix_fd 1 HIGH)"
    ANSI_PR_MEDIUM="$(board_ansi_priority_prefix_fd 1 MEDIUM)"
    ANSI_PR_LOW="$(board_ansi_priority_prefix_fd 1 LOW)"
    ANSI_PR_TRIVIAL="$(board_ansi_priority_prefix_fd 1 TRIVIAL)"
  fi

  columns=${COLUMNS:-}
  case "$columns" in
    ""|*[!0-9]*)
      columns=""
      ;;
  esac

  if [ -z "$columns" ]; then
    size=""
    if [ -r /dev/tty ]; then
      size=$(stty size </dev/tty 2>/dev/null || true)
    else
      size=$(stty size 2>/dev/null || true)
    fi

    # shellcheck disable=SC2086
    set -- $size
    if [ $# -eq 2 ]; then
      case "$2" in
        ""|*[!0-9]*) ;;
        *) columns=$2 ;;
      esac
    fi
  fi

  case "$columns" in
    ""|*[!0-9]*)
      columns=80
      ;;
  esac
  if [ "$columns" -lt 20 ]; then
    columns=20
  fi

  awk -F '\t' \
    -v W="$columns" \
    -v R="$ANSI_RESET" \
    -v PR_CRITICAL="$ANSI_PR_CRITICAL" \
    -v PR_HIGH="$ANSI_PR_HIGH" \
    -v PR_MEDIUM="$ANSI_PR_MEDIUM" \
    -v PR_LOW="$ANSI_PR_LOW" \
    -v PR_TRIVIAL="$ANSI_PR_TRIVIAL" \
    -v BACKLOG_STATUSES="${BOARD_COLUMN_BACKLOG_STATUSES:-BACKLOG TODO}" \
    -v INPROGRESS_STATUSES="${BOARD_COLUMN_INPROGRESS_STATUSES:-INPROGRESS BLOCKED}" \
    -v REVIEW_STATUSES="${BOARD_COLUMN_REVIEW_STATUSES:-REVIEW}" \
    -v DONE_STATUSES="${BOARD_COLUMN_DONE_STATUSES:-DONE}" \
    -v SHOW_COMPLETED="${BOARD_UI_SHOW_COMPLETED_TASKS:-1}" \
    -v SHOW_ARCHIVED="${BOARD_UI_SHOW_ARCHIVED:-0}" \
    -v SHOW_CANCELLED="${BOARD_UI_SHOW_CANCELLED:-0}" \
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
    function center(s, w,    n, l, r) {
      s = trunc(s, w)
      n = w - length(s)
      if (n <= 0) return s
      l = int(n / 2)
      r = n - l
      return repeat(" ", l) s repeat(" ", r)
    }
    function in_list(status, list) {
      return index(" " list " ", " " status " ") > 0
    }
    function status_to_col(status) {
      if (in_list(status, BACKLOG_STATUSES)) return 1
      if (in_list(status, INPROGRESS_STATUSES)) return 2
      if (in_list(status, REVIEW_STATUSES)) return 3
      if (status == "ARCHIVED" || status == "CANCELLED") return 4
      if (in_list(status, DONE_STATUSES)) return 4
      return 1
    }
    function prio_pre(prio) {
      if (prio == "CRITICAL") return PR_CRITICAL
      if (prio == "HIGH") return PR_HIGH
      if (prio == "MEDIUM") return PR_MEDIUM
      if (prio == "LOW") return PR_LOW
      if (prio == "TRIVIAL") return PR_TRIVIAL
      return ""
    }
    function chips_from_csv(csv,    n, a, i, out, part) {
      if (csv == "") return "-"
      n = split(csv, a, ",")
      out = ""
      for (i=1; i<=n; i++) {
        part = a[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", part)
        if (part == "") continue
        if (out != "") out = out " "
        out = out "#" part
      }
      if (out == "") return "-"
      return out
    }
    function render_badge(prio,    badge, pre) {
      badge = "[" prio "]"
      pre = prio_pre(prio)
      if (pre != "" && R != "") return pre badge R
      return badge
    }
    function chips_from_csv_or_empty(csv,    n, a, i, out, part) {
      if (csv == "") return ""
      n = split(csv, a, ",")
      out = ""
      for (i=1; i<=n; i++) {
        part = a[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", part)
        if (part == "") continue
        if (out != "") out = out " "
        out = out "#" part
      }
      return out
    }
    function render_narrow_card(prio, title, line_w,    pre, max_title) {
      pre = "- [" prio "] "
      max_title = line_w - length(pre)
      if (max_title < 0) max_title = 0
      return "- " render_badge(prio) " " trunc(title, max_title)
    }
    function render_title_cell(prio, id, title, inner_w,    badge, raw, out, padlen) {
      badge = "[" prio "]"
      raw = badge " " id " " title
      raw = trunc(raw, inner_w)
      padlen = inner_w - length(raw)
      if (padlen < 0) padlen = 0
      if (index(raw, badge " ") == 1) {
        out = render_badge(prio) substr(raw, length(badge)+1)
      } else {
        out = raw
      }
      return out repeat(" ", padlen)
    }
    function render_simple_cell(text, inner_w) {
      text = trunc(text, inner_w)
      return text repeat(" ", inner_w - length(text))
    }
    function card_line(line_no, prio, id, title, tags, col_w, inner_w,    border, cell) {
      border = "+" repeat("-", col_w-2) "+"
      if (line_no == 1) return border
      if (line_no == 2) {
        cell = render_title_cell(prio, id, title, inner_w)
        return "| " cell " |"
      }
      if (line_no == 3) {
        cell = render_simple_cell(chips_from_csv(tags), inner_w)
        return "| " cell " |"
      }
      return border
    }
    BEGIN {
      col_titles[1] = "Backlog"
      col_titles[2] = "In Progress"
      col_titles[3] = "Review"
      col_titles[4] = "Done"
    }
    NF==10 {
      id=$1
      status=$2
      prio=$4
      title=$6
      tags=$8

      if (status == "DONE" && SHOW_COMPLETED != 1) next
      if (status == "ARCHIVED" && SHOW_ARCHIVED != 1) next
      if (status == "CANCELLED" && SHOW_CANCELLED != 1) next

      col = status_to_col(status)
      idx = ++col_count[col]

      card_prio[col, idx] = prio
      card_id[col, idx] = id
      card_title[col, idx] = title
      card_tags[col, idx] = tags
    }
    END {
      cols = W
      if (cols < 20) cols = 20

      gutter = 2
      ncols = 4
      if (cols < 80) mode = "narrow"
      else mode = "wide"

      col_w = int((cols - gutter*(ncols-1)) / ncols)
      if (col_w < 10) mode = "narrow"

      inner_w = col_w - 4
      if (inner_w < 20) mode = "narrow"

      if (mode == "narrow") {
        line_w = cols
        for (c=1; c<=4; c++) {
          header = "== " col_titles[c] " (" col_count[c] ") =="
          print trunc(header, line_w)
          print ""
          for (i=1; i<=col_count[c]; i++) {
            print trunc(render_narrow_card(card_prio[c, i], card_title[c, i], line_w), line_w)
            tags_line = chips_from_csv_or_empty(card_tags[c, i])
            if (tags_line != "") print trunc("  tags: " tags_line, line_w)
            print ""
          }
        }
        exit 0
      }

      header = ""
      divider = ""
      for (c=1; c<=4; c++) {
        seg = "| " center(col_titles[c], inner_w) " |"
        line = "+" repeat("-", col_w-2) "+"
        if (c > 1) {
          header = header repeat(" ", gutter)
          divider = divider repeat(" ", gutter)
        }
        header = header seg
        divider = divider line
      }
      print header
      print divider

      max_cards = 0
      for (c=1; c<=4; c++) if (col_count[c] > max_cards) max_cards = col_count[c]

      blank = repeat(" ", col_w)
      for (i=1; i<=max_cards; i++) {
        for (ln=1; ln<=4; ln++) {
          row = ""
          for (c=1; c<=4; c++) {
            if (c > 1) row = row repeat(" ", gutter)
            if (i <= col_count[c]) {
              row = row card_line(ln, card_prio[c, i], card_id[c, i], card_title[c, i], card_tags[c, i], col_w, inner_w)
            } else {
              row = row blank
            }
          }
          print row
        }
      }
    }
    '
}

if [ "${1:-}" = "__lib__" ]; then
  return 0 2>/dev/null || exit 0
fi

board_render_kanban
