---
name: ai-swarm
description: >-
  AI agent swarm orchestration system for parallel multi-agent coding. Spawns
  Claude Code, Codex, and Gemini agents in tmux sessions with git worktrees,
  auto-reviews, auto-integrates branches, and manages a 3-vendor duty table
  with automatic model rotation. Use when: (1) building features with 2+
  parallel agents, (2) orchestrating multi-branch development with auto-merge,
  (3) managing agent duty rotation across Claude/Codex/Gemini, (4) running
  automated code review and integration pipelines. Requires: tmux, git, python3,
  and at least one coding CLI (claude, codex, or gemini).
---

# AI Swarm

Multi-agent orchestration system. Spawns parallel coding agents, auto-reviews, auto-integrates, auto-merges.

## Setup

### Quick Install (any platform)
```bash
# From ClawHub (if published):
clawhub install ai-swarm

# Or from GitHub:
git clone https://github.com/linkbag/ai-swarm.git
cd ai-swarm
bash scripts/setup.sh
```

### macOS Users
macOS ships with bash 3.2 — AI Swarm needs bash 4+:
```bash
brew install bash tmux python3
/opt/homebrew/bin/bash scripts/setup.sh
```

### Linux / WSL Users
```bash
sudo apt install tmux python3    # if not installed
bash scripts/setup.sh
```

### After Setup
```bash
bash ~/.openclaw/workspace/swarm/assess-models.sh
```
Tests which agents (Claude/Codex/Gemini) are available and configures the duty table.

Default install: `~/.openclaw/workspace/swarm/`. Creates directories, config files, cron jobs, and role files. Safe to re-run — never overwrites existing state.

## Architecture

```
swarm/
├── scripts/         ← 17 core scripts (spawn, monitor, integrate, assess)
├── duty-table.json  ← Model assignments (auto-rotated every 6h)
├── active-tasks.json← Task registry
├── endorsements/    ← Approval files (one per task)
├── logs/            ← Per-agent logs, integration logs
└── templates/       ← EOR template
```

### Duty Table (3-vendor pipeline)

| Role | Default | Purpose |
|------|---------|---------|
| Architect | Claude Opus | Complex design, architecture decisions |
| Workhorse | Codex/Claude Sonnet | Standard feature building |
| Reviewer | Gemini Pro/Claude Sonnet | Code review + fix |
| Speedster | Claude Sonnet | Quick fixes, integration |

Auto-assessed every 6 hours via cron. If a vendor hits quota limits, auto-rotates to another. See `references/ROLE.md` for full workflow.

## Core Workflow

### spawn-batch.sh (primary tool for parallel work)

```bash
# 1. Write prompts
cat > /tmp/prompt-task1.md << 'EOF'
Your task description...

When finished, run:
openclaw system event --text "Done: task-1 — summary" --mode now
EOF

# 2. Create tasks JSON
cat > /tmp/tasks.json << 'EOF'
[
  {"id": "task-1", "description": "/tmp/prompt-task1.md", "agent": "claude", "model": "claude-sonnet-4-6"},
  {"id": "task-2", "description": "/tmp/prompt-task2.md", "agent": "codex", "model": "gpt-5.3-codex"}
]
EOF

# 3. Spawn batch (auto-endorses + auto-starts integration watcher)
bash ~/workspace/swarm/spawn-batch.sh "/path/to/project" "batch-id" "Description" /tmp/tasks.json
```

This single command: creates worktrees, spawns tmux sessions, starts per-agent watchers, starts integration watcher, registers tasks, logs usage.

### spawn-agent.sh (single task only)

```bash
bash ~/workspace/swarm/spawn-agent.sh "/path/to/project" "task-id" "/tmp/prompt.md" claude claude-sonnet-4-6
```

Creates worktree + branch, spawns in tmux, starts completion watcher. Does NOT start integration watcher — use `start-integration.sh` manually if needed.

## Script Reference

| Script | Purpose |
|--------|---------|
| `spawn-batch.sh` | **Primary** — spawn N agents + auto-integration |
| `spawn-agent.sh` | Spawn single agent with worktree + watcher |
| `start-integration.sh` | Manual integration watcher start |
| `integration-watcher.sh` | Poll subteams, auto-merge when all done |
| `notify-on-complete.sh` | Per-agent watcher, chains reviewer |
| `assess-models.sh` | Test all agents, update duty table |
| `duty-cycle.sh` | 6-hourly assessment + quota-based rotation |
| `fallback-swap.sh` | Auto-fallback when agent hits limits |
| `check-agents.sh` | Quick tmux session status |
| `check-completions.sh` | Cron: check for completed agents |
| `pulse-check.sh` | Stuck detection (auth prompts, stalls) |
| `endorse-task.sh` | Create endorsement file for a task |
| `esr-log.sh` | Update project ESR after completion |
| `eor-log.sh` | End-of-run logging |
| `deploy-notify.sh` | Notify on deployment |
| `try-model.sh` | Quick model availability test |
| `monitor-and-notify.sh` | General monitoring helper |

## Role Files

Install to `roles/swarm-lead/` (done automatically by `setup.sh`):
- `ROLE.md` — Full 11-step workflow, rules, lessons learned. Read `references/ROLE.md`.
- `TOOLS.md` — CLI commands, conflict resolution patterns. Read `references/TOOLS.md`.
- `HEARTBEAT.md` — Periodic checks for stuck agents. Read `references/HEARTBEAT.md`.

## Key Rules

1. **Plan first** — present task breakdown to user before spawning
2. **Use spawn-batch.sh** for 2+ parallel tasks (never individual spawn-agent.sh for batch work)
3. **Reviewer = Fixer** — no separate fixer agent, avoids context loss
4. **Work logs flow** — `/tmp/worklog-{session}.md` from builder → reviewer → integrator
5. **Auto-merge** — merge after review+tests pass, only flag user on unresolvable conflicts
6. **Never overwrite state** — setup.sh preserves existing duty-table.json, active-tasks.json
