#!/usr/bin/env bash
# try-model.sh — Test a model, return 0 if it works, 1 if it fails.
# Usage: try-model.sh <agent> <model>
#   agent: claude | gemini | codex
#   model: model name (e.g. gemini-2.5-pro, claude-sonnet-4-6)

set -euo pipefail

# macOS compatibility: use gtimeout if timeout not available
if ! command -v timeout &>/dev/null && command -v gtimeout &>/dev/null; then
  timeout() { gtimeout "$@"; }
fi

AGENT="${1:?Usage: try-model.sh <agent> <model>}"
MODEL="${2:?Missing model}"

TIMEOUT=45

case "$AGENT" in
  claude)
    timeout "$TIMEOUT" bash -c "echo 'Reply with OK' | claude --model $MODEL --permission-mode bypassPermissions --print 'Reply with just OK'" >/dev/null 2>&1
    ;;
  gemini)
    timeout "$TIMEOUT" bash -c "gemini -m $MODEL -y -p 'Reply with just OK'" >/dev/null 2>&1
    ;;
  codex)
    timeout "$TIMEOUT" bash -c "echo 'Reply with OK' | codex --model $MODEL -q 'Reply with just OK'" >/dev/null 2>&1
    ;;
  *)
    echo "[try-model] Unknown agent: $AGENT" >&2
    exit 1
    ;;
esac
