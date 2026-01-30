---
name: wf5-implement
description: Planの1ステップを実装
argument-hint: "[step_number]"
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /wf5-implement

Implement one step of the Plan document.

## Usage

```
/wf5-implement [step_number]
```

## Arguments

- `step_number`: Step to implement (optional). Auto-selects next incomplete step if omitted.

## Constraints

- **No Off-Plan Changes**: Only implement what is documented in the Plan.
- **One Execution = One Step**: Only one step per execution.

## Processing

### 1. Check Prerequisites

Get active work. Require `03_PLAN.md` exists.

### 2. Determine Target Step

If no argument: `current_step + 1` from state.json. Check dependent steps are completed.

### 3. Extract Step Info from Plan

Title, Purpose, Target Files, Tasks, Completion Criteria, Dependencies.

### 4. Implementation

1. Load and analyze target files
2. Make code changes following Plan tasks — **no off-plan changes**
3. Run related tests; fix failures if directly related to this step's changes

### 5. Record Implementation Log

Append to `05_IMPLEMENT_LOG.md` using template `~/.claude/templates/05_IMPLEMENT_LOG.md`.

### 6. Update state.json

Set step status to `"completed"` with timestamp. Update `current_step`. Set `current: "wf5-implement"`. If all steps done, set `next: "wf6-verify"`.

### 7. Verify Completion Criteria

Check each criterion is satisfied.

### 8. Commit

Auto-detect commit type from step content:
- `bug`/`fix`/`repair` → `fix`
- `refactor` → `refactor`
- `test` → `test`
- `doc`/`documentation` → `docs`
- otherwise → `feat`

Override with `commit.type_detection`/`commit.default_type` from config.json.

Message: `<type>(<scope>): <description>` with step info and work-id in body.

### 9. Completion Message

Show changed files with diff stats, completion criteria results, progress (n/total), next step suggestion.

## Off-Plan Changes

- **Minor** (typos, imports): Record in Notes section, continue
- **Significant** (design changes): Interrupt, suggest `/wf3-plan update`

