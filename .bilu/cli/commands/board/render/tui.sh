#!/usr/bin/env bash
set -euo pipefail

TUI_STTY_SAVED=""
TUI_CLEANED=0

# TUI state
TUI_SEL_COL=0
TUI_SEL_ROW=0
TUI_SEL_ID=""
TUI_NEEDS_REDRAW=1
TUI_VISIBLE_ROWS=5
TUI_COL_WIDTH=20

# Search state
TUI_SEARCH_ACTIVE=0
TUI_SEARCH_QUERY=""
TUI_SEARCH_PROMPT=""
TUI_SEARCH_MODE=0  # 0=normal, 1=prompt input
TUI_SEARCH_MATCHES=""  # Comma-separated list of matching task IDs
TUI_SEARCH_INDEX=0  # Current match index

# Filter state
TUI_FILTER_ACTIVE=0
TUI_FILTER_FIELD=""
TUI_FILTER_VALUE=""
TUI_FILTER_MODE=0  # 0=normal, 1=field selection, 2=value selection
TUI_FILTER_PROMPT=""

# Sort state
TUI_SORT_KEY="priority"
TUI_SORT_ORDER="desc"
TUI_SORT_MODE=0  # 0=normal, 1=key selection, 2=order selection
TUI_SORT_PROMPT=""

# Column data (will be populated from TSV)
declare -a TUI_COLUMNS=("Backlog" "In Progress" "Review" "Done")
declare -a TUI_COLUMN_STATS=("BACKLOG TODO" "INPROGRESS BLOCKED" "REVIEW" "DONE")
declare -A TUI_CARDS  # [col_index]="card1,card2,..."  (comma-separated IDs)
declare -A TUI_CARD_COUNTS  # [col_index]=count
declare -A TUI_SCROLL_OFFSETS  # [col_index]=scroll_row
declare -A TUI_TASK_TITLES  # [task_id]=title
declare -A TUI_TASK_STATUS  # [task_id]=status
declare -A TUI_TASK_PRIORITIES  # [task_id]=priority_weight
declare -A TUI_TASK_PRIORITY_STRINGS  # [task_id]=priority_string
declare -A TUI_TASK_KINDS  # [task_id]=kind
declare -A TUI_TASK_TAGS  # [task_id]=tags
declare -A TUI_TASK_PATHS  # [task_id]=path

# Load task data into TUI structures
tui_load_tasks() {
  local records_sh tsv_data id status priority_weight priority kind title path tags deps link
  
   # Clear existing data
   TUI_CARDS=()
   TUI_CARD_COUNTS=()
   TUI_SCROLL_OFFSETS=()
   TUI_TASK_TITLES=()
   TUI_TASK_STATUS=()
   TUI_TASK_PRIORITIES=()
   TUI_TASK_PRIORITY_STRINGS=()
   TUI_TASK_KINDS=()
   TUI_TASK_TAGS=()
   TUI_TASK_PATHS=()
  
  # Initialize empty columns
  for ((i=0; i<4; i++)); do
    TUI_CARDS[$i]=""
    TUI_CARD_COUNTS[$i]=0
    TUI_SCROLL_OFFSETS[$i]=0
  done
  
  # Find records_tsv.sh using BOARD_LIB_DIR environment variable if available
  local board_lib_dir="${BOARD_LIB_DIR:-}"
  if [[ -z "$board_lib_dir" ]]; then
    # Fallback: calculate from script location
    board_lib_dir="$(cd "$(dirname -- "$(dirname -- "$0")")" && pwd)"
  fi
  records_sh="$board_lib_dir/records_tsv.sh"
  
  # Load and process TSV data
  if [[ -f "$records_sh" ]] && [[ -n "${BOARD_ROOT:-}" ]]; then
    # Use temp file to avoid pipe/subshell issues
    local temp_file=$(mktemp)
    if ! bash "$records_sh" "$BOARD_ROOT" 2>/dev/null > "$temp_file"; then
      echo "ERROR: Failed to load TSV data" >&2
      rm -f "$temp_file"
      return 1
    fi
    
    local line_num=0
    while IFS=$'\t' read -r id status priority_weight priority kind title path tags deps link rest || [[ -n "$id" ]]; do
      ((line_num++))
      
      # Skip empty lines
      if [[ -z "$id" ]]; then
        continue
      fi
      
      # Determine column based on status
      local col_idx=-1
      case "$status" in
        BACKLOG|TODO) col_idx=0 ;;
        INPROGRESS|BLOCKED) col_idx=1 ;;
        REVIEW) col_idx=2 ;;
        DONE) col_idx=3 ;;
      esac
      
       # Always store task metadata for search, regardless of column
       TUI_TASK_TITLES[$id]="$title"
       TUI_TASK_STATUS[$id]="$status"
       TUI_TASK_PRIORITIES[$id]="$priority_weight"
       TUI_TASK_PRIORITY_STRINGS[$id]="$priority"
       TUI_TASK_KINDS[$id]="$kind"
       TUI_TASK_TAGS[$id]="$tags"
       TUI_TASK_PATHS[$id]="$path"
      
      if [[ $col_idx -ge 0 ]]; then
        local current_cards="${TUI_CARDS[$col_idx]:-}"
        if [[ -n "$current_cards" ]]; then
          TUI_CARDS[$col_idx]="$current_cards,$id"
        else
          TUI_CARDS[$col_idx]="$id"
        fi
        ((TUI_CARD_COUNTS[$col_idx]++))
      fi
    done < "$temp_file"
    
    # Clean up temp file
    rm -f "$temp_file"
  fi
  
  # Set initial selection if not set
  if [[ -z "$TUI_SEL_ID" ]]; then
    tui_select_first_available
  fi
}

