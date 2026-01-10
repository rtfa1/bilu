# lock.sh - Board-level locking to prevent concurrent edits
#
# Functions:
# - board_lock_acquire <lock_dir> <timeout_seconds>
# - board_lock_release <lock_dir>
#
# Exit codes:
# - 0: success
# - 1: failure (cannot acquire, timeout, etc.)

# Global flag to track if lock is held (for idempotent release)
BOARD_LOCK_HELD=0

board_lock_acquire() {
    local lock_dir="$1"
    local timeout_seconds="$2"

    # Ensure parent storage directory exists
    local storage_dir
    storage_dir="$(dirname "$lock_dir")"
    if ! mkdir -p "$storage_dir" 2>/dev/null; then
        echo "bilu board: error: cannot create storage directory: $storage_dir" >&2
        return 1
    fi

    # Attempt to acquire lock
    if mkdir "$lock_dir" 2>/dev/null; then
        # Acquired successfully
        # Write metadata (best-effort)
        echo "$$" > "$lock_dir/pid" 2>/dev/null || true
        date '+%s' > "$lock_dir/ts" 2>/dev/null || echo "$(date)" > "$lock_dir/ts" || true
        printf '%s\n' "$0 $*" > "$lock_dir/cmd" 2>/dev/null || true
        BOARD_LOCK_HELD=1
        return 0
    fi

    # Lock exists, check if timeout is 0
    if [ "$timeout_seconds" -eq 0 ]; then
        echo "bilu board: error: lock busy: $lock_dir" >&2
        echo "bilu board: hint: If you are sure no bilu process is running, remove the lock directory." >&2
        return 1
    fi

    # Wait with timeout
    local elapsed=0
    local sleep_interval=1  # Use 1 second for portability
    while [ "$elapsed" -lt "$timeout_seconds" ]; do
        if mkdir "$lock_dir" 2>/dev/null; then
            # Acquired
            echo "$$" > "$lock_dir/pid" 2>/dev/null || true
            date '+%s' > "$lock_dir/ts" 2>/dev/null || echo "$(date)" > "$lock_dir/ts" || true
            printf '%s\n' "$0 $*" > "$lock_dir/cmd" 2>/dev/null || true
            BOARD_LOCK_HELD=1
            return 0
        fi

        # Check for stale lock (optional improvement)
        if [ -f "$lock_dir/pid" ]; then
            local pid
            pid="$(cat "$lock_dir/pid" 2>/dev/null || echo "")"
            if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
                # Process is dead, remove stale lock
                rm -rf "$lock_dir" 2>/dev/null || true
                # Retry immediately
                continue
            fi
        fi

        sleep "$sleep_interval"
        elapsed=$((elapsed + sleep_interval))
    done

    # Timeout expired
    echo "bilu board: error: lock busy: $lock_dir" >&2
    echo "bilu board: hint: If you are sure no bilu process is running, remove the lock directory." >&2
    return 1
}

board_lock_release() {
    local lock_dir="$1"

    if [ "$BOARD_LOCK_HELD" -eq 0 ]; then
        # Not held, idempotent
        return 0
    fi

    # Remove metadata files (best-effort)
    rm -f "$lock_dir/pid" "$lock_dir/ts" "$lock_dir/cmd" 2>/dev/null || true

    # Remove lock dir
    if rmdir "$lock_dir" 2>/dev/null; then
        BOARD_LOCK_HELD=0
        return 0
    else
        echo "bilu board: warning: failed to release lock: $lock_dir" >&2
        return 1
    fi
}