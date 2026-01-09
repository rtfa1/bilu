#!/usr/bin/env sh
set -eu

filter=${1:-}
filter_value=${2:-}

if [ -n "$filter" ]; then
  printf "board listing (filter: %s=%s)\n" "$filter" "$filter_value"
else
  printf "%s\n" "board listing"
fi
