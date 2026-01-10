#!/bin/bash
set -euo pipefail

CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: $0 <config.json>"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  exit 1
fi

# Read JSON config
IMAGE=$(jq -r '.image // empty' "$CONFIG_FILE")
RM=$(jq -r '.rm // false' "$CONFIG_FILE")
INTERACTIVE=$(jq -r '.interactive // false' "$CONFIG_FILE")
NAME=$(jq -r '.name // empty' "$CONFIG_FILE")
WORKING_DIR_RAW=$(jq -r '.workingDir // empty' "$CONFIG_FILE")
NETWORK=$(jq -r '.network // empty' "$CONFIG_FILE")

# Get expansion values
basename_val=$(basename "$PWD")
pwd_val=$(pwd)
home_val=$HOME

# Expand shell variables in working directory
if [ -n "$WORKING_DIR_RAW" ]; then
  WORKING_DIR=$(echo "$WORKING_DIR_RAW" | sed "s#\$(basename \"\$PWD\")#$basename_val#g" | sed "s#\$(pwd)#$pwd_val#g" | sed "s#\$HOME#$home_val#g")
else
  WORKING_DIR=""
fi

# Build docker run command
CMD="docker run"

if [ "$RM" = "true" ]; then
  CMD="$CMD --rm"
fi

if [ -n "$NAME" ]; then
  CMD="$CMD --name $NAME"
fi

if [ "$INTERACTIVE" = "true" ]; then
  CMD="$CMD -it"
fi

# Add environment variables
ENV_VARS=""
if jq -e '.env' "$CONFIG_FILE" &> /dev/null; then
  ENV_VARS=$(jq -r '.env | to_entries[] | "-e \(.key)=\(.value)"' "$CONFIG_FILE" | tr '\n' ' ')
fi
CMD="$CMD $ENV_VARS"

# Add volumes
VOLUME_VARS=""
if jq -e '.volumes' "$CONFIG_FILE" &> /dev/null; then
  while read -r volume_raw; do
    if [ -n "$volume_raw" ]; then
      volume=$(echo "$volume_raw" | sed "s#\$(basename \"\$PWD\")#$basename_val#g" | sed "s#\$(pwd)#$pwd_val#g" | sed "s#\$HOME#$home_val#g")
      VOLUME_VARS="$VOLUME_VARS -v \"$volume\""
    fi
  done < <(jq -r '.volumes[]' "$CONFIG_FILE")
fi
CMD="$CMD $VOLUME_VARS"

# Add working directory
if [ -n "$WORKING_DIR" ]; then
  CMD="$CMD -w \"$WORKING_DIR\""
fi

# Add network
if [ -n "$NETWORK" ]; then
  CMD="$CMD --network=$NETWORK"
fi

# Add image
CMD="$CMD $IMAGE"

# Add command
if jq -e '.command' "$CONFIG_FILE" &> /dev/null; then
  COMMAND_ARGS_RAW=$(jq -r '.command | join(" ")' "$CONFIG_FILE")
  COMMAND_ARGS=$(echo "$COMMAND_ARGS_RAW" | sed "s#\$(basename \"\$PWD\")#$basename_val#g" | sed "s#\$(pwd)#$pwd_val#g" | sed "s#\$HOME#$home_val#g")
else
  COMMAND_ARGS=""
fi

# Output the formatted command
echo "docker run --rm \\"
if [ -n "$NAME" ]; then
  echo "    --name $NAME \\"
fi
if [ "$INTERACTIVE" = "true" ]; then
  echo "    -it \\"
fi
if jq -e '.env' "$CONFIG_FILE" &> /dev/null; then
  jq -r '.env | to_entries[] | "    -e \(.key)=\(.value) \\"' "$CONFIG_FILE"
fi
if [ -n "$VOLUME_VARS" ]; then
  echo "$VOLUME_VARS" | sed 's/ -v /\n    -v /g' | sed '1d' | sed 's/$/ \\/'
fi
if [ -n "$WORKING_DIR" ]; then
  echo "    -w \"$WORKING_DIR\" \\"
fi
if [ -n "$NETWORK" ]; then
  echo "    --network=$NETWORK \\"
fi
if [ -n "$COMMAND_ARGS" ]; then
  echo "    $IMAGE \\"
  echo "    $COMMAND_ARGS"
else
  echo "    $IMAGE"
fi