# Select first available task
tui_select_first_available() {
  for ((col=0; col<4; col++)); do
    local count="${TUI_CARD_COUNTS[$col]:-0}"
    if [[ $count -gt 0 ]]; then
      TUI_SEL_COL=$col
      TUI_SEL_ROW=0
      local cards="${TUI_CARDS[$col]}"
      TUI_SEL_ID="${cards%%,*}"  # First card ID
      return 0
    fi
  done
  TUI_SEL_ID=""
  return 1
}

# Get card ID at specific position
tui_get_card_id() {
  local col=$1 row=$2
  local cards="${TUI_CARDS[$col]:-}"
  local count=0
  
  if [[ -z "$cards" ]]; then
    return 1
  fi
  
  IFS=',' read -ra CARD_ARRAY <<< "$cards"
  if [[ $row -ge ${#CARD_ARRAY[@]} ]]; then
    return 1
  fi
  
  printf '%s' "${CARD_ARRAY[$row]}"
}

# Update selection based on movement
tui_handle_movement() {
  local direction=$1
  local old_col=$TUI_SEL_COL
  local old_row=$TUI_SEL_ROW
  
  case "$direction" in
    UP)
      if [[ $TUI_SEL_ROW -gt 0 ]]; then
        ((TUI_SEL_ROW--))
      fi
      ;;
    DOWN)
      local max_row=$((TUI_CARD_COUNTS[TUI_SEL_COL] - 1))
      if [[ $TUI_SEL_ROW -lt $max_row ]]; then
        ((TUI_SEL_ROW++))
      fi
      ;;
    LEFT)
      if [[ $TUI_SEL_COL -gt 0 ]]; then
        ((TUI_SEL_COL--))
        local target_max=$((TUI_CARD_COUNTS[TUI_SEL_COL] - 1))
        TUI_SEL_ROW=$((TUI_SEL_ROW > target_max ? target_max : TUI_SEL_ROW))
        if [[ $TUI_SEL_ROW -lt 0 ]]; then TUI_SEL_ROW=0; fi
      fi
      ;;
    RIGHT)
      if [[ $TUI_SEL_COL -lt 3 ]]; then
        ((TUI_SEL_COL++))
        local target_max=$((TUI_CARD_COUNTS[TUI_SEL_COL] - 1))
        TUI_SEL_ROW=$((TUI_SEL_ROW > target_max ? target_max : TUI_SEL_ROW))
        if [[ $TUI_SEL_ROW -lt 0 ]]; then TUI_SEL_ROW=0; fi
      fi
      ;;
  esac
  
  # Update selected ID
  TUI_SEL_ID=$(tui_get_card_id "$TUI_SEL_COL" "$TUI_SEL_ROW" || true)
  
  # Update scroll to keep selection visible
  tui_update_scroll
  
  # Mark for redraw if position changed
  if [[ $old_col -ne $TUI_SEL_COL || $old_row -ne $TUI_SEL_ROW ]]; then
    TUI_NEEDS_REDRAW=1
  fi
}

# Update scroll offsets to keep selection visible
tui_update_scroll() {
  local col=$TUI_SEL_COL
  local row=$TUI_SEL_ROW
  local scroll="${TUI_SCROLL_OFFSETS[$col]:-0}"
  
  # Ensure selection is within visible range
  if [[ $row -lt $scroll ]]; then
    TUI_SCROLL_OFFSETS[$col]=$row
  elif [[ $row -ge $((scroll + TUI_VISIBLE_ROWS)) ]]; then
    TUI_SCROLL_OFFSETS[$col]=$((row - TUI_VISIBLE_ROWS + 1))
  fi
}

