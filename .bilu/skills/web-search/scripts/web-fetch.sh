#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: web-fetch.sh "<url>" [--lines <n>]

Fetches a URL and prints a trimmed, text-ish excerpt (best-effort).

Options:
  --lines <n>   Max lines to print (default: 80)
  -h, --help    Show this help
EOF
}

lines=80

if [ $# -lt 1 ]; then
  usage >&2
  exit 2
fi

url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --lines)
      shift
      if [ $# -lt 1 ]; then
        echo "web-fetch: missing value for --lines" >&2
        exit 2
      fi
      lines=$1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "web-fetch: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -z "$url" ]; then
        url=$1
      else
        echo "web-fetch: unexpected argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [ -z "$url" ]; then
  usage >&2
  exit 2
fi

body=$(
  curl -fsSL "$url" 2>/dev/null || true
)

if [ -z "$body" ]; then
  echo "web-fetch: failed to fetch (network blocked or URL unavailable): $url" >&2
  exit 1
fi

# Best-effort “HTML to text” without dependencies:
# - drop scripts/styles
# - strip tags
# - decode a couple of common entities
printf "%s\n" "$body" \
  | awk '
      BEGIN { in_script=0; in_style=0 }
      /<script[ >]/ { in_script=1 }
      in_script && /<\/script>/ { in_script=0; next }
      in_script { next }
      /<style[ >]/ { in_style=1 }
      in_style && /<\/style>/ { in_style=0; next }
      in_style { next }
      { print }
    ' \
  | sed 's/<[^>]*>/ /g' \
  | sed 's/&nbsp;/ /g; s/&amp;/\\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/\"/g' \
  | sed 's/[[:space:]][[:space:]]*/ /g' \
  | sed 's/^ *//; s/ *$//' \
  | awk 'NF' \
  | head -n "$lines"

