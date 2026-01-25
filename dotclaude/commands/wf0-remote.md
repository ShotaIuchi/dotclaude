---
description: Remote workflow operation via GitHub Issue
argument-hint: "<start|stop|status> [work-id|--all|pattern]"
---

# /wf0-remote

Command for remote workflow monitoring and execution via GitHub Issue comments.
Enables workflow approval from mobile devices while PC daemon executes the commands.

## Usage

```
/wf0-remote <subcommand> [work-id|--all|pattern]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `start [target]` | Start remote monitoring (launches in tmux session) |
| `stop [target]` | Stop remote monitoring |
| `status` | Show current monitoring status |

## Arguments

- `target`: Target specification (optional)
  - `work-id`: Single work ID (e.g., `FEAT-123-auth`, `FIX-456-login-error`)
  - `--all`: All works with GitHub source
  - `pattern`: Wildcard pattern (e.g., `FEAT-*`, `*-auth`, `FIX-???-*`)
  - If omitted: Use `active_work` from `state.json`

## Target Examples

```bash
# Single work
/wf0-remote start FEAT-123-auth

# All GitHub-sourced works
/wf0-remote start --all
/wf0-remote stop --all

# Wildcard patterns
/wf0-remote start FEAT-*      # All works starting with FEAT-
/wf0-remote start *-auth      # All works ending with -auth
/wf0-remote stop FIX-???-*    # FIX- followed by 3 chars and any suffix
```

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Subcommand and Target

```bash
subcommand=$(echo "$ARGUMENTS" | awk '{print $1}')
target=$(echo "$ARGUMENTS" | awk '{print $2}')

if [ -z "$subcommand" ]; then
  echo "ERROR: Subcommand required (start|stop|status)"
  exit 1
fi

# Determine target type
if [ "$target" = "--all" ]; then
  target_type="all"
elif [[ "$target" == *"*"* ]] || [[ "$target" == *"?"* ]]; then
  target_type="pattern"
  target_pattern="$target"
elif [ -n "$target" ]; then
  target_type="single"
  work_id="$target"
else
  target_type="single"  # Will use active_work
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

### 3. Resolve Target Works

```bash
# Get all work IDs
all_works=$(jq -r '.works | keys[]' .wf/state.json)

# Build work_ids array based on target type
work_ids=()

case "$target_type" in
  "all")
    for wid in $all_works; do
      source_type=$(jq -r ".works[\"$wid\"].source.type // empty" .wf/state.json)
      if [ "$source_type" = "github" ]; then
        work_ids+=("$wid")
      fi
    done
    ;;
  "pattern")
    for wid in $all_works; do
      # Use bash case for glob pattern matching
      case "$wid" in
        $target_pattern) work_ids+=("$wid") ;;
      esac
    done
    ;;
  "single")
    if [ -z "$work_id" ] && [ "$subcommand" != "status" ]; then
      work_id=$(jq -r '.active_work // empty' .wf/state.json)
    fi
    if [ -n "$work_id" ]; then
      work_ids+=("$work_id")
    fi
    ;;
esac

# Validate we have targets (except for status)
if [ "$subcommand" != "status" ] && [ ${#work_ids[@]} -eq 0 ]; then
  echo "ERROR: No matching works found"
  if [ "$target_type" = "pattern" ]; then
    echo "Pattern '$target_pattern' did not match any works"
    echo ""
    echo "Available works:"
    for wid in $all_works; do
      echo "  - $wid"
    done
  elif [ "$target_type" = "all" ]; then
    echo "No works with GitHub source found"
  else
    echo "Please specify work-id or run /wf1-kickoff"
  fi
  exit 1
fi
```

### 4. Execute Subcommand

#### 4.1 start

Start the remote monitoring daemon in a tmux session. Supports multiple works.

