#!/usr/bin/env bash
# setup.sh — Initialize AI Swarm system in current workspace
# Usage: bash setup.sh [swarm-dir]
#   swarm-dir: where to install (default: ~/.openclaw/workspace/swarm)

set -euo pipefail

SWARM_DIR="${1:-$HOME/.openclaw/workspace/swarm}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "🐝 AI Swarm — Setup"
echo "   Install to: $SWARM_DIR"
echo ""

mkdir -p "$SWARM_DIR"/{logs,endorsements,prompts,templates}

# Copy scripts
echo "📦 Installing scripts..."
for f in "$SKILL_DIR/scripts/"*.sh; do
  fname=$(basename "$f")
  if [[ "$fname" != "setup.sh" ]]; then
    cp "$f" "$SWARM_DIR/"
    chmod +x "$SWARM_DIR/$fname"
    echo "  ✅ $fname"
  fi
done

# Copy templates
cp "$SKILL_DIR/references/EOR-TEMPLATE.md" "$SWARM_DIR/templates/" 2>/dev/null || true

# Initialize config files (only if they don't exist — never overwrite state)
if [[ ! -f "$SWARM_DIR/active-tasks.json" ]]; then
  echo '{"tasks":[]}' > "$SWARM_DIR/active-tasks.json"
  echo "  Created active-tasks.json"
fi

if [[ ! -f "$SWARM_DIR/usage-log.json" ]]; then
  echo '[]' > "$SWARM_DIR/usage-log.json"
  echo "  Created usage-log.json"
fi

if [[ ! -f "$SWARM_DIR/duty-table.json" ]]; then
  python3 -c "
import json
data = {
  'assessedAt': '',
  'nextAssessment': '',
  'availableAgents': {
    'claude': {'cli': 'claude', 'auth': 'oauth', 'status': 'active', 'models': {
      'claude-opus-4-6': {'status': 'available', 'tier': 'top'},
      'claude-sonnet-4-6': {'status': 'available', 'tier': 'mid'}
    }},
    'codex': {'cli': 'codex', 'auth': 'oauth', 'status': 'unknown', 'models': {
      'gpt-5.3-codex': {'status': 'unknown', 'tier': 'top'}
    }},
    'gemini': {'cli': 'gemini', 'auth': 'oauth', 'status': 'unknown', 'models': {
      'gemini-2.5-pro': {'status': 'unknown', 'tier': 'top'},
      'gemini-2.5-flash': {'status': 'unknown', 'tier': 'mid'}
    }}
  },
  'dutyTable': {
    'architect': {'agent': 'claude', 'model': 'claude-opus-4-6', 'reason': 'Default: best reasoning', 'nonInteractiveCmd': 'claude --model claude-opus-4-6 --dangerously-skip-permissions -p'},
    'workhorse': {'agent': 'claude', 'model': 'claude-sonnet-4-6', 'reason': 'Default: fast + reliable', 'nonInteractiveCmd': 'claude --model claude-sonnet-4-6 --dangerously-skip-permissions -p'},
    'reviewer': {'agent': 'claude', 'model': 'claude-sonnet-4-6', 'reason': 'Default: fast review', 'nonInteractiveCmd': 'claude --model claude-sonnet-4-6 --dangerously-skip-permissions -p'},
    'speedster': {'agent': 'claude', 'model': 'claude-sonnet-4-6', 'reason': 'Default: fastest', 'nonInteractiveCmd': 'claude --model claude-sonnet-4-6 --dangerously-skip-permissions -p'}
  },
  'history': [],
  'manualOverride': {'enabled': False}
}
with open('$SWARM_DIR/duty-table.json', 'w') as f:
  json.dump(data, f, indent=2)
"
  echo "  Created duty-table.json (default Claude-only)"
fi

# Install role files
ROLES_DIR="$HOME/.openclaw/workspace/roles/swarm-lead"
mkdir -p "$ROLES_DIR"
if [[ ! -f "$ROLES_DIR/ROLE.md" ]]; then
  cp "$SKILL_DIR/references/ROLE.md" "$ROLES_DIR/" 2>/dev/null || true
  cp "$SKILL_DIR/references/TOOLS.md" "$ROLES_DIR/" 2>/dev/null || true
  cp "$SKILL_DIR/references/HEARTBEAT.md" "$ROLES_DIR/" 2>/dev/null || true
  echo "  Installed swarm-lead role files"
fi

# Setup cron (only if not already present)
CRON_MARKER="duty-cycle.sh"
if ! crontab -l 2>/dev/null | grep -q "$CRON_MARKER"; then
  echo ""
  echo "📅 Setting up cron jobs..."
  EXISTING_CRON=$(crontab -l 2>/dev/null || true)
  echo "${EXISTING_CRON}
# AI Swarm System — auto-assessment every 6 hours
0 */6 * * * $SWARM_DIR/duty-cycle.sh >> $SWARM_DIR/logs/duty-cycle.log 2>&1
# AI Swarm System — check completions every 5 min
*/5 * * * * $SWARM_DIR/check-completions.sh >> $SWARM_DIR/logs/cron-completions.log 2>&1" | crontab -
  echo "  ✅ Cron installed (duty-cycle every 6h, completions every 5m)"
else
  echo "  ℹ️  Cron already configured"
fi

# Create workspace symlink if not present
if [[ ! -e "$HOME/workspace/swarm" ]]; then
  ln -s "$SWARM_DIR" "$HOME/workspace/swarm" 2>/dev/null && echo "  Created ~/workspace/swarm symlink" || true
fi

echo ""
echo "✅ AI Swarm installed at $SWARM_DIR"
echo ""
echo "Next steps:"
echo "  1. Run: bash $SWARM_DIR/assess-models.sh"
echo "     (Tests which agents are available and sets up the duty table)"
echo "  2. Add 'swarm-lead' to your roles/active.json"
echo "  3. Start spawning: bash $SWARM_DIR/spawn-batch.sh <project> <batch-id> <desc> <tasks.json>"
