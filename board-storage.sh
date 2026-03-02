#!/bin/bash
# Shared Board Storage Manager
# Provides read/write access to shared board state with locking

BOARD_FILE="$HOME/.openclaw/workspace/MissionControl/board-state.json"
LOCK_FILE="$HOME/.openclaw/workspace/MissionControl/.board.lock"
BACKUP_FILE="$HOME/.openclaw/workspace/MissionControl/.board-backup.json"

# Read operations
read_board() {
    if [ -f "$BOARD_FILE" ]; then
        cat "$BOARD_FILE"
    else
        echo '{"boards":[],"cards":[]}'
    fi
}

# Write operations (atomic)
write_board() {
    local json="$1"
    local tmp=$(mktemp)
    echo "$json" > "$tmp"
    mv "$tmp" "$BOARD_FILE"
}

# Update a single card by ID
update_card() {
    local card_id="$1"
    local field="$2"
    local value="$3"
    
    # Read current board
    local board=$(read_board)
    
    # Use jq to update
    local updated=$(echo "$board" | jq --arg id "$card_id" --arg val "$value" \
        '.cards = [.cards[] | if .id == $id then .'$field' = $val else . end]')
    
    write_board "$updated"
}

# Add comment to card
add_comment() {
    local card_id="$1"
    local author="$2"
    local ctype="$3"
    local message="$4"
    local timestamp=$(date -Iseconds)
    
    local board=$(read_board)
    
    local updated=$(jq --arg id "$card_id" --arg author "$author" --arg type "$ctype" --arg msg "$message" --arg ts "$timestamp" \
        '.cards = [.cards[] | if .id == $id then .comments += [{"author": $author, "type": $type, "message": $msg, "timestamp": $ts}] else . end]' <<< "$board")
    
    write_board "$updated"
}

# Get tasks by status
get_tasks_by_status() {
    local status="$1"
    read_board | jq --arg s "$status" '[.cards[] | select(.status == $s)]'
}

# Main command
case "$1" in
    read)
        read_board
        ;;
    write)
        shift
        write_board "$1"
        ;;
    update-card)
        update_card "$2" "$3" "$4"
        ;;
    add-comment)
        add_comment "$2" "$3" "$4" "$5"
        ;;
    get-by-status)
        get_tasks_by_status "$2"
        ;;
    *)
        echo "Usage: $0 {read|write|update-card|add-comment|get-by-status}"
        ;;
esac
