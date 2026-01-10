#!/usr/bin/env bash

# Test script for TUI layout and selection model
# This tests the core functions without running the interactive TUI

cd /workspace/bilu

# Mock terminal environment
export LINES=24
export COLUMNS=80

# Source required dependencies first
SCRIPT_DIR=".bilu/cli/commands/board"
source "$SCRIPT_DIR/paths.sh"

# Detect paths properly (this sets BOARD_ROOT and other variables)
if ! board_detect_paths "$SCRIPT_DIR"; then
  echo "ERROR: Could not detect board paths"
  exit 1
fi

echo "Detected BOARD_ROOT: $BOARD_ROOT"
echo "Detected BOARD_DEFAULT_JSON_PATH: $BOARD_DEFAULT_JSON_PATH"

source "$SCRIPT_DIR/ui/columns.sh" "__lib__"
board_columns_init

# Set BOARD_LIB_DIR for TUI script
export BOARD_LIB_DIR="$SCRIPT_DIR"

# Source TUI functions for testing
source "$SCRIPT_DIR/render/tui.sh"

echo "=== Testing TUI Layout and Selection Model ==="

echo "1. Testing layout calculation..."
tui_calculate_layout
echo "   Visible rows: $TUI_VISIBLE_ROWS"
echo "   Column width: $TUI_COL_WIDTH"

echo "2. Loading tasks..."
tui_load_tasks
echo "   Tasks loaded successfully"
echo "   Columns loaded: ${#TUI_COLUMNS[@]}"

for ((i=0; i<4; i++)); do
  count=${TUI_CARD_COUNTS[$i]:-0}
  echo "   Column ${TUI_COLUMNS[$i]}: $count cards"
done

echo "3. Testing selection..."
if [[ -n "$TUI_SEL_ID" ]]; then
  echo "   Initial selection: column $TUI_SEL_COL, row $TUI_SEL_ROW, id $TUI_SEL_ID"
else
  echo "   No initial selection found"
fi

echo "4. Testing movement..."
echo "   Testing UP/DOWN movements..."
old_col=$TUI_SEL_COL
old_row=$TUI_SEL_ROW

# Test DOWN movement
tui_handle_movement "DOWN"
echo "   After DOWN: column $TUI_SEL_COL, row $TUI_SEL_ROW, id $TUI_SEL_ID"

# Test RIGHT movement  
tui_handle_movement "RIGHT"
echo "   After RIGHT: column $TUI_SEL_COL, row $TUI_SEL_ROW, id $TUI_SEL_ID"

# Test LEFT movement
tui_handle_movement "LEFT" 
echo "   After LEFT: column $TUI_SEL_COL, row $TUI_SEL_ROW, id $TUI_SEL_ID"

echo "5. Testing scroll updates..."
echo "   Scroll offsets:"
for ((i=0; i<4; i++)); do
  scroll=${TUI_SCROLL_OFFSETS[$i]:-0}
  count=${TUI_CARD_COUNTS[$i]:-0}
  echo "   Column ${TUI_COLUMNS[$i]}: scroll=$scroll, cards=$count"
done

echo "=== Test completed ==="