#!/usr/bin/env bash

# Test script for search functionality
# This tests search functions without running interactive TUI

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

source "$SCRIPT_DIR/ui/columns.sh" "__lib__"
board_columns_init

# Set BOARD_LIB_DIR for TUI script
export BOARD_LIB_DIR="$SCRIPT_DIR"

# Source TUI functions for testing
source "$SCRIPT_DIR/render/tui.sh"

echo "=== Testing Search UI ==="

echo "1. Loading tasks..."
tui_load_tasks
echo "   Tasks loaded successfully"

echo "2. Checking loaded tasks before search..."
echo "   Total cards before search:"
total_before=0
for ((i=0; i<4; i++)); do
  count=${TUI_CARD_COUNTS[$i]:-0}
  total_before=$((total_before + count))
  echo "   Column ${TUI_COLUMNS[$i]}: $count cards"
done
echo "   Total: $total_before cards"

echo "3. Testing search functionality..."

# Test searching for "search"
echo "   Testing search for 'search'..."
TUI_SEARCH_QUERY="search"
tui_apply_search

echo "   Search active: $TUI_SEARCH_ACTIVE"
echo "   Search query: $TUI_SEARCH_QUERY"
echo "   Search matches: $TUI_SEARCH_MATCHES"
echo "   Search index: $TUI_SEARCH_INDEX"

echo "4. Checking filtered results..."
for ((i=0; i<4; i++)); do
  count=${TUI_CARD_COUNTS[$i]:-0}
  echo "   Column ${TUI_COLUMNS[$i]}: $count cards"
done

if [[ -n "$TUI_SEARCH_MATCHES" ]]; then
  IFS=',' read -ra matches_array <<< "$TUI_SEARCH_MATCHES"
  echo "   Found ${#matches_array[@]} matches"
  
  if [[ ${#matches_array[@]} -gt 0 ]]; then
    echo "   First match: ${matches_array[0]}"
    echo "   First match title: ${TUI_TASK_TITLES[${matches_array[0]]}"
  fi
fi

echo "4. Testing search navigation..."
if [[ -n "$TUI_SEARCH_MATCHES" ]]; then
  echo "   Testing 'next' navigation..."
  tui_handle_search_navigation "next"
  echo "   After next - index: $TUI_SEARCH_INDEX, selection: $TUI_SEL_ID"
  
  echo "   Testing 'prev' navigation..."
  tui_handle_search_navigation "prev"
  echo "   After prev - index: $TUI_SEARCH_INDEX, selection: $TUI_SEL_ID"
fi

echo "5. Testing search navigation before clear..."
TUI_SEARCH_QUERY=""
tui_apply_search

echo "   After clear - active: $TUI_SEARCH_ACTIVE, query: '$TUI_SEARCH_QUERY'"

echo "7. Testing search clear..."
for ((i=0; i<4; i++)); do
  count=${TUI_CARD_COUNTS[$i]:-0}
  echo "   Column ${TUI_COLUMNS[$i]}: $count cards"
done

echo "8. Final results check after clear..."
total_after=0
for ((i=0; i<4; i++)); do
  count=${TUI_CARD_COUNTS[$i]:-0}
  total_after=$((total_after + count))
done
echo "   Total after clear: $total_after cards (should equal before: $total_before)"

echo "=== Search test completed ==="