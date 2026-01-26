---
name: wf0-batch
description: Batch execution control for scheduled workflows
references:
  - path: ../../commands/wf0-batch.md
  - path: ../../commands/wf0-schedule.md
  - path: ../../scripts/batch/batch-daemon.sh
  - path: ../../scripts/batch/batch-worker.sh
---

# /wf0-batch

Batch execution control command for scheduled workflows.
Uses worktrees for parallel execution with dependency resolution.

## Core Functions

1. **Parallel Execution** - Run multiple workflows simultaneously
2. **Worktree Isolation** - Each work runs in isolated git worktree
3. **Dependency Resolution** - Execute works in correct order
4. **Progress Tracking** - Monitor completion status

## Subcommands

| Subcommand | Purpose |
|------------|---------|
| `start [--parallel N]` | Start batch execution |
| `stop [--all \| work-id...]` | Stop execution |
| `status` | Show execution status |
| `resume` | Resume from paused/failed state |

## Options

| Option | Description |
|--------|-------------|
| `--parallel N` | Number of parallel workers |
| `--dry-run` | Show execution plan without running |
| `--all` | Target all workers (for stop) |

## Architecture

```
┌─────────────────────────────────────┐
│ wf-batch-scheduler (tmux)           │
│   batch-daemon.sh                   │
│   - Assigns work to workers         │
│   - Handles dependency resolution   │
└─────────────────────────────────────┘
              │
     ┌────────┼────────┐
     ▼        ▼        ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│worker-1 │ │worker-2 │ │worker-3 │
│(tmux)   │ │(tmux)   │ │(tmux)   │
└─────────┘ └─────────┘ └─────────┘
```

## Worktree Structure

```
.worktrees/
├── feat-123-auth/       # Work in progress
│   ├── .git             # Worktree git link
│   ├── src/             # Project files
│   └── .wf -> ../.wf    # Shared state
├── feat-124-export/
└── fix-456-login/
```

## Execution Flow

1. **Schedule Creation**: `/wf0-schedule create`
2. **Start Execution**: `/wf0-batch start --parallel 3`
3. **Daemon Starts**: Scheduler assigns works to idle workers
4. **Worker Execution**:
   - Create worktree
   - Execute wf1-kickoff through wf6-verify
   - Push changes
   - Report completion
5. **Dependency Resolution**: Daemon assigns next available work
6. **Completion**: All works done or paused

## Configuration

In `config.json`:

```json
{
  "batch": {
    "default_parallel": 2,
    "max_parallel": 5,
    "auto_worktree": true
  },
  "worktree": {
    "enabled": true,
    "root_dir": ".worktrees"
  }
}
```

## Usage Examples

### Basic Execution

```bash
# Create schedule
/wf0-schedule create github="label:scheduled"

# Start with 2 workers
/wf0-batch start --parallel 2

# Monitor
/wf0-batch status

# Stop if needed
/wf0-batch stop
```

### Resume After Failure

```bash
# Check status
/wf0-batch status

# Resume (resets failed works to pending)
/wf0-batch resume
```

### Dry Run

```bash
# Preview execution plan
/wf0-batch start --dry-run
```

## Monitoring

### View Logs

```bash
# Scheduler logs
tmux attach -t wf-batch-scheduler

# Worker logs
tmux attach -t wf-batch-worker-1
```

### Status Display

```
📊 Batch Execution Status
═══════════════════════════════════════

Progress:
  ✅ Completed:   2
  🔄 In Progress: 2
  ⏳ Pending:     1

Workers:
  📋 Scheduler: ✅ running
  🔧 Worker 1: FEAT-123-auth (running)
  🔧 Worker 2: FEAT-125-api (running)
```

## Detailed Reference

- [wf0-batch Command](../../commands/wf0-batch.md)
- [wf0-schedule Command](../../commands/wf0-schedule.md)
