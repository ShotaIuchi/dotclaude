---
name: wf0-nexttask
description: Execute next task from schedule
---

**Always respond in Japanese.**

# /wf0-nexttask

Command to select and execute the next task from schedule.
Retrieves a dependency-resolved task from schedule.json and executes workflow phases.

## Usage

```
/wf0-nexttask [options]
```

## Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Display task info only, do not execute |
| `--until <phase>` | Auto-execute until specified phase (skip selection) |
| `--all` | Auto-execute until all tasks complete (skip selection) |

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Options

```bash
dry_run=false
until_phase=""
execute_all=false

for arg in $ARGUMENTS; do
  case "$arg" in
    --dry-run)
      dry_run=true
      ;;
    --until)
      shift_next="until"
      ;;
    --all)
      execute_all=true
      ;;
    *)
      if [ "$shift_next" = "until" ]; then
        until_phase="$arg"
        shift_next=""
      fi
      ;;
  esac
done
```

### 2. Load Schedule

```bash
SCHEDULE_FILE=".wf/schedule.json"

if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "ERROR: No schedule found"
  echo "Use '/wf0-schedule create' to create a schedule first"
  exit 1
fi

schedule=$(cat "$SCHEDULE_FILE")
schedule_status=$(echo "$schedule" | jq -r '.status')

if [ "$schedule_status" = "completed" ]; then
  echo "All tasks in schedule have been completed"
  exit 0
fi
```

### 3. Get Next Task

Find a pending work with all dependencies resolved:

```bash
# Get next available work (pending with resolved dependencies)
next_work=""

pending_works=$(echo "$schedule" | jq -r '
  .works | to_entries
  | map(select(.value.status == "pending"))
  | sort_by(.value.priority)
  | .[].key
')

for work_id in $pending_works; do
  deps_resolved=true

  # Get dependencies
  deps=$(echo "$schedule" | jq -r ".works[\"$work_id\"].dependencies[]?" 2>/dev/null)

  for dep in $deps; do
    dep_status=$(echo "$schedule" | jq -r ".works[\"$dep\"].status // \"pending\"")
    if [ "$dep_status" != "completed" ]; then
      deps_resolved=false
      break
    fi
  done

  if [ "$deps_resolved" = true ]; then
    next_work="$work_id"
    break
  fi
done

if [ -z "$next_work" ]; then
  # Check if there are blocked works
  blocked_count=$(echo "$schedule" | jq '[.works[] | select(.status == "pending")] | length')

  if [ "$blocked_count" -gt 0 ]; then
    echo "No tasks ready to execute (all pending tasks have unresolved dependencies)"
    echo ""
    echo "Pending tasks with dependencies:"
    echo "$schedule" | jq -r '.works | to_entries | map(select(.value.status == "pending")) | .[] |
      "  - \(.key) (blocked by: \(.value.dependencies | join(", ")))"'
  else
    echo "All tasks completed or no pending tasks"
  fi
  exit 0
fi
```

### 4. Display Task Information

```bash
work_info=$(echo "$schedule" | jq ".works[\"$next_work\"]")
source_type=$(echo "$work_info" | jq -r '.source.type')
source_id=$(echo "$work_info" | jq -r '.source.id')
source_title=$(echo "$work_info" | jq -r '.source.title // "N/A"')
deps=$(echo "$work_info" | jq -r '.dependencies | if length > 0 then join(", ") else "(none)" end')

echo ""
echo "Next Task: $next_work"
echo ""
echo "Source:       $source_type #$source_id"
echo "Title:        $source_title"
echo "Dependencies: $deps"
echo ""
```

### 5. Handle Dry Run

```bash
if [ "$dry_run" = true ]; then
  # Show remaining tasks info
  total=$(echo "$schedule" | jq '.progress.total')
  completed=$(echo "$schedule" | jq '.progress.completed')
  pending=$(echo "$schedule" | jq '.progress.pending')

  echo "Schedule Progress:"
  echo "  Completed: $completed/$total"
  echo "  Pending:   $pending"
  echo ""
  echo "(Dry run mode - no execution)"
  exit 0
fi
```

