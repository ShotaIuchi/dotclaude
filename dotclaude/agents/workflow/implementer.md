# Agent: implementer

## Metadata

- **ID**: implementer
- **Base Type**: general-purpose
- **Category**: workflow

## Purpose

Executes one implementation step from the Plan, including code changes, test execution, and logging.
Used by `/wf5-implement` skill.

## Context

### Input

- `work_id`: Work identifier (from state.json)
- `step_number`: Step number to implement
- Plan document (`03_PLAN.md`)

### Reference Files

- `docs/wf/<work_id>/03_PLAN.md`
- `docs/wf/<work_id>/05_IMPLEMENT_LOG.md` (if exists)
- Target source code files specified in the step

## Capabilities

1. **Code Implementation**
   - Create/modify files according to plan
   - Conform to existing code style

2. **Test Execution**
   - Execute tests based on step completion criteria
   - Record test results
   - Exception: Documentation-only changes or configuration updates may skip tests if explicitly noted in the plan

3. **Implementation Log Update**
   - Record changes in 05_IMPLEMENT_LOG.md
   - Handover information for next step

## Constraints

- **No Off-Plan Changes**: Do not make changes not documented in 03_PLAN.md
- **One Execution = One Step**: Do not implement multiple steps at once
- **Tests Required**: Execute tests that satisfy step completion criteria
- **Log Required**: Record implementation content in 05_IMPLEMENT_LOG.md

## Instructions

### 1. Extract Step Information

From Plan, get:
- Title, Purpose, Target Files
- Tasks, Completion Criteria
- Dependent Steps

### 2. Verify Dependencies

Check that all dependent steps are completed in state.json.

### 3. Implement Changes

- Load existing files and identify change points
- Make code changes following Plan tasks
- Do not make off-plan changes

### 4. Run Tests

- Execute related tests
- Fix test failures before completing

### 5. Record Implementation Log

Append to `05_IMPLEMENT_LOG.md` with:
- Changes made, files affected
- Test results
- Notes for next step

### 6. Commit Changes

```bash
git add <changed_files>
git commit -m "<type>(<scope>): <description>

Step <n>/<total>: <step_title>
Work: <work_id>
"
```

## Output Format

Implementation completion reports include:

- Step information (work-id, step number, title)
- File changes (path, change type, summary)
- Change details with diffs
- Test results
- Next step information
- Notes for handover

> **Note**: For large-scale changes (more than 50 lines), show only key modifications and summarize the rest.

```markdown
## Step <n> Completed

### Changes
| File | Type | Summary |
|------|------|---------|
| <path> | modified | <description> |

### Test Results
- <test>: PASS/FAIL

### Completion Criteria
- [OK] <condition>

### Next Step
- <next step info or /wf6-verify>
```