# Apply search filter to tasks
tui_apply_search() {
  local query_lower col cards card_array filtered_cards all_matches
  
  if [[ -z "$TUI_SEARCH_QUERY" ]]; then
    # Clear search - reset to show all tasks
    TUI_SEARCH_ACTIVE=0
    TUI_SEARCH_MATCHES=""
    TUI_SEARCH_INDEX=0
    # Reload all tasks without filtering
    tui_load_tasks
    return 0
  fi
  
  # Convert query to lowercase for case-insensitive matching
  query_lower=$(echo "$TUI_SEARCH_QUERY" | tr '[:upper:]' '[:lower:]')
  
  TUI_SEARCH_ACTIVE=1
  all_matches=""
  
  # Filter each column
  for ((col=0; col<4; col++)); do
    cards="${TUI_CARDS[$col]:-}"
    filtered_cards=""
    
    if [[ -n "$cards" ]]; then
      IFS=',' read -ra card_array <<< "$cards"
      for card_id in "${card_array[@]}"; do
        local title="${TUI_TASK_TITLES[$card_id]:-}"
        local title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')
        
        # Check if query matches title (case-insensitive substring)
        if [[ "$title_lower" == *"$query_lower"* ]]; then
          if [[ -n "$filtered_cards" ]]; then
            filtered_cards="$filtered_cards,$card_id"
          else
            filtered_cards="$card_id"
          fi
          
          # Add to matches list
          if [[ -n "$all_matches" ]]; then
            all_matches="$all_matches,$card_id"
          else
            all_matches="$card_id"
          fi
        fi
      done
    fi
    
    # Update column with filtered results
    TUI_CARDS[$col]="$filtered_cards"
    # Update count
    IFS=',' read -ra filtered_array <<< "$filtered_cards"
    TUI_CARD_COUNTS[$col]="${#filtered_array[@]}"
    # Reset scroll for this column
    TUI_SCROLL_OFFSETS[$col]=0
  done
  
  # Update matches tracking
  TUI_SEARCH_MATCHES="$all_matches"
  TUI_SEARCH_INDEX=0
  
  # Try to maintain selection in filtered results
  if [[ -n "$TUI_SEL_ID" ]]; then
    local found=0
    for ((col=0; col<4; col++)); do
      cards="${TUI_CARDS[$col]:-}"
      if [[ -n "$cards" ]]; then
        IFS=',' read -ra card_array <<< "$cards"
        local row=0
        for card_id in "${card_array[@]}"; do
          if [[ "$card_id" == "$TUI_SEL_ID" ]]; then
            TUI_SEL_COL=$col
            TUI_SEL_ROW=$row
            found=1
            
            # Find this match in the matches list
            IFS=',' read -ra matches_array <<< "$all_matches"
            for ((i=0; i<${#matches_array[@]}; i++)); do
              if [[ "${matches_array[i]}" == "$TUI_SEL_ID" ]]; then
                TUI_SEARCH_INDEX=$i
                break
              fi
            done
            break 2
          fi
          ((row++))
        done
      fi
    done
    
    # If current selection not found, select first available
    if [[ $found -eq 0 ]]; then
      tui_select_first_available
    fi
  else
    tui_select_first_available
  fi
}

# Navigate search matches
tui_handle_search_navigation() {
  local direction=$1 matches_array match_count target_idx target_id
  
  if [[ -z "$TUI_SEARCH_MATCHES" ]]; then
    return 0
  fi
  
  IFS=',' read -ra matches_array <<< "$TUI_SEARCH_MATCHES"
  match_count=${#matches_array[@]}
  
  if [[ $match_count -eq 0 ]]; then
    return 0
  fi
  
  case "$direction" in
    "next")
      target_idx=$((TUI_SEARCH_INDEX + 1))
      if [[ $target_idx -ge $match_count ]]; then
        target_idx=0  # Wrap around
      fi
      ;;
    "prev")
      target_idx=$((TUI_SEARCH_INDEX - 1))
      if [[ $target_idx -lt 0 ]]; then
        target_idx=$((match_count - 1))  # Wrap around
      fi
      ;;
  esac
  
  target_id="${matches_array[$target_idx]}"
  
  # Find the column and row for this task ID
  local found=0
  for ((col=0; col<4; col++)); do
    local cards="${TUI_CARDS[$col]:-}"
    if [[ -n "$cards" ]]; then
      IFS=',' read -ra card_array <<< "$cards"
      local row=0
      for card_id in "${card_array[@]}"; do
        if [[ "$card_id" == "$target_id" ]]; then
          TUI_SEL_COL=$col
          TUI_SEL_ROW=$row
          TUI_SEL_ID="$target_id"
          TUI_SEARCH_INDEX=$target_idx
          found=1
          break 2
        fi
        ((row++))
      done
    fi
  done
  
  if [[ $found -eq 1 ]]; then
    tui_update_scroll
    TUI_NEEDS_REDRAW=1
  fi
}

# Apply filter and sort to tasks
tui_apply_filter_and_sort() {
  local cards filtered_cards sorted_cards all_task_ids temp_array
  declare -a task_ids_array
  
  # If no filter or sort is active, just reload tasks
  if [[ $TUI_FILTER_ACTIVE -eq 0 && "$TUI_SORT_KEY" == "priority" && "$TUI_SORT_ORDER" == "desc" ]]; then
    tui_load_tasks
    return 0
  fi
  
  # First, reload all tasks to get fresh data
  tui_load_tasks
  
  # Collect all task IDs from all columns
  all_task_ids=""
  for ((col=0; col<4; col++)); do
    cards="${TUI_CARDS[$col]:-}"
    if [[ -n "$cards" ]]; then
      if [[ -n "$all_task_ids" ]]; then
        all_task_ids="$all_task_ids,$cards"
      else
        all_task_ids="$cards"
      fi
    fi
  done
  
  if [[ -z "$all_task_ids" ]]; then
    return 0
  fi
  
  # Convert to array for processing
  IFS=',' read -ra task_ids_array <<< "$all_task_ids"
  
  # Apply filter
  filtered_tasks=()
  for task_id in "${task_ids_array[@]}"; do
    local include_task=1
    
    if [[ $TUI_FILTER_ACTIVE -eq 1 ]]; then
      case "$TUI_FILTER_FIELD" in
        status)
          local task_status="${TUI_TASK_STATUS[$task_id]:-}"
          [[ "$task_status" != "$TUI_FILTER_VALUE" ]] && include_task=0
          ;;
        priority)
          local task_priority="${TUI_TASK_PRIORITIES[$task_id]:-}"
          # Normalize priority comparison
          local filter_priority
          case "$TUI_FILTER_VALUE" in
            CRITICAL) filter_priority=10 ;;
            HIGH) filter_priority=8 ;;
            MEDIUM) filter_priority=5 ;;
            LOW) filter_priority=3 ;;
            TRIVIAL) filter_priority=1 ;;
            *) filter_priority="$TUI_FILTER_VALUE" ;;
          esac
          [[ "$task_priority" != "$filter_priority" ]] && include_task=0
          ;;
        kind)
          local task_kind="${TUI_TASK_KINDS[$task_id]:-}"
          [[ "${task_kind,,}" != "${TUI_FILTER_VALUE,,}" ]] && include_task=0
          ;;
        tag)
          local task_tags="${TUI_TASK_TAGS[$task_id]:-}"
          local filter_tag_lower="${TUI_FILTER_VALUE,,}"
          local found=0
          IFS=',' read -ra tags_array <<< "$task_tags"
          for tag in "${tags_array[@]}"; do
            [[ "${tag,,}" == "$filter_tag_lower" ]] && found=1 && break
          done
          [[ $found -eq 0 ]] && include_task=0
          ;;
      esac
    fi
    
    if [[ $include_task -eq 1 ]]; then
      filtered_tasks+=("$task_id")
    fi
  done
  
  # Apply sort using a temporary file
  if [[ ${#filtered_tasks[@]} -gt 0 ]]; then
    local temp_sort_file=$(mktemp)
    
    # Create sort key + task_id pairs
    for id in "${filtered_tasks[@]}"; do
      case "$TUI_SORT_KEY" in
        priority)
          echo "${TUI_TASK_PRIORITIES[$id]:-0}$'\t'$id" >> "$temp_sort_file"
          ;;
        title)
          echo "${TUI_TASK_TITLES[$id]:-}$'\t'$id" >> "$temp_sort_file"
          ;;
        status)
          echo "${TUI_TASK_STATUS[$id]:-}$'\t'$id" >> "$temp_sort_file"
          ;;
      esac
    done
    
    # Sort and extract task IDs
    local sort_flags="-f"
    [[ "$TUI_SORT_ORDER" == "desc" ]] && sort_flags="-rf"
    
    filtered_tasks=()
    while IFS=$'\t' read -r sort_key task_id; do
      filtered_tasks+=("$task_id")
    done < <(sort $sort_flags -k1,1 "$temp_sort_file" | cut -f2)
    
    rm -f "$temp_sort_file"
  fi
  
  # Clear current columns
  for ((i=0; i<4; i++)); do
    TUI_CARDS[$i]=""
    TUI_CARD_COUNTS[$i]=0
    TUI_SCROLL_OFFSETS[$i]=0
  done
  
  # Redistribute tasks to columns based on their status
  for task_id in "${filtered_tasks[@]}"; do
    local task_status="${TUI_TASK_STATUS[$task_id]:-}"
    local col_idx=-1
    
    case "$task_status" in
      BACKLOG|TODO) col_idx=0 ;;
      INPROGRESS|BLOCKED) col_idx=1 ;;
      REVIEW) col_idx=2 ;;
      DONE) col_idx=3 ;;
    esac
    
    if [[ $col_idx -ge 0 ]]; then
      local current_cards="${TUI_CARDS[$col_idx]:-}"
      if [[ -n "$current_cards" ]]; then
        TUI_CARDS[$col_idx]="$current_cards,$task_id"
      else
        TUI_CARDS[$col_idx]="$task_id"
      fi
      ((TUI_CARD_COUNTS[col_idx]++))
    fi
  done
  
  # Maintain selection
  if [[ -n "$TUI_SEL_ID" ]]; then
    local found=0
    for ((col=0; col<4; col++)); do
      cards="${TUI_CARDS[$col]:-}"
      if [[ -n "$cards" ]]; then
        IFS=',' read -ra card_array <<< "$cards"
        local row=0
        for card_id in "${card_array[@]}"; do
          if [[ "$card_id" == "$TUI_SEL_ID" ]]; then
            TUI_SEL_COL=$col
            TUI_SEL_ROW=$row
            found=1
            break 2
          fi
          ((row++))
        done
      fi
    done
    
    # If current selection not found, select first available
    if [[ $found -eq 0 ]]; then
      tui_select_first_available
    fi
  else
    tui_select_first_available
  fi
}