### 6. Execution Range Selection

If `--until` or `--all` is not specified, prompt user for execution range:

```bash
if [ -z "$until_phase" ] && [ "$execute_all" = false ]; then
  echo "Where would you like to stop?"
  echo ""
  echo "  1. wf1-kickoff only (Start work)"
  echo "  2. Until wf3-plan (Design complete)"
  echo "  3. Until wf4-review (Review complete)"
  echo "  4. Until wf6-verify (Task complete)"
  echo "  5. Complete all remaining tasks"
  echo ""

  # Use AskUserQuestion to get user selection
  # Prompt: "Select execution range [1-5]:"
fi
```

**Implementation:** Use the AskUserQuestion tool to present options to the user:

```
AskUserQuestion(
  questions: [{
    question: "Where would you like to stop?",
    header: "Execute",
    options: [
      { label: "wf1-kickoff only", description: "Start work, then pause for review" },
      { label: "Until wf3-plan", description: "Complete design phase" },
      { label: "Until wf4-review", description: "Complete review phase" },
      { label: "Until wf6-verify (Recommended)", description: "Complete entire task" },
      { label: "Complete all tasks", description: "Execute all remaining tasks in schedule" }
    ],
    multiSelect: false
  }]
)
```

Map selection to phase:

| Selection | Target Phase |
|-----------|--------------|
| 1 | wf1-kickoff |
| 2 | wf3-plan |
| 3 | wf4-review |
| 4 | wf6-verify |
| 5 | (execute all tasks) |

### 7. Update Schedule Status

Mark the work as started:

```bash
# Update work status to running
jq --arg w "$next_work" '
  .works[$w].status = "running" |
  .works[$w].started_at = (now | todate) |
  .progress.pending = ([.works[] | select(.status == "pending")] | length) |
  .progress.in_progress = ([.works[] | select(.status == "running")] | length)
' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
```

### 8. Execute Workflow

Execute workflow phases based on selection:

```bash
# Determine target phase
case "$selection" in
  1) target_phase="wf1-kickoff" ;;
  2) target_phase="wf3-plan" ;;
  3) target_phase="wf4-review" ;;
  4) target_phase="wf6-verify" ;;
  5) execute_all=true ;;
esac

# If --until was specified
if [ -n "$until_phase" ]; then
  target_phase="$until_phase"
fi

echo ""
echo "Starting $next_work..."
echo ""

# Execute /wf1-kickoff first
echo "Executing /wf1-kickoff $next_work..."
# Use Skill tool: Skill(skill: "wf1-kickoff", args: "$next_work")
```

For execution beyond wf1-kickoff, repeatedly call `/wf0-nextstep`:

```bash
if [ "$target_phase" != "wf1-kickoff" ]; then
  # Loop until target phase is reached or work is complete
  while true; do
    # Check current phase
    current_phase=$(jq -r ".works[\"$next_work\"].current // empty" .wf/state.json)
    next_phase=$(jq -r ".works[\"$next_work\"].next // empty" .wf/state.json)

    # Check if target reached
    if [ "$current_phase" = "$target_phase" ]; then
      echo ""
      echo "Reached target phase: $target_phase"
      break
    fi

    # Check if complete
    if [ "$next_phase" = "complete" ] || [ -z "$next_phase" ]; then
      break
    fi

    # Execute next step
    echo "Executing /wf0-nextstep $next_work..."
    # Use Skill tool: Skill(skill: "wf0-nextstep", args: "$next_work")
  done
fi
```

### 9. Mark Work Complete

When work reaches wf6-verify and PR is created:

```bash
# Check if work is complete (PR created)
pr_url=$(jq -r ".works[\"$next_work\"].pr.url // empty" .wf/state.json)

if [ -n "$pr_url" ]; then
  # Update schedule - mark as completed
  jq --arg w "$next_work" '
    .works[$w].status = "completed" |
    .works[$w].completed_at = (now | todate) |
    .progress.completed = ([.works[] | select(.status == "completed")] | length) |
    .progress.in_progress = ([.works[] | select(.status == "running")] | length)
  ' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
fi
```

