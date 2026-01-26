---
description: Batch execution control for scheduled workflows
argument-hint: "<start|stop|status|resume> [--parallel N] [--dry-run]"
---

# /wf0-batch

Command for controlling batch execution of scheduled workflows.
Uses worktrees for parallel execution with dependency resolution.

## Usage

```
/wf0-batch <subcommand> [options...]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `start [options]` | Start batch execution |
| `stop [--all \| work-id...]` | Stop execution |
| `status` | Show execution status |
| `resume` | Resume from paused/failed state |

## Options

| Option | Description |
|--------|-------------|
| `--parallel N` | Number of parallel workers (default: from config) |
| `--dry-run` | Show what would execute without running |
| `--all` | Target all running workers (for stop) |

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Subcommand and Options

```bash
subcommand=$(echo "$ARGUMENTS" | awk '{print $1}')
remaining=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}' | xargs)

if [ -z "$subcommand" ]; then
  echo "ERROR: Subcommand required (start|stop|status|resume)"
  exit 1
fi

# Parse options
parallel_count=""
dry_run=false
targets=()

for arg in $remaining; do
  case "$arg" in
    --parallel)
      shift_next=true
      ;;
    --dry-run)
      dry_run=true
      ;;
    --all)
      targets+=("--all")
      ;;
    *)
      if [ "$shift_next" = true ]; then
        parallel_count="$arg"
        shift_next=false
      else
        targets+=("$arg")
      fi
      ;;
  esac
done
```

### 2. Load Configuration and Schedule

```bash
SCHEDULE_FILE=".wf/schedule.json"
CONFIG_FILE=".wf/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  CONFIG_FILE="$HOME/.claude/examples/config.json"
fi

# Load default parallel count from config
if [ -z "$parallel_count" ]; then
  parallel_count=$(jq -r '.batch.default_parallel // 2' "$CONFIG_FILE")
fi

max_parallel=$(jq -r '.batch.max_parallel // 5' "$CONFIG_FILE")

if [ "$parallel_count" -gt "$max_parallel" ]; then
  echo "WARNING: Requested $parallel_count workers, limiting to max $max_parallel"
  parallel_count=$max_parallel
fi
```

### 3. Execute Subcommand

#### 3.1 start

Start batch execution.

```bash
if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "ERROR: No schedule found"
  echo "Use '/wf0-schedule create' to create a schedule first"
  exit 1
fi

echo "🚀 Starting Batch Execution"
echo "═══════════════════════════════════════"
echo ""

schedule=$(cat "$SCHEDULE_FILE")
schedule_status=$(echo "$schedule" | jq -r '.status')

if [ "$schedule_status" = "running" ]; then
  echo "ERROR: Batch is already running"
  echo "Use '/wf0-batch status' to check progress"
  echo "Use '/wf0-batch stop' to stop current execution"
  exit 1
fi