# Calculate layout based on terminal size
tui_calculate_layout() {
  local rows=${LINES:-24}
  local cols=${COLUMNS:-80}
  
  # Reserve space for header (2 lines) and footer (1 line)
  TUI_VISIBLE_ROWS=$((rows - 3))
  if [[ $TUI_VISIBLE_ROWS -lt 3 ]]; then
    TUI_VISIBLE_ROWS=3
  fi
  
  # Calculate column width (minus borders and spacing)
  TUI_COL_WIDTH=$(((cols - 9) / 4))  # 4 borders + 3 spaces = 7, plus padding
  if [[ $TUI_COL_WIDTH -lt 10 ]]; then
    TUI_COL_WIDTH=10
  fi
}

# Handle window resize
tui_on_resize() {
  tui_calculate_layout
  TUI_NEEDS_REDRAW=1
}

tui_read_key() {
  local key k1 k2 k3

  key=""
  IFS= read -rsn1 -t 0.05 key || true
  if [[ -z "$key" ]]; then
    printf '%s\n' "NONE"
    return 0
  fi

  case "$key" in
    $'\r'|$'\n') printf '%s\n' "ENTER"; return 0 ;;
    $'\x7f'|$'\b') printf '%s\n' "BACKSPACE"; return 0 ;;
  esac

  if [[ "$key" != $'\e' ]]; then
    printf '%s\n' "$key"
    return 0
  fi

  k1=""
  k2=""
  k3=""
  IFS= read -rsn1 -t 0.001 k1 || true
  IFS= read -rsn1 -t 0.001 k2 || true

  case "${k1}${k2}" in
    "[A") printf '%s\n' "UP"; return 0 ;;
    "[B") printf '%s\n' "DOWN"; return 0 ;;
    "[C") printf '%s\n' "RIGHT"; return 0 ;;
    "[D") printf '%s\n' "LEFT"; return 0 ;;
    "OA") printf '%s\n' "UP"; return 0 ;;
    "OB") printf '%s\n' "DOWN"; return 0 ;;
    "OC") printf '%s\n' "RIGHT"; return 0 ;;
    "OD") printf '%s\n' "LEFT"; return 0 ;;
    "[H") printf '%s\n' "HOME"; return 0 ;;
    "[F") printf '%s\n' "END"; return 0 ;;
  esac

  if [[ "$k1" = "[" ]]; then
    case "$k2" in
      1|4|5|6)
        IFS= read -rsn1 -t 0.001 k3 || true
        if [[ "$k3" = "~" ]]; then
          case "$k2" in
            1) printf '%s\n' "HOME"; return 0 ;;
            4) printf '%s\n' "END"; return 0 ;;
            5) printf '%s\n' "PAGEUP"; return 0 ;;
            6) printf '%s\n' "PAGEDOWN"; return 0 ;;
          esac
        fi
        ;;
    esac
  fi

  printf '%s\n' "ESC"
}