```bash
echo "📡 Starting Remote Monitoring"
echo "═══════════════════════════════════════"
echo ""

# Track results
started=()
already_running=()
skipped=()
failed=()

# Show target works
if [ "$target_type" = "all" ] || [ "$target_type" = "pattern" ]; then
  echo "Target works (${#work_ids[@]}):"
  for wid in "${work_ids[@]}"; do
    issue=$(jq -r ".works[\"$wid\"].source.issue // \"?\"" .wf/state.json)
    echo "  - $wid (#$issue)"
  done
  echo ""
fi

# Check for non-github works that would be skipped (for --all or pattern)
if [ "$target_type" != "single" ]; then
  for wid in $all_works; do
    source_type=$(jq -r ".works[\"$wid\"].source.type // empty" .wf/state.json)
    if [ "$source_type" != "github" ]; then
      # Check if it would match the pattern
      if [ "$target_type" = "all" ]; then
        skipped+=("$wid (non-github source)")
      elif [ "$target_type" = "pattern" ]; then
        case "$wid" in
          $target_pattern) skipped+=("$wid (non-github source)") ;;
        esac
      fi
    fi
  done

  if [ ${#skipped[@]} -gt 0 ]; then
    echo "⚠️  Skipped (non-github source):"
    for s in "${skipped[@]}"; do
      echo "  - $s"
    done
    echo ""
  fi
fi

echo "═══════════════════════════════════════"
echo ""

# Process each work
for wid in "${work_ids[@]}"; do
  # Get source issue number
  source_type=$(jq -r ".works[\"$wid\"].source.type // empty" .wf/state.json)
  source_issue=$(jq -r ".works[\"$wid\"].source.issue // empty" .wf/state.json)

  if [ "$source_type" != "github" ] || [ -z "$source_issue" ]; then
    if [ "$target_type" = "single" ]; then
      echo "ERROR: No GitHub issue found for $wid"
      echo "Remote monitoring requires a GitHub Issue as source"
    fi
    failed+=("$wid")
    continue
  fi

  # Check if already running
  tmux_session="wf-remote-$wid"
  if tmux has-session -t "$tmux_session" 2>/dev/null; then
    already_running+=("$wid")
    continue
  fi

  # Start daemon in tmux
  if tmux new-session -d -s "$tmux_session" \
    "$HOME/.claude/scripts/remote/remote-daemon.sh $wid" 2>/dev/null; then

    # Update state.json
    jq ".works[\"$wid\"].remote = {
      \"enabled\": true,
      \"source_issue\": $source_issue,
      \"poll_interval\": 60,
      \"last_check\": null,
      \"status\": \"waiting_approval\",
      \"tmux_session\": \"$tmux_session\"
    }" .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json

    started+=("$wid:#$source_issue")
  else
    failed+=("$wid")
  fi
done

# Show results summary
if [ ${#started[@]} -gt 0 ]; then
  echo "🚀 Started (${#started[@]}):"
  for s in "${started[@]}"; do
    wid="${s%%:*}"
    issue="${s##*:}"
    echo "  ✅ $wid ($issue)"
  done
  echo ""
fi

if [ ${#already_running[@]} -gt 0 ]; then
  echo "ℹ️  Already running (${#already_running[@]}):"
  for wid in "${already_running[@]}"; do
    echo "  - $wid"
  done
  echo ""
fi

if [ ${#failed[@]} -gt 0 ]; then
  echo "❌ Failed (${#failed[@]}):"
  for wid in "${failed[@]}"; do
    echo "  - $wid"
  done
  echo ""
fi

# Show usage info if any started
if [ ${#started[@]} -gt 0 ]; then
  echo "Available commands in Issue comments:"
  echo "  /approve  - Execute next workflow step"
  echo "  /next     - Same as /approve"
  echo "  /pause    - Pause monitoring temporarily"
  echo "  /stop     - Stop monitoring completely"
  echo ""
  echo "To view daemon output:"
  if [ ${#started[@]} -eq 1 ]; then
    wid="${started[0]%%:*}"
    echo "  tmux attach -t wf-remote-$wid"
  else
    echo "  tmux attach -t wf-remote-<work-id>"
  fi
fi
```

