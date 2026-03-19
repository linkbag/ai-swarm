#!/usr/bin/env bash
# monitor-and-notify.sh — Check for completed agents and write notifications
# Called by cron every 5 minutes when agents are active

SWARM_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_FILE="$SWARM_DIR/pending-notifications.txt"

# Check pending notifications file
if [[ -s "$NOTIFY_FILE" ]]; then
  echo "NOTIFY: $(cat "$NOTIFY_FILE")"
  exit 0
fi

# Check if any tmux agent sessions are still alive
ACTIVE=$(tmux ls 2>/dev/null | grep -E "^(claude|codex|gemini)-" | wc -l)

if [[ "$ACTIVE" -eq 0 ]]; then
  # No agent sessions running — they all completed
  echo "NO_AGENTS_RUNNING"
else
  echo "AGENTS_STILL_RUNNING: $ACTIVE active"
  tmux ls 2>/dev/null | grep -E "^(claude|codex|gemini)-"
fi
