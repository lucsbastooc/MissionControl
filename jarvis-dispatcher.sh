#!/bin/bash
# JARVIS dispatcher - one task per agent
BOARD_FILE="$HOME/.openclaw/workspace/MissionControl/board-state.json"
LOG_FILE="$HOME/.openclaw/workspace/MissionControl/logs/agent-actions-$(date +%Y-%m-%d).log"

# Check each agent
for AGENT in jarvis banner pepper; do
    IN_PROGRESS=$(cat "$BOARD_FILE" | jq --arg agent "$AGENT" '[.cards[] | select(.status == "in_progress" and .owner == $agent)] | length')
    BACKLOG=$(cat "$BOARD_FILE" | jq --arg agent "$AGENT" '[.cards[] | select(.status == "backlog" and .owner == $agent)] | length')
    
    echo "[$(date '+%Y-%m-%d %H:%M')] | JARVIS | CHECK | $AGENT | in_progress=$IN_PROGRESS backlog=$BACKLOG" >> "$LOG_FILE"
    
    # Rule: if in_progress == 0 AND backlog > 0 → pick task
    if [ "$IN_PROGRESS" -eq 0 ] && [ "$BACKLOG" -gt 0 ]; then
        TASK_ID=$(cat "$BOARD_FILE" | jq -r --arg agent "$AGENT" '.cards[] | select(.status == "backlog" and .owner == $agent) | .id' | head -1)
        
        if [ -n "$TASK_ID" ]; then
            cat "$BOARD_FILE" | jq --arg id "$TASK_ID" '.cards = [.cards[] | if .id == $id then .status = "in_progress" else . end]' > "$BOARD_FILE.tmp"
            mv "$BOARD_FILE.tmp" "$BOARD_FILE"
            echo "[$(date '+%Y-%m-%d %H:%M')] | JARVIS | DISPATCH | $AGENT | $TASK_ID" >> "$LOG_FILE"
        fi
    fi
    
    # Rule: if in_progress > 0 → move to review (complete the task)
    if [ "$IN_PROGRESS" -gt 0 ]; then
        TASK_ID=$(cat "$BOARD_FILE" | jq -r --arg agent "$AGENT" '.cards[] | select(.status == "in_progress" and .owner == $agent) | .id' | head -1)
        
        if [ -n "$TASK_ID" ]; then
            cat "$BOARD_FILE" | jq --arg id "$TASK_ID" '.cards = [.cards[] | if .id == $id then .status = "review" else . end]' > "$BOARD_FILE.tmp"
            mv "$BOARD_FILE.tmp" "$BOARD_FILE"
            echo "[$(date '+%Y-%m-%d %H:%M')] | $AGENT | COMPLETE | $TASK_ID | Moved to review" >> "$LOG_FILE"
        fi
    fi
done

# Review → Done (PEPPER auto-complete)
REVIEW_COUNT=$(cat "$BOARD_FILE" | jq '[.cards[] | select(.status == "review")] | length')
if [ "$REVIEW_COUNT" -gt 0 ]; then
    REVIEW_ID=$(cat "$BOARD_FILE" | jq -r '.cards[] | select(.status == "review") | .id' | head -1)
    cat "$BOARD_FILE" | jq --arg id "$REVIEW_ID" '.cards = [.cards[] | if .id == $id then .status = "done" else . end]' > "$BOARD_FILE.tmp"
    mv "$BOARD_FILE.tmp" "$BOARD_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M')] | PEPPER | DONE | $REVIEW_ID | Auto completed" >> "$LOG_FILE"
fi
