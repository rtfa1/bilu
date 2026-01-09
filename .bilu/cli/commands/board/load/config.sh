#!/usr/bin/env sh

board_load_config_json() {
  config_path=${1:-}
  if [ -z "$config_path" ] || [ ! -f "$config_path" ]; then
    return 1
  fi
  cat "$config_path"
}

