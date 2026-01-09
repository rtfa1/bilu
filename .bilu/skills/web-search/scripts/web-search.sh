#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: web-search.sh "<query>" [--n <count>]

Performs a lightweight web search using DuckDuckGo Lite and prints result URLs.

Options:
  --n <count>   Max results (default: 8)
  -h, --help    Show this help
EOF
}

n=8

if [ $# -lt 1 ]; then
  usage >&2
  exit 2
fi

query=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --n)
      shift
      if [ $# -lt 1 ]; then
        echo "web-search: missing value for --n" >&2
        exit 2
      fi
      n=$1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "web-search: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -z "$query" ]; then
        query=$1
      else
        query="$query $1"
      fi
      shift
      ;;
  esac
done

if [ -z "$query" ]; then
  usage >&2
  exit 2
fi

enc=$(
  # URL-encode query (minimal, sufficient for common ASCII queries).
  printf "%s" "$query" | awk '
    BEGIN {
      ORS=""
      for (i=0; i<256; i++) hex[sprintf("%c", i)] = sprintf("%%%02X", i)
    }
    {
      for (i=1; i<=length($0); i++) {
        c = substr($0, i, 1)
        if (c ~ /[A-Za-z0-9_.~-]/) {
          printf "%s", c
        } else if (c == " ") {
          printf "+"
        } else {
          printf "%s", hex[c]
        }
      }
    }'
)

html=$(
  curl -fsSL "https://lite.duckduckgo.com/lite/?q=$enc" 2>/dev/null || true
)

if [ -z "$html" ]; then
  echo "web-search: failed to fetch results (network blocked or provider unavailable)" >&2
  exit 1
fi

# Extract URLs. DuckDuckGo Lite returns result links in href="...".
printf "%s\n" "$html" \
  | sed -n 's/.*href="\([^"]*\)".*/\1/p' \
  | awk '
      # Prefer http(s) and drop DDG internal links.
      /^https?:\/\// && $0 !~ /duckduckgo\.com/ { print }
    ' \
  | awk '!seen[$0]++' \
  | head -n "$n"

