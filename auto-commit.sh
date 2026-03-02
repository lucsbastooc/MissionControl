#!/bin/bash
# Auto-commit changes to GitHub
cd ~/.openclaw/workspace/MissionControl

# Check if there are changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    git add -A
    git commit -m "chore: $(date '+%Y-%m-%d %H:%M') - board update"
    git push origin master 2>&1
fi
