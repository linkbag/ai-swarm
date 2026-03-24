# Swarm Lead — Heartbeat Checks

## Agent Swarm Notifications (TOP PRIORITY)

### Step 1: Read pending notifications
```bash
cat ~/workspace/swarm/pending-notifications.txt
```
If it has content → send EACH line to WB → then clear the file:
```bash
> ~/workspace/swarm/pending-notifications.txt
```

### Step 2: Run pulse check for stuck agents
```bash
~/workspace/swarm/pulse-check.sh
```
Detects stuck agents (auth prompts, no output change for 30+ min, error loops) and auto-kills them. If it kills any agent, it writes to pending-notifications.txt — send those too.

### Step 3: Check tmux for completed agents
```bash
tmux ls
```
If any expected agent sessions are gone → agent completed → check git log in the project dir → notify WB with what was produced.

### Step 4: If agents are actively running
Report brief status: "X agents still running, ~Y min elapsed"

### Rules
- If you find notifications, DO NOT reply HEARTBEAT_OK — send the notifications instead.
- Clear the file AFTER sending, not before.

## Weekly Model Assessment
- Check `~/workspace/swarm/duty-table.json`
- If `nextAssessment` date has passed, run `assess-models.sh` and notify WB of any duty table changes
- Report: which models gained/lost access, and new duty assignments

## Obsidian Vault Sync
- After any significant swarm changes, update `/mnt/d/Obsidian projects/OpenClaw Swarm Orchestration/Dashboard.md`
- Keep duty table, agent status, and "what's built" sections current
- Drop build logs to `Logs/YYYY-MM-DD.md` after work sessions
