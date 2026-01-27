---
name: wf3-plan
description: Create the Implementation Plan
argument-hint: "[update | revise | chat]"
context: fork
agent: Plan
---

**Always respond in Japanese.**

# /wf3-plan

Command to create the Implementation Plan (Plan) document.

## Usage

```
/wf3-plan [subcommand]
```

## Subcommands

- `(none)`: Create new
- `update`: Update existing Plan
- `step <n>`: Display details of a specific step

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Check Prerequisites

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
spec_path="$docs_dir/01_SPEC.md"
plan_path="$docs_dir/02_PLAN.md"

# Check if Spec exists
if [ ! -f "$spec_path" ]; then
  echo "Spec document not found"
  echo "Please run /wf2-spec first"
  exit 1
fi
```

### 2. Load and Analyze Spec

```bash
cat "$spec_path"
```

Extract from Spec:
- Affected Components
- Detailed Changes
- Test Strategy

### 3. Detailed Codebase Investigation

Collect information needed for implementation:

1. **Identify Target Files**
   - Files that need modification
   - Files that need to be created
   - Test files

2. **Dependency Analysis**
   - Dependencies between files
   - Determine order of changes

3. **Risk Assessment**
   - Complex change points
   - Potential side effects

### 4. Step Division Principles

Divide steps according to the following principles:

1. **1 Step = 1 /wf5-implement Execution**
   - Scope completable in one implementation
   - Appropriate size for a commit unit
   - **Size guidelines:**
     - Lines changed: ~50-200 lines per step
     - Files modified: 1-5 files per step
     - Complexity: Focusable on a single logical change

2. **Consider Dependency Order**
   - Foundational changes first
   - Tests simultaneously with or immediately after implementation

3. **Risk Distribution**
   - Split complex changes
   - Units that are easy to rollback

### 5. Create Plan

**Template reference:** Load and use `~/.claude/templates/02_PLAN.md`.

Replace template placeholders with investigation results and Spec content.

**Note:** Divide into approximately 5-10 steps, and copy the Step section of 02_PLAN.md as needed.
Similarly, add rows to the Progress table according to the number of steps.

### 6. User Confirmation

After creating Plan, confirm the following:

1. **Step Count Validity**
   - Not too many (guideline: 5-10 steps)
   - Is granularity appropriate

2. **Dependencies**
   - Is the order correct
   - Are there steps that can be executed in parallel

3. **Risk Assessment**
   - Are there overlooked risks

### 7. Update state.json

```bash
jq ".works[\"$work_id\"].current = \"wf3-plan\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].next = \"wf4-review\"" .wf/state.json > tmp && mv tmp .wf/state.json

# Add step information with schema
# Each step in "steps" object follows this structure:
# {
#   "<step_number>": {
#     "status": "pending|in_progress|completed",
#     "started_at": "<timestamp>|null",
#     "completed_at": "<timestamp>|null"
#   }
# }
jq ".works[\"$work_id\"].plan = {\"total_steps\": <n>, \"current_step\": 0, \"steps\": {}}" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 8. Commit

Commit Plan document changes:

```bash
# For new creation
git add "$plan_path" .wf/state.json
git commit -m "docs(wf): create plan <work-id>

Steps: <n>
Work: <work-id>
"

# For update
git add "$plan_path" .wf/state.json
git commit -m "docs(wf): update plan <work-id>

Steps: <n>
Work: <work-id>
"
```

### 9. Completion Message

```
Plan document created

File: docs/wf/<work-id>/02_PLAN.md

Implementation Steps:
1. <step1_title> (small)
2. <step2_title> (medium)
3. <step3_title> (small)

Total: 3 steps

Next step:
- If review is needed: /wf4-review
- To start implementation: /wf5-implement
```

## step Subcommand

Display details of a specific step:

```
/wf3-plan step 1
```

Output:
```
Step 1: <title>
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

Estimate: medium
Dependencies: none
```

## Notes

- Do not include changes in Plan that exceed Spec content
- Strictly consider dependencies for implementation order
- Each step should be a unit that can be tested independently

---

## Agent Capabilities (Integrated from planner agent)

This skill runs as a forked sub-agent (Plan type) with the following specialized capabilities:

### Implementation Step Decomposition

- Break down specification into executable units
- Clarify dependencies between steps (DAG structure recommended)
- Estimate effort per step (~15-60 min target)

### Technical Approach Selection

- Analyze trade-offs when multiple approaches exist
- Consider consistency with existing code patterns
- Evaluation criteria: Complexity, Maintainability, Performance, Risk (score 1-5)

### Risk Analysis

- Identify technical risks
- Present countermeasures

### Rollback Planning

- Define rollback method for each step

### Planning Constraints

- Limited to planning within specification scope
- 1 step = granularity completable in one wf5-implement
  - Guideline: ~50-200 lines of code changes, ~15-60 minutes of work
  - Each step should have a single, well-defined objective
- Each step must be independently testable

### Error Handling

When `01_SPEC.md` is missing or incomplete:

1. **Missing file**: Notify user and suggest running `wf2-spec` first
2. **Incomplete specification**: List missing required sections and request completion
3. **Invalid format**: Identify format issues and provide correction guidance