# Get pending works sorted by priority
pending_works=$(echo "$schedule" | jq -r '
  .works | to_entries
  | map(select(.value.status == "pending"))
  | sort_by(.value.priority)
  | .[].key
')

total_pending=$(echo "$pending_works" | grep -c . || echo 0)

if [ "$total_pending" -eq 0 ]; then
  echo "No pending works in schedule"
  exit 0
fi

echo "Workers:       $parallel_count"
echo "Pending works: $total_pending"
echo ""

# Display execution plan
echo "Execution Plan:"
echo "───────────────────────────────────────"

# Group by priority level
priority_levels=$(echo "$schedule" | jq -r '.works | to_entries | map(select(.value.status == "pending")) | .[].value.priority' | sort -n | uniq)

for level in $priority_levels; do
  works_at_level=$(echo "$schedule" | jq -r --argjson p "$level" '
    .works | to_entries
    | map(select(.value.status == "pending" and .value.priority == $p))
    | .[].key
  ')

  count=$(echo "$works_at_level" | grep -c . || echo 0)
  echo ""
  echo "Priority $level ($count works):"
  for work in $works_at_level; do
    deps=$(echo "$schedule" | jq -r ".works[\"$work\"].dependencies | if length > 0 then \" <- \" + join(\", \") else \"\" end")
    echo "  - $work$deps"
  done
done

echo ""
echo "═══════════════════════════════════════"

if [ "$dry_run" = true ]; then
  echo ""
  echo "🔍 Dry run mode - no changes made"
  exit 0
fi

echo ""
echo "Starting workers..."
echo ""

# Update schedule status
jq '.status = "running"' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
  mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

# Create worktree directory if needed
worktree_root=$(jq -r '.worktree.root_dir // ".worktrees"' "$CONFIG_FILE")
mkdir -p "$worktree_root"

# Start scheduler daemon in tmux
scheduler_session="wf-batch-scheduler"

if tmux has-session -t "$scheduler_session" 2>/dev/null; then
  echo "Scheduler session already exists, reusing..."
else
  tmux new-session -d -s "$scheduler_session" \
    "$HOME/.claude/scripts/batch/batch-daemon.sh" 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "✅ Scheduler daemon started"
  else
    echo "❌ Failed to start scheduler daemon"
    jq '.status = "failed"' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
      mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
    exit 1
  fi
fi

# Start worker processes
for i in $(seq 1 $parallel_count); do
  worker_session="wf-batch-worker-$i"

  if tmux has-session -t "$worker_session" 2>/dev/null; then
    echo "Worker $i already running"
    continue
  fi

  tmux new-session -d -s "$worker_session" \
    "$HOME/.claude/scripts/batch/batch-worker.sh $i" 2>/dev/null

  if [ $? -eq 0 ]; then
    echo "✅ Worker $i started"
    # Register worker in schedule
    jq --arg w "worker-$i" '.execution.sessions[$w] = {"status": "idle", "work_id": null}' \
      "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
  else
    echo "❌ Failed to start worker $i"
  fi
done

echo ""
echo "═══════════════════════════════════════"
echo ""
echo "Batch execution started!"
echo ""
echo "Monitor progress:"
echo "  /wf0-batch status"
echo ""
echo "View logs:"
echo "  tmux attach -t wf-batch-scheduler"
echo "  tmux attach -t wf-batch-worker-1"
echo ""
echo "Stop execution:"
echo "  /wf0-batch stop"
```

#### 3.2 stop

Stop batch execution.

```bash
echo "🛑 Stopping Batch Execution"
echo "═══════════════════════════════════════"
echo ""

# Determine targets
stop_all=false
stop_workers=()

if [ ${#targets[@]} -eq 0 ]; then
  stop_all=true
elif [ "${targets[0]}" = "--all" ]; then
  stop_all=true
else
  stop_workers=("${targets[@]}")
fi

stopped=()
not_running=()

if [ "$stop_all" = true ]; then
  # Stop scheduler
  if tmux has-session -t "wf-batch-scheduler" 2>/dev/null; then
    tmux kill-session -t "wf-batch-scheduler"
    stopped+=("scheduler")
  else
    not_running+=("scheduler")
  fi

  # Stop all workers
  for session in $(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^wf-batch-worker-'); do
    tmux kill-session -t "$session"
    stopped+=("$session")
  done
else
  # Stop specific workers
  for work_id in "${stop_workers[@]}"; do
    # Find worker running this work
    if [ -f "$SCHEDULE_FILE" ]; then
      worker=$(jq -r ".execution.sessions | to_entries | map(select(.value.work_id == \"$work_id\")) | .[0].key // empty" "$SCHEDULE_FILE")
      if [ -n "$worker" ]; then
        session="wf-batch-$worker"
        if tmux has-session -t "$session" 2>/dev/null; then
          tmux kill-session -t "$session"
          stopped+=("$session ($work_id)")
        fi
      fi
    fi
  done
fi

# Update schedule status
if [ -f "$SCHEDULE_FILE" ]; then
  jq '.status = "paused" | .execution.sessions = {}' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
    mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
fi

# Report results
if [ ${#stopped[@]} -gt 0 ]; then
  echo "✅ Stopped:"
  for s in "${stopped[@]}"; do
    echo "  - $s"
  done
fi

if [ ${#not_running[@]} -gt 0 ]; then
  echo ""
  echo "ℹ️  Not running:"
  for s in "${not_running[@]}"; do
    echo "  - $s"
  done
fi

echo ""
echo "═══════════════════════════════════════"
echo ""
echo "Use '/wf0-batch resume' to continue execution"
```

#### 3.3 status

Show current execution status.

```bash
echo "📊 Batch Execution Status"
echo "═══════════════════════════════════════"
echo ""

if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "No schedule found"
  exit 0
fi

schedule=$(cat "$SCHEDULE_FILE")

# Overall status
status=$(echo "$schedule" | jq -r '.status')
created=$(echo "$schedule" | jq -r '.created_at')

total=$(echo "$schedule" | jq -r '.progress.total')
completed=$(echo "$schedule" | jq -r '.progress.completed')
in_progress=$(echo "$schedule" | jq -r '.progress.in_progress')
pending=$(echo "$schedule" | jq -r '.progress.pending')
failed=$(echo "$schedule" | jq -r '[.works[] | select(.status == "failed")] | length')

echo "Schedule Status: $status"
echo "Created:         $created"
echo ""
echo "Progress:"
echo "  ✅ Completed:   $completed"
echo "  🔄 In Progress: $in_progress"
echo "  ⏳ Pending:     $pending"
if [ "$failed" -gt 0 ]; then
  echo "  ❌ Failed:      $failed"
fi
echo "  ─────────────"
echo "  📊 Total:       $total"
echo ""

# Active workers
echo "═══════════════════════════════════════"
echo "Workers:"
echo ""

scheduler_running=false
if tmux has-session -t "wf-batch-scheduler" 2>/dev/null; then
  scheduler_running=true
  echo "  📋 Scheduler: ✅ running"
else
  echo "  📋 Scheduler: ❌ stopped"
fi

echo ""

worker_count=0
for session in $(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^wf-batch-worker-' | sort); do
  worker_num="${session#wf-batch-worker-}"
  worker_key="worker-$worker_num"

  # Get current work from schedule
  current_work=$(echo "$schedule" | jq -r ".execution.sessions[\"$worker_key\"].work_id // \"idle\"")
  worker_status=$(echo "$schedule" | jq -r ".execution.sessions[\"$worker_key\"].status // \"unknown\"")

  if [ "$current_work" = "null" ] || [ "$current_work" = "idle" ]; then
    echo "  🔧 Worker $worker_num: idle"
  else
    echo "  🔧 Worker $worker_num: $current_work ($worker_status)"
  fi
  worker_count=$((worker_count + 1))
done

if [ $worker_count -eq 0 ]; then
  echo "  (no workers running)"
fi

echo ""

# Works in progress
echo "═══════════════════════════════════════"
echo "Works in Progress:"
echo ""

running_works=$(echo "$schedule" | jq -r '.works | to_entries | map(select(.value.status == "running")) | .[].key')

if [ -z "$running_works" ]; then
  echo "  (none)"
else
  for work in $running_works; do
    worktree=$(echo "$schedule" | jq -r ".works[\"$work\"].worktree_path // \"N/A\"")
    echo "  - $work"
    echo "    Worktree: $worktree"
  done
fi

echo ""

# Recently completed
echo "═══════════════════════════════════════"
echo "Recently Completed:"
echo ""

completed_works=$(echo "$schedule" | jq -r '.works | to_entries | map(select(.value.status == "completed")) | sort_by(.value.completed_at) | reverse | .[:5] | .[].key')

if [ -z "$completed_works" ]; then
  echo "  (none)"
else
  for work in $completed_works; do
    echo "  ✅ $work"
  done
fi

echo ""

# Failed works
if [ "$failed" -gt 0 ]; then
  echo "═══════════════════════════════════════"
  echo "Failed Works:"
  echo ""

  failed_works=$(echo "$schedule" | jq -r '.works | to_entries | map(select(.value.status == "failed")) | .[].key')

  for work in $failed_works; do
    error=$(echo "$schedule" | jq -r ".works[\"$work\"].error // \"Unknown error\"")
    echo "  ❌ $work"
    echo "     Error: $error"
  done

  echo ""
fi

echo "═══════════════════════════════════════"
echo ""
echo "Commands:"
echo "  /wf0-batch stop     - Stop execution"
echo "  /wf0-batch resume   - Resume paused/failed"
echo "  /wf0-schedule show  - View full schedule"
```

#### 3.4 resume

Resume execution from paused or failed state.

```bash
if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "ERROR: No schedule found"
  exit 1
fi

echo "▶️  Resuming Batch Execution"
echo "═══════════════════════════════════════"
echo ""

schedule=$(cat "$SCHEDULE_FILE")
status=$(echo "$schedule" | jq -r '.status')

case "$status" in
  running)
    echo "Batch is already running"
    echo "Use '/wf0-batch status' to check progress"
    exit 0
    ;;
  completed)
    echo "Batch has completed"
    echo "Use '/wf0-schedule create' to create a new schedule"
    exit 0
    ;;
  pending|paused|failed)
    # Can resume
    ;;
  *)
    echo "Unknown status: $status"
    exit 1
    ;;
esac

# Reset failed works to pending (for retry)
failed_count=$(echo "$schedule" | jq '[.works[] | select(.status == "failed")] | length')

if [ "$failed_count" -gt 0 ]; then
  echo "Resetting $failed_count failed works to pending..."

  # Update failed works to pending
  jq '.works |= with_entries(
    if .value.status == "failed" then
      .value.status = "pending" | .value.error = null
    else . end
  )' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
fi

# Reset in_progress works to pending (they were interrupted)
in_progress_count=$(echo "$schedule" | jq '[.works[] | select(.status == "running")] | length')

if [ "$in_progress_count" -gt 0 ]; then
  echo "Resetting $in_progress_count interrupted works to pending..."

  jq '.works |= with_entries(
    if .value.status == "running" then
      .value.status = "pending"
    else . end
  )' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
fi

# Recalculate progress
jq '
  .progress.completed = ([.works[] | select(.status == "completed")] | length) |
  .progress.in_progress = 0 |
  .progress.pending = ([.works[] | select(.status == "pending")] | length)
' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

echo ""

# Use default parallel count from config
parallel_count=$(jq -r '.batch.default_parallel // 2' "$CONFIG_FILE")

# Delegate to start logic
echo "Restarting with $parallel_count workers..."
echo ""

# The actual start is handled like the start subcommand
# Set status to running and start workers
jq '.status = "running"' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
  mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

# Start scheduler if not running
if ! tmux has-session -t "wf-batch-scheduler" 2>/dev/null; then
  tmux new-session -d -s "wf-batch-scheduler" \
    "$HOME/.claude/scripts/batch/batch-daemon.sh" 2>/dev/null
  echo "✅ Scheduler daemon started"
fi

# Start workers
for i in $(seq 1 $parallel_count); do
  worker_session="wf-batch-worker-$i"

  if ! tmux has-session -t "$worker_session" 2>/dev/null; then
    tmux new-session -d -s "$worker_session" \
      "$HOME/.claude/scripts/batch/batch-worker.sh $i" 2>/dev/null
    echo "✅ Worker $i started"
  else
    echo "Worker $i already running"
  fi
done

echo ""
echo "═══════════════════════════════════════"
echo ""
echo "Batch execution resumed!"
echo "Use '/wf0-batch status' to monitor progress"
```

## Worktree Management

Each work is executed in an isolated git worktree:

```
.worktrees/
├── feat-123-auth/       # FEAT-123-auth work
│   ├── .git             # Worktree git link
│   ├── src/             # Project files
│   └── .wf/             # Symlink to main .wf
├── feat-124-export/     # FEAT-124-export work
└── fix-456-login/       # FIX-456-login work
```

### Worktree Creation

Workers create worktrees as needed:

```bash
# Create worktree for a work
wf_batch_create_worktree() {
  local work_id="$1"
  local branch="$2"
  local worktree_root="${3:-.worktrees}"

  local worktree_path="$worktree_root/$(echo "$work_id" | tr '[:upper:]' '[:lower:]')"

  # Check if worktree already exists
  if [ -d "$worktree_path" ]; then
    echo "$worktree_path"
    return 0
  fi

  # Create branch if needed
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    git branch "$branch" 2>/dev/null || true
  fi

  # Create worktree
  git worktree add "$worktree_path" "$branch" 2>/dev/null

  # Symlink .wf directory
  ln -sf "$(pwd)/.wf" "$worktree_path/.wf"

  echo "$worktree_path"
}
```

### Worktree Cleanup

After work completion:

```bash
wf_batch_cleanup_worktree() {
  local work_id="$1"
  local worktree_root="${2:-.worktrees}"

  local worktree_path="$worktree_root/$(echo "$work_id" | tr '[:upper:]' '[:lower:]')"

  if [ -d "$worktree_path" ]; then
    git worktree remove "$worktree_path" --force 2>/dev/null || rm -rf "$worktree_path"
  fi
}
```

## Session Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ wf-batch-scheduler (tmux session)                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ batch-daemon.sh                                      │   │
│  │  - Monitors schedule.json                            │   │
│  │  - Assigns work to idle workers                      │   │
│  │  - Handles dependency resolution                     │   │
│  │  - Updates progress                                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         │
         │ (IPC via schedule.json)
         ▼
┌─────────────────────────────────────────────────────────────┐
│ wf-batch-worker-1 (tmux session)                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ batch-worker.sh 1                                    │   │
│  │  - Polls for assigned work                           │   │
│  │  - Creates/enters worktree                           │   │
│  │  - Executes wf1-kickoff through wf6-verify           │   │
│  │  - Reports completion/failure                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ wf-batch-worker-2 (tmux session)                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ batch-worker.sh 2                                    │   │
│  │  (same as worker-1)                                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Output Examples

### Start Output

```
🚀 Starting Batch Execution
═══════════════════════════════════════

Workers:       3
Pending works: 5

Execution Plan:
───────────────────────────────────────

Priority 1 (1 works):
  - FEAT-100-database

Priority 2 (2 works):
  - FEAT-123-auth <- FEAT-100-database
  - FEAT-125-api <- FEAT-100-database

Priority 3 (2 works):
  - FEAT-124-export <- FEAT-123-auth
  - FEAT-126-ui <- FEAT-125-api

═══════════════════════════════════════

Starting workers...

✅ Scheduler daemon started
✅ Worker 1 started
✅ Worker 2 started
✅ Worker 3 started

═══════════════════════════════════════

Batch execution started!

Monitor progress:
  /wf0-batch status

View logs:
  tmux attach -t wf-batch-scheduler
  tmux attach -t wf-batch-worker-1

Stop execution:
  /wf0-batch stop
```

### Status Output

```
📊 Batch Execution Status
═══════════════════════════════════════

Schedule Status: running
Created:         2026-01-26T10:00:00Z

Progress:
  ✅ Completed:   2
  🔄 In Progress: 2
  ⏳ Pending:     1
  ─────────────
  📊 Total:       5

═══════════════════════════════════════
Workers:

  📋 Scheduler: ✅ running

  🔧 Worker 1: FEAT-123-auth (running)
  🔧 Worker 2: FEAT-125-api (running)
  🔧 Worker 3: idle

═══════════════════════════════════════
Works in Progress:

  - FEAT-123-auth
    Worktree: .worktrees/feat-123-auth
  - FEAT-125-api
    Worktree: .worktrees/feat-125-api

═══════════════════════════════════════
Recently Completed:

  ✅ FEAT-100-database

═══════════════════════════════════════

Commands:
  /wf0-batch stop     - Stop execution
  /wf0-batch resume   - Resume paused/failed
  /wf0-schedule show  - View full schedule
```

## Notes

- Requires `tmux` for session management
- Requires `git worktree` support
- Schedule must be created first with `/wf0-schedule create`
- Workers execute Claude Code CLI with workflow commands
- Failed works can be retried with `/wf0-batch resume`
- See `config.json` for parallel worker configuration
  - `batch.default_parallel`: Default number of parallel workers (default: 2)
  - `batch.max_parallel`: Maximum allowed parallel workers (default: 5)
  - `batch.auto_worktree`: Automatically create worktrees for works (default: true)
  - `batch.cleanup_worktree`: Clean up worktrees after completion (default: true)
- Daemon and worker scripts are located in `scripts/batch/`:
  - `batch-daemon.sh`: Scheduler daemon for work assignment
  - `batch-worker.sh`: Worker process for executing workflows
  - `batch-utils.sh`: Shared utility functions