#### 4.2 stop

Stop the remote monitoring daemon. Supports multiple works.

```bash
echo "🛑 Stopping Remote Monitoring"
echo "═══════════════════════════════════════"
echo ""

# For --all in stop, target all works with remote.enabled=true
if [ "$target_type" = "all" ]; then
  work_ids=()
  for wid in $all_works; do
    enabled=$(jq -r ".works[\"$wid\"].remote.enabled // false" .wf/state.json)
    if [ "$enabled" = "true" ]; then
      work_ids+=("$wid")
    fi
  done

  if [ ${#work_ids[@]} -eq 0 ]; then
    echo "ℹ️  No active remote monitoring sessions to stop"
    exit 0
  fi
fi

# Track results
stopped=()
not_running=()

# Show target works
if [ "$target_type" = "all" ] || [ "$target_type" = "pattern" ]; then
  echo "Target works (${#work_ids[@]}):"
  for wid in "${work_ids[@]}"; do
    echo "  - $wid"
  done
  echo ""
  echo "═══════════════════════════════════════"
  echo ""
fi

# Process each work
for wid in "${work_ids[@]}"; do
  tmux_session="wf-remote-$wid"

  if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
    not_running+=("$wid")
    # Still update state.json to ensure consistency
    jq ".works[\"$wid\"].remote.enabled = false |
        .works[\"$wid\"].remote.status = \"stopped\"" \
      .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json
    continue
  fi

  # Kill the tmux session
  tmux kill-session -t "$tmux_session"

  # Update state.json
  jq ".works[\"$wid\"].remote.enabled = false |
      .works[\"$wid\"].remote.status = \"stopped\"" \
    .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json

  stopped+=("$wid")
done

# Show results summary
if [ ${#stopped[@]} -gt 0 ]; then
  echo "✅ Stopped (${#stopped[@]}):"
  for wid in "${stopped[@]}"; do
    echo "  - $wid"
  done
  echo ""
fi

if [ ${#not_running[@]} -gt 0 ]; then
  echo "ℹ️  Not running (${#not_running[@]}):"
  for wid in "${not_running[@]}"; do
    echo "  - $wid"
  done
  echo ""
fi

if [ ${#stopped[@]} -eq 0 ] && [ ${#not_running[@]} -gt 0 ]; then
  echo "No active sessions were running"
fi
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

### Start Success (Single)

```
📡 Starting Remote Monitoring
═══════════════════════════════════════

═══════════════════════════════════════

🚀 Started (1):
  ✅ FEAT-123-auth (#123)

Available commands in Issue comments:
  /approve  - Execute next workflow step
  /next     - Same as /approve
  /pause    - Pause monitoring temporarily
  /stop     - Stop monitoring completely

To view daemon output:
  tmux attach -t wf-remote-FEAT-123-auth
```

### Start Success (Multiple with --all)

```
📡 Starting Remote Monitoring
═══════════════════════════════════════

Target works (3):
  - FEAT-123-auth (#123)
  - FEAT-456-export (#456)
  - FIX-789-login (#789)

⚠️  Skipped (non-github source):
  - LOCAL-001-refactor (non-github source)

═══════════════════════════════════════

🚀 Started (2):
  ✅ FEAT-123-auth (#123)
  ✅ FIX-789-login (#789)

ℹ️  Already running (1):
  - FEAT-456-export

Available commands in Issue comments:
  /approve  - Execute next workflow step
  /next     - Same as /approve
  /pause    - Pause monitoring temporarily
  /stop     - Stop monitoring completely

To view daemon output:
  tmux attach -t wf-remote-<work-id>
```

### Stop Success (Multiple)

```
🛑 Stopping Remote Monitoring
═══════════════════════════════════════

Target works (2):
  - FEAT-123-auth
  - FIX-789-login

═══════════════════════════════════════

✅ Stopped (2):
  - FEAT-123-auth
  - FIX-789-login
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
