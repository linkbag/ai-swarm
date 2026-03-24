# Swarm Lead — Tools Notes

## ⛔ PRE-FLIGHT CHECK (read this EVERY time before spawning agents)

Before ANY agent work, ask yourself:
1. Did I present a plan to WB and get endorsement? → If NO, stop and present the plan.
2. Am I using `spawn-agent.sh` (single) or `spawn-batch.sh` (multi)? → If NO, STOP. Do NOT use bare `claude --print`, background exec, or any other method. The scripts handle tmux, notifications, watchers, ESR — everything.
3. Will WB get a Telegram notification? → If NO, something is wrong.

**The scripts ARE the swarm. Bypassing them = no swarm.**

## spawn-batch.sh Usage

```bash
# 1. Write task prompts to /tmp/
cat > /tmp/prompt-task1.md << 'EOF'
... task description ...
EOF

# 2. Create tasks JSON
cat > /tmp/batch-tasks.json << 'EOF'
[
  {"id": "task-1", "description": "/tmp/prompt-task1.md", "agent": "claude", "model": "claude-sonnet-4-6"},
  {"id": "task-2", "description": "/tmp/prompt-task2.md", "agent": "claude", "model": "claude-sonnet-4-6"}
]
EOF

# 3. Spawn batch (auto-endorses + auto-integration)
cd ~/workspace/swarm
bash spawn-batch.sh "/mnt/d/Startup projects/ProjectName" "batch-id" "Batch description" /tmp/batch-tasks.json
```

## Prompt Template

**DO NOT include `openclaw system event` in agent prompts.** The `notify-on-complete.sh` watcher 
handles completion notifications automatically (and is more reliable — fires even if agent crashes).
Adding it to prompts causes duplicate notifications.

Work log instructions are auto-appended by `spawn-agent.sh` — don't duplicate them either.

## Integration Conflict Resolution
When integration agent hits conflicts:
- Keep the most complete version of shared files
- For i18n + UX conflicts: keep UX styling, apply stringResource() extraction
- For DB migrations: combine migrations with sequential version numbers
- Always verify build after resolution: `./gradlew assembleDebug` (Android) or `npm run build` (web)

## Agent Selection Guide
| Task Type | Agent | Model | Why |
|-----------|-------|-------|-----|
| Complex architecture | Claude | Opus | Best reasoning |
| Standard features | Claude | Sonnet | Fast, reliable |
| Quick fixes/UI tweaks | Claude | Sonnet | Speed |
| Parallel bulk work | Claude | Sonnet | Cost-effective |
| AI/ML research tasks | Claude | Opus | Deep analysis |

Codex (GPT-5.3) and Gemini available but currently benched (quota issues as of Mar 2026).