### 10. Show Remaining Tasks

After completing a task:

```bash
# Reload schedule
schedule=$(cat "$SCHEDULE_FILE")
remaining=$(echo "$schedule" | jq '[.works[] | select(.status == "pending" or .status == "running")] | length')

if [ "$remaining" -eq 0 ]; then
  # All tasks complete
  jq '.status = "completed"' "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
    mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"

  echo ""
  echo "All tasks completed!"
  echo ""
else
  echo ""
  echo "Task $next_work completed!"
  echo ""
  echo "Remaining tasks: $remaining"

  echo ""
  echo "Run '/wf0-nexttask' for the next task"
fi
```

### 11. Execute All Tasks (--all or selection 5)

If `--all` is specified or user selects option 5:

```bash
if [ "$execute_all" = true ]; then
  task_count=0
  max_tasks=50  # Safety limit

  while [ $task_count -lt $max_tasks ]; do
    # Reload schedule
    schedule=$(cat "$SCHEDULE_FILE")
    remaining=$(echo "$schedule" | jq '[.works[] | select(.status == "pending")] | length')

    if [ "$remaining" -eq 0 ]; then
      echo ""
      echo "All tasks completed!"
      break
    fi

    # Get next task (same logic as step 3)
    # ... (find next available work)

    if [ -z "$next_work" ]; then
      echo "No more tasks can be executed (remaining tasks are blocked)"
      break
    fi

    echo ""
    echo "Starting task $((task_count + 1)): $next_work"
    echo ""

    # Execute full workflow for this task
    # /wf1-kickoff -> /wf0-nextstep (repeat until complete)

    task_count=$((task_count + 1))
  done

  if [ $task_count -ge $max_tasks ]; then
    echo "WARNING: Reached maximum task limit ($max_tasks)"
    echo "Run '/wf0-nexttask --all' to continue"
  fi
fi
```

## Output Examples

### Task Display

```

Next Task: FEAT-123-auth

Source:       github #123
Title:        Add user authentication
Dependencies: FEAT-100-database (completed)

Where would you like to stop?

  1. wf1-kickoff only (Start work)
  2. Until wf3-plan (Design complete)
  3. Until wf4-review (Review complete)
  4. Until wf6-verify (Task complete)
  5. Complete all remaining tasks

Select [1-5]:
```

### Completion Notification

```

Task FEAT-123-auth completed!

Remaining tasks: 2
  Ready:
    - FEAT-124-export
  Blocked:
    - FEAT-125-api (blocked by: FEAT-124-export)

Run '/wf0-nexttask' for the next task
```

### Dry Run Output

```

Next Task: FEAT-123-auth

Source:       github #123
Title:        Add user authentication
Dependencies: FEAT-100-database (completed)

Schedule Progress:
  Completed: 1/5
  Pending:   4

(Dry run mode - no execution)
```

### All Tasks Blocked

```
No tasks ready to execute (all pending tasks have unresolved dependencies)

Pending tasks with dependencies:
  - FEAT-124-export (blocked by: FEAT-123-auth)
  - FEAT-125-api (blocked by: FEAT-123-auth, FEAT-124-export)
```

## Relationship with wf0-nextstep

| Command | Role | Scope |
|---------|------|-------|
| `wf0-nextstep` | Phase transition | Within a single work (wf1->wf2->...->wf6) |
| `wf0-nexttask` | Task selection and execution | Multiple works in schedule.json |

## Internal Flow

```
wf0-nexttask
  |-- Get next task from schedule.json
  |-- Propose execution range and get selection
  +-- Execute based on selection
       |-- wf1-kickoff only -> /wf1-kickoff and exit
       +-- Until wfN -> /wf1-kickoff -> /wf0-nextstep (repeat)
```

## Notes

- Schedule must be created first with `/wf0-schedule create`
- Tasks are executed in priority order respecting dependencies
- Use `--dry-run` to preview without execution
- Use `--until <phase>` to skip the selection prompt
- Use `--all` to execute all remaining tasks automatically
- Maximum 50 tasks per `--all` execution (safety limit)