board_tui_setup_terminal() {
  TUI_STTY_SAVED="$(stty -g 2>/dev/null || true)"

  printf '\e[?1049h'
  printf '\e[?7l'
  printf '\e[?25l'

  if ! stty -echo -icanon time 0 min 0 2>/dev/null; then
    stty -echo 2>/dev/null || true
  fi

  printf '\e[2J\e[H'
}

board_tui_cleanup_terminal() {
  if [[ "$TUI_CLEANED" -eq 1 ]]; then
    return 0
  fi
  TUI_CLEANED=1

  if [[ -n "$TUI_STTY_SAVED" ]]; then
    stty "$TUI_STTY_SAVED" 2>/dev/null || true
  else
    stty echo icanon 2>/dev/null || true
  fi

  printf '\e[?7h'
  printf '\e[?25h'
  printf '\e[?1049l'
}

# Build frame buffer for rendering
tui_build_frame() {
  local frame=""
  local total_tasks visible_tasks
  local line
  
  # Calculate totals
  total_tasks=0
  for ((i=0; i<4; i++)); do
    total_tasks=$((total_tasks + TUI_CARD_COUNTS[i]))
  done
  visible_tasks=$total_tasks  # For now, no filtering
  
  # Header
  frame+=$'\e[H\e[2J'  # Clear screen and home cursor
  frame+="\e[1;37;44m"  # Bold white on blue for header
  frame+=$(printf " bilu board --tui %*s " $((COLUMNS - 20)) "")
  frame+="\e[0m\n"
  frame+="\e[1;37;44m"
  frame+=$(printf " Tasks: %d visible / %d total%*s " "$visible_tasks" "$total_tasks" $((COLUMNS - 35)) "")
  frame+="\e[0m\n"
  frame+="\n"
  
  # Column headers
  local col_start=1
  for ((i=0; i<4; i++)); do
    local title="${TUI_COLUMNS[i]}"
    local count="${TUI_CARD_COUNTS[i]}"
    local header_text="$title ($count)"
    
    # Position cursor and draw column
    frame+=$(printf "\e[3;%dH" $col_start)
    if [[ $i -eq $TUI_SEL_COL ]]; then
      frame+="\e[1;33;44m"  # Yellow on blue for selected column
    else
      frame+="\e[1;37;44m"  # White on blue
    fi
    frame+=$(printf "%-*s" $((TUI_COL_WIDTH)) "$header_text")
    frame+="\e[0m"
    
    col_start=$((col_start + TUI_COL_WIDTH + 2))
  done
  
  # Draw cards in each column
  local line_num=4  # Start after headers
  for ((row=0; row<TUI_VISIBLE_ROWS; row++)); do
    local col_start=1
    
    for ((col=0; col<4; col++)); do
      local card_id=""
      local scroll="${TUI_SCROLL_OFFSETS[$col]:-0}"
      local actual_row=$((scroll + row))
      
      card_id=$(tui_get_card_id "$col" "$actual_row" || true)
      
      frame+=$(printf "\e[%d;%dH" $line_num $col_start)
      
      if [[ -n "$card_id" ]]; then
        # This is a card - draw it
        local is_selected=0
        if [[ $col -eq $TUI_SEL_COL && $actual_row -eq $TUI_SEL_ROW ]]; then
          is_selected=1
        fi
        
        if [[ $is_selected -eq 1 ]]; then
          frame+="\e[1;33;47m"  # Yellow on white for selected card
        else
          frame+="\e[0;37;47m"  # White on white for regular cards
        fi
        
        # Truncate card ID to fit column width
        local display_id="${card_id:0:$((TUI_COL_WIDTH - 1))}"
        frame+=$(printf "%-*s" $((TUI_COL_WIDTH)) "$display_id")
        frame+="\e[0m"
      else
        # Empty space
        frame+=$(printf "%-*s" $((TUI_COL_WIDTH)) " ")
      fi
      
      col_start=$((col_start + TUI_COL_WIDTH + 2))
    done
    
    line_num=$((line_num + 1))
  done
  
  # Footer/status bar
  local footer_line=$((LINES))
  frame+=$(printf "\e[%d;H" $footer_line)
  frame+="\e[1;37;44m"
  
  if [[ $TUI_FILTER_MODE -eq 1 ]]; then
    # Show filter field selection prompt
    frame+=$(printf " Filter field (status/priority/tag/kind): %s %*s " "$TUI_FILTER_PROMPT" $((COLUMNS - 45 - ${#TUI_FILTER_PROMPT})) "")
  elif [[ $TUI_FILTER_MODE -eq 2 ]]; then
    # Show filter value selection prompt
    frame+=$(printf " Filter $TUI_FILTER_FIELD: %s%s %*s " "$TUI_FILTER_PROMPT" "_" $((COLUMNS - 15 - ${#TUI_FILTER_FIELD} - ${#TUI_FILTER_PROMPT})) "")
  elif [[ $TUI_SORT_MODE -eq 1 ]]; then
    # Show sort key selection prompt
    frame+=$(printf " Sort key (priority/title/status): %s %*s " "$TUI_SORT_PROMPT" $((COLUMNS - 35 - ${#TUI_SORT_PROMPT})) "")
  elif [[ $TUI_SORT_MODE -eq 2 ]]; then
    # Show sort order selection prompt
    frame+=$(printf " Order (asc/desc): %s %*s " "$TUI_SORT_PROMPT" $((COLUMNS - 20 - ${#TUI_SORT_PROMPT})) "")
  elif [[ $TUI_SEARCH_MODE -eq 1 ]]; then
    # Show search prompt
    frame+=$(printf " Search: %s%s %*s " "$TUI_SEARCH_PROMPT" "_" $((COLUMNS - 15 - ${#TUI_SEARCH_PROMPT})) "")
  else
    # Show normal status with search, filter, and sort info
    local status_text=" q:quit ↑↓←→:navigate /:search f:filter s:sort c:clear ?:help"
    
    # Show filter info
    if [[ $TUI_FILTER_ACTIVE -eq 1 && -n "$TUI_FILTER_FIELD" && -n "$TUI_FILTER_VALUE" ]]; then
      status_text="$status_text Filter: $TUI_FILTER_FIELD=$TUI_FILTER_VALUE"
    fi
    
    # Show sort info
    if [[ -n "$TUI_SORT_KEY" && -n "$TUI_SORT_ORDER" ]]; then
      status_text="$status_text Sort: $TUI_SORT_KEY $TUI_SORT_ORDER"
    fi
    
    # Show search info
    if [[ $TUI_SEARCH_ACTIVE -eq 1 && -n "$TUI_SEARCH_QUERY" ]]; then
      local match_count=0
      if [[ -n "$TUI_SEARCH_MATCHES" ]]; then
        IFS=',' read -ra matches_array <<< "$TUI_SEARCH_MATCHES"
        match_count=${#matches_array[@]}
        if [[ $match_count -gt 0 ]]; then
          status_text="$status_text Search: \"$TUI_SEARCH_QUERY\" $((TUI_SEARCH_INDEX + 1))/$match_count"
        else
          status_text="$status_text Search: \"$TUI_SEARCH_QUERY\" 0 matches"
        fi
      fi
    fi
    
    frame+=$(printf "%s %*s " "$status_text" $((COLUMNS - ${#status_text} - 20)) "")
    
    if [[ -n "$TUI_SEL_ID" ]]; then
      frame+=" Selected: $TUI_SEL_ID"
    fi
  fi
  
  frame+="\e[0m"
  
  printf '%b' "$frame"
}

board_tui_draw() {
  if [[ $TUI_NEEDS_REDRAW -eq 1 ]]; then
    tui_build_frame
    TUI_NEEDS_REDRAW=0
  fi
}

board_tui_handle_key() {
  local key=$1
  
  # Handle filter mode
  if [[ $TUI_FILTER_MODE -gt 0 ]]; then
    case "$key" in
      ENTER)
        if [[ $TUI_FILTER_MODE -eq 1 ]]; then
          # Field selection step
          case "$TUI_FILTER_PROMPT" in
            s|S) TUI_FILTER_FIELD="status" ;;
            p|P) TUI_FILTER_FIELD="priority" ;;
            t|T) TUI_FILTER_FIELD="tag" ;;
            k|K) TUI_FILTER_FIELD="kind" ;;
            *) return 0 ;;  # Invalid field, ignore
          esac
          # Move to value selection step
          TUI_FILTER_MODE=2
          TUI_FILTER_PROMPT=""
          TUI_NEEDS_REDRAW=1
        else
          # Value selection step
          if [[ -n "$TUI_FILTER_PROMPT" ]]; then
            TUI_FILTER_VALUE="$TUI_FILTER_PROMPT"
            TUI_FILTER_ACTIVE=1
            TUI_FILTER_MODE=0
            tui_apply_filter_and_sort
            TUI_NEEDS_REDRAW=1
          fi
        fi
        ;;
      ESC)
        # Cancel filter prompt
        TUI_FILTER_MODE=0
        TUI_FILTER_PROMPT=""
        TUI_NEEDS_REDRAW=1
        ;;
      BACKSPACE)
        # Remove last character from prompt
        if [[ -n "$TUI_FILTER_PROMPT" ]]; then
          TUI_FILTER_PROMPT="${TUI_FILTER_PROMPT%?}"
          TUI_NEEDS_REDRAW=1
        fi
        ;;
      NONE) ;;  # No action needed
      *)
        # Add character to prompt
        if [[ $TUI_FILTER_MODE -eq 1 && ${#key} -eq 1 && "$key" =~ [spktSPKT] ]]; then
          TUI_FILTER_PROMPT="$key"
          TUI_NEEDS_REDRAW=1
        elif [[ $TUI_FILTER_MODE -eq 2 && ${#key} -eq 1 && "$key" =~ [a-zA-Z0-9\ \.\-\_] ]]; then
          TUI_FILTER_PROMPT="${TUI_FILTER_PROMPT}${key}"
          TUI_NEEDS_REDRAW=1
        fi
        ;;
    esac
    return 0
  fi
  
  # Handle sort mode
  if [[ $TUI_SORT_MODE -gt 0 ]]; then
    case "$key" in
      ENTER)
        if [[ $TUI_SORT_MODE -eq 1 ]]; then
          # Key selection step
          case "$TUI_SORT_PROMPT" in
            p|P) TUI_SORT_KEY="priority" ;;
            t|T) TUI_SORT_KEY="title" ;;
            s|S) TUI_SORT_KEY="status" ;;
            *) return 0 ;;  # Invalid key, ignore
          esac
          # Move to order selection step
          TUI_SORT_MODE=2
          TUI_SORT_PROMPT=""
          TUI_NEEDS_REDRAW=1
        else
          # Order selection step
          case "$TUI_SORT_PROMPT" in
            a|A) TUI_SORT_ORDER="asc" ;;
            d|D) TUI_SORT_ORDER="desc" ;;
            *) return 0 ;;  # Invalid order, ignore
          esac
          TUI_SORT_MODE=0
          tui_apply_filter_and_sort
          TUI_NEEDS_REDRAW=1
        fi
        ;;
      ESC)
        # Cancel sort prompt
        TUI_SORT_MODE=0
        TUI_SORT_PROMPT=""
        TUI_NEEDS_REDRAW=1
        ;;
      BACKSPACE)
        # Remove last character from prompt
        if [[ -n "$TUI_SORT_PROMPT" ]]; then
          TUI_SORT_PROMPT="${TUI_SORT_PROMPT%?}"
          TUI_NEEDS_REDRAW=1
        fi
        ;;
      NONE) ;;  # No action needed
      *)
        # Add character to prompt
        if [[ $TUI_SORT_MODE -eq 1 && ${#key} -eq 1 && "$key" =~ [ptsPTS] ]]; then
          TUI_SORT_PROMPT="$key"
          TUI_NEEDS_REDRAW=1
        elif [[ $TUI_SORT_MODE -eq 2 && ${#key} -eq 1 && "$key" =~ [adAD] ]]; then
          TUI_SORT_PROMPT="$key"
          TUI_NEEDS_REDRAW=1
        fi
        ;;
    esac
    return 0
  fi
  
  # Handle search mode differently
  if [[ $TUI_SEARCH_MODE -eq 1 ]]; then
    case "$key" in
      ENTER)
        # Commit search
        TUI_SEARCH_QUERY="$TUI_SEARCH_PROMPT"
        TUI_SEARCH_MODE=0
        tui_apply_search
        TUI_NEEDS_REDRAW=1
        ;;
      ESC)
        # Cancel search prompt
        TUI_SEARCH_MODE=0
        TUI_NEEDS_REDRAW=1
        ;;
      BACKSPACE)
        # Remove last character from prompt
        if [[ -n "$TUI_SEARCH_PROMPT" ]]; then
          TUI_SEARCH_PROMPT="${TUI_SEARCH_PROMPT%?}"
          TUI_NEEDS_REDRAW=1
        fi
        ;;
      NONE) ;;  # No action needed
      *)
        # Add printable character to prompt
        if [[ ${#key} -eq 1 && "$key" =~ [a-zA-Z0-9\ \.\-\_] ]]; then
          TUI_SEARCH_PROMPT="${TUI_SEARCH_PROMPT}${key}"
          TUI_NEEDS_REDRAW=1
        fi
        ;;
    esac
    return 0
  fi
  
  case "$key" in
    q) return 1 ;;  # Signal to quit
    f) 
      # Enter filter mode (field selection)
      TUI_FILTER_MODE=1
      TUI_FILTER_PROMPT=""
      TUI_NEEDS_REDRAW=1
      ;;
    s) 
      # Enter sort mode (key selection)
      TUI_SORT_MODE=1
      TUI_SORT_PROMPT=""
      TUI_NEEDS_REDRAW=1
      ;;
    /) 
      # Enter search mode
      TUI_SEARCH_MODE=1
      TUI_SEARCH_PROMPT="$TUI_SEARCH_QUERY"
      TUI_NEEDS_REDRAW=1
      ;;
    n) tui_handle_search_navigation "next" ;;
    p) tui_handle_search_navigation "prev" ;;
    c) 
      # Clear search and filters
      TUI_SEARCH_QUERY=""
      TUI_FILTER_ACTIVE=0
      TUI_FILTER_FIELD=""
      TUI_FILTER_VALUE=""
      tui_apply_filter_and_sort
      TUI_NEEDS_REDRAW=1
      ;;
    UP|k) tui_handle_movement "UP" ;;
    DOWN|j) tui_handle_movement "DOWN" ;;
    LEFT|h) tui_handle_movement "LEFT" ;;
    RIGHT|l) tui_handle_movement "RIGHT" ;;
    HOME) tui_handle_movement "HOME" ;;
    END) tui_handle_movement "END" ;;
    PAGEUP) tui_handle_movement "PAGEUP" ;;
    PAGEDOWN) tui_handle_movement "PAGEDOWN" ;;
    ENTER|NONE) ;;  # No action needed
    *) TUI_NEEDS_REDRAW=1 ;;  # Unknown key, mark for redraw
  esac
  
  return 0
}

