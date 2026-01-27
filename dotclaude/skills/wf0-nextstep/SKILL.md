---
name: wf0-nextstep
description: Execute the next workflow step
---

**Always respond in Japanese.**

# /wf0-nextstep

Command to immediately execute the next workflow command without confirmation.

## Usage

```
/wf0-nextstep [work-id]
```

## Arguments

- `work-id`: Target work ID (optional)
  - If omitted: Use `active_work` from `state.json`

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Load state.json

```bash
if [ ! -f .wf/state.json ]; then
  echo "WF system is not initialized"
  echo "Please create a workspace with /wf1-kickoff"
  exit 1
fi
```

### 2. Resolve work-id

```bash
work_id="$ARGUMENTS"

if [ -z "$work_id" ]; then
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi

if [ -z "$work_id" ]; then
  echo "ERROR: Please specify work-id or run /wf1-kickoff"
  exit 1
fi
```

### 3. Get Work Information

```bash
# Check if work-id exists in works
work=$(jq -r ".works[\"$work_id\"] // empty" .wf/state.json)
if [ -z "$work" ]; then
  echo "ERROR: work-id '$work_id' not found"
  exit 1
fi

# Get next field
next_phase=$(jq -r ".works[\"$work_id\"].next // empty" .wf/state.json)
current_phase=$(jq -r ".works[\"$work_id\"].current // empty" .wf/state.json)
```

### 4. Determine and Execute next

#### 4.1 If next is null, empty, or "complete"

```bash
if [ -z "$next_phase" ] || [ "$next_phase" = "null" ] || [ "$next_phase" = "complete" ]; then
  # Check if PR has been created
  pr_url=$(jq -r ".works[\"$work_id\"].pr.url // empty" .wf/state.json)

  if [ "$next_phase" = "complete" ] && [ -n "$pr_url" ]; then
    # Work is fully complete with PR
    echo "This work is complete"
    echo ""
    echo "PR: $pr_url"
    exit 0
  elif [ -z "$next_phase" ] || [ "$next_phase" = "null" ]; then
    # next is not set (shouldn't happen normally)
    echo "Workflow state is unclear"
    echo "Please check status with /wf0-status"
    exit 1
  else
    # next is "complete" but no PR
    echo "This work implementation is complete"
    echo "Please create a PR with /wf6-verify pr"
    exit 0
  fi
fi
```

#### 4.2 If next is wf5-implement

For wf5-implement, if there are incomplete steps, execute with step argument:

```bash
if [ "$next_phase" = "wf5-implement" ]; then
  current_step=$(jq -r ".works[\"$work_id\"].plan.current_step // 0" .wf/state.json)
  total_steps=$(jq -r ".works[\"$work_id\"].plan.total_steps // 0" .wf/state.json)

  if [ "$current_step" -lt "$total_steps" ]; then
    next_step=$((current_step + 1))
    echo "Executing /wf5-implement $next_step..."
    echo ""
    # Execute /wf5-implement $next_step
  fi
fi
```

#### 4.3 Normal case

```bash
echo "Executing /$next_phase..."
echo ""
# Execute /$next_phase
```

### 5. Execute Next Command

**Important:** Based on the above determination, **execute the corresponding command immediately without confirmation**.

Commands to execute:
- Normal: `/$next_phase`
- wf5-implement + incomplete steps: `/wf5-implement <next_step>`

**Implementation:** Use the Skill tool to invoke the corresponding command:

```
# For normal phases
Skill(skill: "$next_phase")

# For wf5-implement with step number
Skill(skill: "wf5-implement", args: "$next_step")
```

## Output Format

### At Execution Start

```
Executing /<command>...

```

After that, the output of the corresponding command is displayed as-is.

### On Error

```
ERROR: <error message>
```

## Notes

- **Execute immediately without confirmation**: This command executes the next command without asking for user confirmation
- Prompt `/wf1-kickoff` if state.json does not exist
- Display clear error if work-id cannot be resolved
- Display status and exit for completed work
