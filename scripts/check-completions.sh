#!/usr/bin/env bash
# check-completions.sh — Cron-based backup notifier
# Runs every 5 minutes via cron. Checks pending-notifications.txt for unsent notifications.
# This is a BACKUP — primary notifications come from notify-on-complete.sh watchers.
# If watchers die (process killed, WSL restart), this catches what they missed.

# Ensure PATH includes openclaw + node (cron has minimal PATH)
export PATH="/home/dz/.npm-global/bin:/home/dz/.local/bin:/usr/local/bin:/usr/bin:/bin:/home/dz/.volta/bin:/home/dz/.nvm/current/bin:$PATH"

set -euo pipefail

SWARM_DIR="/home/dz/.openclaw/workspace/swarm"
NOTIFY_FILE="$SWARM_DIR/pending-notifications.txt"
SENT_FILE="$SWARM_DIR/sent-notifications.txt"

# Create sent tracker if missing
touch "$SENT_FILE"

# Nothing to do if no pending notifications
[[ ! -s "$NOTIFY_FILE" ]] && exit 0

# Check each line — if not in sent file, send it
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  
  # Skip if already sent
  if grep -Fxq "$line" "$SENT_FILE" 2>/dev/null; then
    continue
  fi
  
  # Send via Telegram
  openclaw message send --channel telegram --target "6148615057" --message "📋 $line" 2>/dev/null && {
    echo "$line" >> "$SENT_FILE"
  }
  
  # Rate limit: 1 message per 2 seconds
  sleep 2
done < "$NOTIFY_FILE"

# Keep sent file from growing forever (last 200 lines)
tail -200 "$SENT_FILE" > "$SENT_FILE.tmp" && mv "$SENT_FILE.tmp" "$SENT_FILE"