board_tui_main_loop() {
  local key
  
  # Initial setup
  tui_calculate_layout
  tui_load_tasks
  TUI_NEEDS_REDRAW=1
  
  # Main loop
  while true; do
    # Always draw current state
    board_tui_draw
    
    # Read key (non-blocking)
    key="$(tui_read_key)"
    
    # Handle key - return 1 means quit
    if ! board_tui_handle_key "$key"; then
      return 0
    fi
    
    # Small sleep to prevent CPU spin when idle
    if [[ "$key" == "NONE" && $TUI_NEEDS_REDRAW -eq 0 ]]; then
      sleep 0.01
    fi
  done
}

tui_handle_enter() {
  if [[ -z "$TUI_SEL_ID" ]]; then
    return 0
  fi
  local path="${TUI_TASK_PATHS[$TUI_SEL_ID]}"
  if [[ -z "$path" ]]; then
    return 0
  fi
  board_tui_cleanup_terminal
  if "$actions_dir/open.sh" "$path"; then
    board_tui_setup_terminal
    TUI_NEEDS_REDRAW=1
  else
    board_tui_setup_terminal
    TUI_NEEDS_REDRAW=1
  fi
}

tui_handle_open_editor() {
  if [[ -z "${EDITOR:-}" ]]; then
    return 0
  fi
  if [[ -z "$TUI_SEL_ID" ]]; then
    return 0
  fi
  local path="${TUI_TASK_PATHS[$TUI_SEL_ID]}"
  if [[ -z "$path" ]]; then
    return 0
  fi
  board_tui_cleanup_terminal
  if "$actions_dir/open.sh" "$path"; then
    board_tui_setup_terminal
    TUI_NEEDS_REDRAW=1
  else
    board_tui_setup_terminal
    TUI_NEEDS_REDRAW=1
  fi
}

