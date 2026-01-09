#!/usr/bin/env sh
set -eu

board_render_table() {
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

  awk -F '\t' -v W="$columns" '
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

      printf "%-*s%s%-*s%s%-*s%s%-*s%s%s\n", \
        status_w, trunc(status, status_w), sep, \
        prio_w, trunc(prio, prio_w), sep, \
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
