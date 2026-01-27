---
name: wf0-remote
description: Remote workflow operation via GitHub Issue
---

**Always respond in Japanese.**

# /wf0-remote

Command for remote workflow monitoring and execution via GitHub Issue comments.
Enables workflow approval from mobile devices while PC daemon executes the commands.

## Usage

```
/wf0-remote <subcommand> [target...]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `start [target...]` | Start remote monitoring (launches in tmux session) |
| `stop [target...]` | Stop remote monitoring |
| `status` | Show current monitoring status |

## Arguments

- `target`: Target specification (optional, supports multiple)
  - `work-id...`: One or more work IDs (e.g., `FEAT-123-auth FIX-456-login`)
  - `--all`: All works with GitHub source
  - `pattern`: Wildcard pattern (e.g., `FEAT-*`, `*-auth`, `FIX-???-*`)
  - If omitted: Use `active_work` from `state.json`

## Target Examples

```bash
# Single work
/wf0-remote start FEAT-123-auth

# Multiple works (variadic)
/wf0-remote start FEAT-123-auth FIX-456-login FEAT-789-export
/wf0-remote stop FEAT-123 FEAT-456

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

### 1. Parse Subcommand and Targets

```bash
subcommand=$(echo "$ARGUMENTS" | awk '{print $1}')

# Get all arguments after subcommand
targets=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}' | xargs)

if [ -z "$subcommand" ]; then
  echo "ERROR: Subcommand required (start|stop|status)"
  exit 1
fi

# Determine target type
first_target=$(echo "$targets" | awk '{print $1}')
target_count=$(echo "$targets" | wc -w | xargs)

if [ "$first_target" = "--all" ]; then
  target_type="all"
elif [[ "$first_target" == *"*"* ]] || [[ "$first_target" == *"?"* ]]; then
  target_type="pattern"
  target_pattern="$first_target"
elif [ "$target_count" -gt 1 ]; then
  target_type="multiple"
  target_list="$targets"
elif [ -n "$first_target" ]; then
  target_type="single"
  work_id="$first_target"
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
  "multiple")
    # Multiple work IDs specified directly
    for wid in $target_list; do
      # Verify work exists
      if jq -e ".works[\"$wid\"]" .wf/state.json > /dev/null 2>&1; then
        work_ids+=("$wid")
      else
        echo "WARNING: Work '$wid' not found, skipping"
      fi
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

#### 4.2 stop

Stop the remote monitoring daemon. Supports multiple works.

#### 4.3 status

Show current remote monitoring status.

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
Starting Remote Monitoring
===

===

Started (1):
  FEAT-123-auth (#123)

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
Starting Remote Monitoring
===

Target works (3):
  - FEAT-123-auth (#123)
  - FEAT-456-export (#456)
  - FIX-789-login (#789)

Skipped (non-github source):
  - LOCAL-001-refactor (non-github source)

===

Started (2):
  FEAT-123-auth (#123)
  FIX-789-login (#789)

Already running (1):
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
Stopping Remote Monitoring
===

Target works (2):
  - FEAT-123-auth
  - FIX-789-login

===

Stopped (2):
  - FEAT-123-auth
  - FIX-789-login
```

### Status Display

```
Remote Monitoring Status
===

Work: FEAT-123-auth
  Issue:      #123
  Status:     waiting_approval
  Session:    wf-remote-FEAT-123-auth (running)
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
