#!/bin/bash
# JARVIS dispatcher - correct flow
BOARD_FILE="$HOME/.openclaw/workspace/MissionControl/board-state.json"
LOG_FILE="$HOME/.openclaw/workspace/MissionControl/logs/agent-actions-$(date +%Y-%m-%d).log"

# JARVIS: create tasks (if has backlog)
JARVIS_BACKLOG=$(cat "$BOARD_FILE" | jq '[.cards[] | select(.status == "backlog" and .owner == "jarvis")] | length')
if [ "$JARVIS_BACKLOG" -gt 0 ]; then
    TASK=$(cat "$BOARD_FILE" | jq -r '.cards[] | select(.status == "backlog" and .owner == "jarvis") | .id' | head -1)
    if [ -n "$TASK" ]; then
        cat "$BOARD_FILE" | jq --arg id "$TASK" '.cards = [.cards[] | if .id == $id then .status = "in_progress" else . end]' > "$BOARD_FILE.tmp"
        mv "$BOARD_FILE.tmp" "$BOARD_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M')] | JARVIS | START | $TASK | Creating task" >> "$LOG_FILE"
    fi
fi

# BANNER: implement backlog → review
BANNER_IN_PROGRESS=$(cat "$BOARD_FILE" | jq '[.cards[] | select(.status == "in_progress" and .owner == "banner")] | length')
BANNER_BACKLOG=$(cat "$BOARD_FILE" | jq '[.cards[] | select(.status == "backlog" and .owner == "banner")] | length')

if [ "$BANNER_IN_PROGRESS" -eq 0 ] && [ "$BANNER_BACKLOG" -gt 0 ]; then
    TASK=$(cat "$BOARD_FILE" | jq -r '.cards[] | select(.status == "backlog" and .owner == "banner") | .id' | head -1)
    if [ -n "$TASK" ]; then
        cat "$BOARD_FILE" | jq --arg id "$TASK" '.cards = [.cards[] | if .id == $id then .status = "in_progress" else . end]' > "$BOARD_FILE.tmp"
        mv "$BOARD_FILE.tmp" "$BOARD_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M')] | BANNER | START | $TASK | Implementing" >> "$LOG_FILE"
    fi
fi

# BANNER: complete in_progress → review
if [ "$BANNER_IN_PROGRESS" -gt 0 ]; then
    TASK=$(cat "$BOARD_FILE" | jq -r '.cards[] | select(.status == "in_progress" and .owner == "banner") | .id' | head -1)
    if [ -n "$TASK" ]; then
        cat "$BOARD_FILE" | jq --arg id "$TASK" '.cards = [.cards[] | if .id == $id then .status = "review" else . end]' > "$BOARD_FILE.tmp"
        mv "$BOARD_FILE.tmp" "$BOARD_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M')] | BANNER | COMPLETE | $TASK | Moving to review" >> "$LOG_FILE"
    fi
fi

# PEPPER: review → done
REVIEW_COUNT=$(cat "$BOARD_FILE" | jq '[.cards[] | select(.status == "review")] | length')
if [ "$REVIEW_COUNT" -gt 0 ]; then
    TASK=$(cat "$BOARD_FILE" | jq -r '.cards[] | select(.status == "review") | .id' | head -1)
    if [ -n "$TASK" ]; then
        cat "$BOARD_FILE" | jq --arg id "$TASK" '.cards = [.cards[] | if .id == $id then .status = "done" else . end]' > "$BOARD_FILE.tmp"
        mv "$BOARD_FILE.tmp" "$BOARD_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M')] | PEPPER | DONE | $TASK | Validated" >> "$LOG_FILE"
    fi
fi
