#!/usr/bin/env bash
# esr-log.sh — Executive Summary Report per project
#
# Usage: esr-log.sh <project-dir> [summary-text]
#
# Maintains ONE living ESR per project at:
#   - <project>/docs/ESR.md (codebase, pushed to GitHub)
#   - /mnt/d/Obsidian projects/<Project>/ESR.md (Obsidian vault)
#
# This is NOT a per-agent log. It's an executive summary maintained by the orchestrator.
# Contains: what's been achieved, latest updates, what's next, actionable levers.

set -euo pipefail

PROJECT_DIR="${1:?Usage: esr-log.sh <project-dir> [summary-text]}"
SUMMARY="${2:-}"

PROJECT_NAME=$(basename "$PROJECT_DIR")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
DATE=$(date "+%Y-%m-%d")

# Determine paths
CODEBASE_ESR="$PROJECT_DIR/docs/ESR.md"
OBSIDIAN_BASE="/mnt/d/Obsidian projects"
OBSIDIAN_ESR="$OBSIDIAN_BASE/$PROJECT_NAME/ESR.md"

# Migrate old EOR → ESR if needed
OLD_EOR="$PROJECT_DIR/docs/EOR.md"
if [[ -f "$OLD_EOR" ]] && [[ ! -f "$CODEBASE_ESR" ]]; then
  mv "$OLD_EOR" "$CODEBASE_ESR"
  sed -i 's/Executive Summary (EOR)/Executive Summary Report (ESR)/g' "$CODEBASE_ESR"
  sed -i 's/EOR/ESR/g' "$CODEBASE_ESR"
  echo "[esr] Migrated EOR → ESR for $PROJECT_NAME"
fi
OLD_OBS_EOR="$OBSIDIAN_BASE/$PROJECT_NAME/EOR.md"
if [[ -f "$OLD_OBS_EOR" ]] && [[ ! -f "$OBSIDIAN_ESR" ]]; then
  mv "$OLD_OBS_EOR" "$OBSIDIAN_ESR"
  sed -i 's/Executive Summary (EOR)/Executive Summary Report (ESR)/g' "$OBSIDIAN_ESR"
  sed -i 's/EOR/ESR/g' "$OBSIDIAN_ESR"
fi

# Create directories
mkdir -p "$PROJECT_DIR/docs"
mkdir -p "$OBSIDIAN_BASE/$PROJECT_NAME"

# If ESR doesn't exist yet, create template
if [[ ! -f "$CODEBASE_ESR" ]]; then
  cat > "$CODEBASE_ESR" << TEMPLATE
# $PROJECT_NAME — Executive Summary Report (ESR)
*Last updated: $TIMESTAMP*

## What We've Built
<!-- High-level summary of what exists -->

## Latest Updates
<!-- Most recent session's work -->

## What's Next
<!-- Prioritized next steps -->

## Actionable Levers
<!-- What would it take to make this succeed? Key decisions, resources, blockers -->

## Learnings
<!-- Technical and product lessons learned -->

---
*This is a living document maintained by the orchestrator. Updated after each work session.*
TEMPLATE
fi

# If summary provided, append as an update
if [[ -n "$SUMMARY" ]]; then
  # Update the "Last updated" timestamp
  sed -i "s/\*Last updated:.*\*/*Last updated: $TIMESTAMP*/" "$CODEBASE_ESR"
  
  # Append update entry
  cat >> "$CODEBASE_ESR" << UPDATE

### Update: $TIMESTAMP
$SUMMARY
UPDATE
fi

# Sync to Obsidian
cp "$CODEBASE_ESR" "$OBSIDIAN_ESR"

echo "[esr] Updated ESR for $PROJECT_NAME at $TIMESTAMP"
echo "  → $CODEBASE_ESR"
echo "  → $OBSIDIAN_ESR"
