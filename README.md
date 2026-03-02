# Mission Control

Autonomous multi-agent system for task management.

## Agents

- **JARVIS** - Product Decomposer
- **BANNER** - Execution Worker  
- **PEPPER** - Quality & Refinement

## Architecture

```
MissionControl/
├── board-state.json    # Shared task board
├── jarvis-dispatcher.sh  # Auto-dispatcher (cron)
├── web/                # Web interface
└── logs/              # Agent activity logs
```

## Running

```bash
# Start web server
cd web && node server.js

# Start dispatcher (cron)
*/5 * * * * /path/to/jarvis-dispatcher.sh
```

## Status

- 51 tasks completed
- 100% autonomous operation