tui_handle_cycle_status() {
  if [[ -z "$TUI_SEL_ID" ]]; then
    return 0
  fi
  local path="${TUI_TASK_PATHS[$TUI_SEL_ID]}"
  local current="${TUI_TASK_STATUS[$TUI_SEL_ID]}"
  local next
  case "$current" in
    TODO) next="INPROGRESS" ;;
    INPROGRESS) next="REVIEW" ;;
    REVIEW) next="DONE" ;;
    DONE) next="TODO" ;;
    *) next="TODO" ;;
  esac
  if "$actions_dir/set_status.sh" "$path" "$next"; then
    tui_load_tasks
    TUI_NEEDS_REDRAW=1
  else
    TUI_NEEDS_REDRAW=1
  fi
}

tui_handle_cycle_priority() {
  if [[ -z "$TUI_SEL_ID" ]]; then
    return 0
  fi
  local path="${TUI_TASK_PATHS[$TUI_SEL_ID]}"
  local current="${TUI_TASK_PRIORITY_STRINGS[$TUI_SEL_ID]}"
  local next
  case "$current" in
    TRIVIAL) next="LOW" ;;
    LOW) next="MEDIUM" ;;
    MEDIUM) next="HIGH" ;;
    HIGH) next="CRITICAL" ;;
    CRITICAL) next="TRIVIAL" ;;
    *) next="MEDIUM" ;;
  esac
  if "$actions_dir/set_priority.sh" "$path" "$next"; then
    tui_load_tasks
    TUI_NEEDS_REDRAW=1
  else
    TUI_NEEDS_REDRAW=1
  fi
}

tui_handle_refresh() {
  tui_load_tasks
  TUI_NEEDS_REDRAW=1
}

board_tui_main() {
   if [[ ! -t 0 || ! -t 1 ]]; then
     printf "%s\n" "bilu board --tui requires a TTY" >&2
     return 1
   fi

   # Source required libraries
   local script_dir
   script_dir="$(dirname -- "$0")"
   local actions_dir="$script_dir/actions"
   
   # Source paths detection
   if [[ -f "$script_dir/../paths.sh" ]]; then
     # shellcheck source=../paths.sh
     . "$script_dir/../paths.sh"
   fi
   
   # Source column configuration
   if [[ -f "$script_dir/../ui/columns.sh" ]]; then
     # shellcheck source=../ui/columns.sh
     . "$script_dir/../ui/columns.sh" "__lib__"
     board_columns_init
   fi

   # Set up traps
   trap board_tui_cleanup_terminal EXIT INT TERM
   trap 'tui_on_resize; TUI_NEEDS_REDRAW=1' WINCH
   
   # Initialize terminal and start main loop
   board_tui_setup_terminal
   board_tui_main_loop
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  board_tui_main "$@"
fi
