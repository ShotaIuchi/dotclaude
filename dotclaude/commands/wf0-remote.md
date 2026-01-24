---
description: Remote workflow operation via GitHub Issue
argument-hint: "<start|stop|status> [work-id]"
---

# /wf0-remote

Command for remote workflow monitoring and execution via GitHub Issue comments.
Enables workflow approval from mobile devices while PC daemon executes the commands.

## Usage

```
/wf0-remote <subcommand> [work-id]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `start [work-id]` | Start remote monitoring (launches in tmux session) |
| `stop [work-id]` | Stop remote monitoring |
| `status` | Show current monitoring status |

## Arguments

- `work-id`: Target work ID (optional)
  - Format: `TYPE-ISSUE-SLUG` (e.g., `FEAT-123-auth`, `FIX-456-login-error`)
  - If omitted: Use `active_work` from `state.json`

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Subcommand

```bash
subcommand=$(echo "$ARGUMENTS" | awk '{print $1}')
work_id=$(echo "$ARGUMENTS" | awk '{print $2}')

if [ -z "$subcommand" ]; then
  echo "ERROR: Subcommand required (start|stop|status)"
  exit 1
fi
```

### 2. Load state.json

```bash
if [ ! -f .wf/state.json ]; then
  echo "WF system is not initialized"
  echo "Please create a workspace with /wf1-kickoff"
  exit 1
fi
```

### 3. Resolve work-id (for start/stop)

```bash
if [ -z "$work_id" ] && [ "$subcommand" != "status" ]; then
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi

if [ -z "$work_id" ] && [ "$subcommand" != "status" ]; then
  echo "ERROR: Please specify work-id or run /wf1-kickoff"
  exit 1
fi
```

### 4. Execute Subcommand

#### 4.1 start

Start the remote monitoring daemon in a tmux session.

```bash
# Get source issue number
source_issue=$(jq -r ".works[\"$work_id\"].source.issue // empty" .wf/state.json)

if [ -z "$source_issue" ]; then
  echo "ERROR: No source issue found for $work_id"
  echo "Remote monitoring requires a GitHub Issue as source"
  exit 1
fi

# Check if already running
tmux_session="wf-remote-$work_id"
if tmux has-session -t "$tmux_session" 2>/dev/null; then
  echo "Remote monitoring is already running for $work_id"
  echo "Session: $tmux_session"
  exit 0
fi

# Start daemon in tmux
tmux new-session -d -s "$tmux_session" \
  "$HOME/.claude/scripts/remote/remote-daemon.sh $work_id"

# Update state.json
jq ".works[\"$work_id\"].remote = {
  \"enabled\": true,
  \"source_issue\": $source_issue,
  \"poll_interval\": 60,
  \"last_check\": null,
  \"status\": \"waiting_approval\",
  \"tmux_session\": \"$tmux_session\"
}" .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json

echo "🚀 Remote monitoring started for $work_id"
echo ""
echo "Session: $tmux_session"
echo "Issue: #$source_issue"
echo ""
echo "Available commands in Issue comments:"
echo "  /approve  - Execute next workflow step"
echo "  /next     - Same as /approve"
echo "  /pause    - Pause monitoring temporarily"
echo "  /stop     - Stop monitoring completely"
echo ""
echo "To view daemon output:"
echo "  tmux attach -t $tmux_session"
```

#### 4.2 stop

Stop the remote monitoring daemon.

```bash
tmux_session="wf-remote-$work_id"

if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  echo "Remote monitoring is not running for $work_id"
  exit 0
fi

# Kill the tmux session
tmux kill-session -t "$tmux_session"

# Update state.json
jq ".works[\"$work_id\"].remote.enabled = false |
    .works[\"$work_id\"].remote.status = \"stopped\"" \
  .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json

echo "🛑 Remote monitoring stopped for $work_id"
```

#### 4.3 status

Show current remote monitoring status.

```bash
echo "📡 Remote Monitoring Status"
echo "═══════════════════════════════════════"
echo ""

# Get all works with remote enabled
works_with_remote=$(jq -r '.works | to_entries[] | select(.value.remote.enabled == true) | .key' .wf/state.json)

if [ -z "$works_with_remote" ]; then
  echo "No active remote monitoring sessions"
  exit 0
fi

for wid in $works_with_remote; do
  remote=$(jq -r ".works[\"$wid\"].remote" .wf/state.json)
  tmux_session=$(echo "$remote" | jq -r '.tmux_session')
  source_issue=$(echo "$remote" | jq -r '.source_issue')
  status=$(echo "$remote" | jq -r '.status')
  last_check=$(echo "$remote" | jq -r '.last_check // "never"')

  # Check if tmux session is actually running
  if tmux has-session -t "$tmux_session" 2>/dev/null; then
    running="✅ running"
  else
    running="❌ stopped"
  fi

  echo "Work: $wid"
  echo "  Issue:      #$source_issue"
  echo "  Status:     $status"
  echo "  Session:    $tmux_session ($running)"
  echo "  Last check: $last_check"
  echo ""
done
```

## Remote Commands

Commands that users can post as Issue comments:

| Command | Description |
|---------|-------------|
| `/approve` | Execute next workflow step |
| `/next` | Alias for `/approve` |
| `/pause` | Pause monitoring (resume with `/approve`) |
| `/stop` | Stop monitoring completely |

## State JSON Extension

```json
{
  "works": {
    "<work-id>": {
      "remote": {
        "enabled": true,
        "source_issue": 123,
        "poll_interval": 60,
        "last_check": "2026-01-24T10:00:00Z",
        "status": "waiting_approval",
        "tmux_session": "wf-remote-FEAT-123"
      }
    }
  }
}
```

**Fields:**
- `poll_interval`: Polling interval in seconds (default: 60, set in daemon script)
  - Currently not user-configurable; modify `POLL_INTERVAL` in `remote-daemon.sh` to customize

## Output Format

### Start Success

```
🚀 Remote monitoring started for FEAT-123-auth

Session: wf-remote-FEAT-123-auth
Issue: #123

Available commands in Issue comments:
  /approve  - Execute next workflow step
  /next     - Same as /approve
  /pause    - Pause monitoring temporarily
  /stop     - Stop monitoring completely

To view daemon output:
  tmux attach -t wf-remote-FEAT-123-auth
```

### Status Display

```
📡 Remote Monitoring Status
═══════════════════════════════════════

Work: FEAT-123-auth
  Issue:      #123
  Status:     waiting_approval
  Session:    wf-remote-FEAT-123-auth (✅ running)
  Last check: 2026-01-24T10:05:00Z
```

## Notes

- Requires `gh` CLI authenticated
- Requires `tmux` for daemon session management
- See `rules/remote-operation.md` for detailed security rules

### Security Summary

| Rule | Description |
|------|-------------|
| Collaborator-only | Only comments from users with `admin`, `write`, or `maintain` permission are processed |
| Step limit | Maximum 10 steps per session to prevent infinite loops |
| Command whitelist | Only `/approve`, `/next`, `/pause`, `/stop` are recognized |
| Execution scope | Only `/wf0-nextstep` is executed (no arbitrary commands) |
