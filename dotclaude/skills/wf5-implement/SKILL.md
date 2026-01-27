---
name: wf5-implement
description: Implement one step of the Plan
context: fork
agent: general-purpose
---

# /wf5-implement

Command to implement one step of the Plan.

## Usage

```
/wf5-implement [step_number]
```

## Arguments

- `step_number`: Step number to implement (optional)
  - If omitted: Auto-select next incomplete step

## Important Constraints

**No Off-Plan Changes**: This command implements only the steps documented in the Plan.
**One Execution = One Step**: Only one step is implemented per execution.

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Check Prerequisites

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
plan_path="$docs_dir/02_PLAN.md"
log_path="$docs_dir/04_IMPLEMENT_LOG.md"

# Check if Plan exists
if [ ! -f "$plan_path" ]; then
  echo "Plan document not found"
  echo "Please run /wf3-plan first"
  exit 1
fi
```

### 2. Determine Implementation Target Step

```bash
step_number="$ARGUMENTS"

if [ -z "$step_number" ]; then
  # Get next step from state.json
  current_step=$(jq -r ".works[\"$work_id\"].plan.current_step // 0" .wf/state.json)
  step_number=$((current_step + 1))
fi
```

### 3. Extract Step Information from Plan

Get the following from the corresponding step in Plan:
- **Title**
- **Purpose**
- **Target Files**
- **Tasks**
- **Completion Criteria**
- **Dependent Steps**

### 4. Check Dependent Steps

```bash
# Check if dependent steps are completed
for dep in $dependencies; do
  dep_status=$(jq -r ".works[\"$work_id\"].plan.steps[\"$dep\"].status // \"pending\"" .wf/state.json)
  if [ "$dep_status" != "completed" ]; then
    echo "ERROR: Dependent step $dep is not completed"
    exit 1
  fi
done
```

### 5. Start Implementation

```
Step <n>: <title>
===

Purpose: <goal>

Target Files:
- <file1>
- <file2>

Tasks:
1. <task1>
2. <task2>

Completion Criteria:
- [ ] <condition1>
- [ ] <condition2>

---
Starting implementation...
```

### 6. Implementation Work

Implement according to the tasks documented in Plan:

1. **Check Target Files**
   - Load existing files
   - Identify change points

2. **Make Code Changes**
   - Follow Plan tasks
   - **Do not make off-plan changes**

3. **Run Tests**
   - Run related tests
   - Fix if tests fail
   - **Note on test fixes:** Fixing test failures within the current step is permitted and does not count as "off-plan changes" if:
     - The fix is directly related to the changes made in this step
     - The fix is necessary to satisfy the step's completion criteria
     - The fix does not introduce new features or significant refactoring

### 7. Record Implementation Log

Append to `04_IMPLEMENT_LOG.md`:

**Template reference:** Load and use `~/.claude/templates/04_IMPLEMENT_LOG.md`.

Record implementation content following the step section structure of the template.

### 8. Update state.json

```bash
timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")

# Update step status
jq ".works[\"$work_id\"].plan.steps[\"$step_number\"] = {\"status\": \"completed\", \"completed_at\": \"$timestamp\"}" .wf/state.json > tmp && mv tmp .wf/state.json

# Update current_step
jq ".works[\"$work_id\"].plan.current_step = $step_number" .wf/state.json > tmp && mv tmp .wf/state.json

# Update current/next
jq ".works[\"$work_id\"].current = \"wf5-implement\"" .wf/state.json > tmp && mv tmp .wf/state.json

# Check if all steps are completed
total_steps=$(jq -r ".works[\"$work_id\"].plan.total_steps" .wf/state.json)
if [ "$step_number" -eq "$total_steps" ]; then
  jq ".works[\"$work_id\"].next = \"wf6-verify\"" .wf/state.json > tmp && mv tmp .wf/state.json
fi
```

### 9. Verify Completion Criteria

Verify each completion criterion is satisfied:

```
Completion Criteria Check:
- [OK] <condition1>
- [OK] <condition2>
```

### 10. Commit

Determine commit type:

```bash
# Check commit settings from config.json
if [ -f ".wf/config.json" ]; then
  type_detection=$(jq -r '.commit.type_detection // "auto"' .wf/config.json)
  default_type=$(jq -r '.commit.default_type // "feat"' .wf/config.json)
else
  type_detection="auto"
  default_type="feat"
fi

# Determine commit type
if [ "$type_detection" = "auto" ]; then
  # Infer from Plan step content
  # If keywords like bug/fix/repair/bug are present -> fix
  # Otherwise -> feat
  commit_type="<auto_detected_type>"
else
  commit_type="$default_type"
fi
```

**Type Auto-Detection Rules (type_detection=auto):**
- Step title or purpose contains `bug`, `fix`, `repair` -> `fix`
- Contains `refactor` -> `refactor`
- Contains `test` -> `test`
- Contains `doc`, `documentation` -> `docs`
- Otherwise -> `feat`

```bash
git add <changed_files>
git commit -m "$commit_type(<scope>): <description>

Step <n>/<total>: <step_title>
Work: <work_id>
"
```

### 11. Completion Message

```
Step <n> completed

Changed Files:
- <file1> (+10, -5)
- <file2> (+3, -0)

Completion Criteria:
- [OK] <condition1>
- [OK] <condition2>

Progress: <n>/<total> steps completed

Next step:
- If remaining steps exist: /wf5-implement
- All steps complete: /wf6-verify
```

## About Off-Plan Changes

When changes not documented in Plan are needed:

1. **Minor Fixes** (typos, adding imports, etc.)
   -> Record in Notes section of implementation log and continue

2. **Significant Changes** (design changes, additional features, etc.)
   -> Interrupt implementation and suggest Plan update
   ```
   Off-plan changes are needed

   Discovered Issue:
   - <issue description>

   Suggestion:
   - Please update the Plan with /wf3-plan update
   ```

## Notes

- **Only one step per execution**
- **Off-plan changes are prohibited in principle**
- Error if dependent steps are incomplete
- Fix test failures before completing
- Commit messages follow Conventional Commits format

---

## Agent Capabilities (Integrated from implementer agent)

This skill runs as a forked sub-agent with the following specialized capabilities:

### Code Implementation

- Create/modify files according to plan
- Conform to existing code style

### Test Execution

- Execute tests based on step completion criteria
- Record test results
- Exception: Documentation-only changes or configuration updates may skip tests if explicitly noted in the plan

### Implementation Log Update

- Record changes in 04_IMPLEMENT_LOG.md
- Handover information for next step

### Implementation Constraints

- **No Off-Plan Changes**: Do not make changes not documented in 02_PLAN.md
- **One Execution = One Step**: Do not implement multiple steps at once
- **Tests Required**: Execute tests that satisfy step completion criteria
- **Log Required**: Record implementation content in 04_IMPLEMENT_LOG.md

### Output Format

Implementation completion reports include:

- Step information (work-id, step number, title)
- File changes (path, change type, summary)
- Change details with diffs
- Test results
- Next step information
- Notes for handover

> **Note**: For large-scale changes (more than 50 lines), show only key modifications and summarize the rest.
