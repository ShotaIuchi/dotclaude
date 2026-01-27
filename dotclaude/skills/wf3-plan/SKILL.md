---
name: wf3-plan
description: Create the Implementation Plan
argument-hint: "[update | step <n>]"
context: fork
agent: Plan
---

**Always respond in Japanese.**

# /wf3-plan

Create or update the Implementation Plan document.

## Usage

```
/wf3-plan [subcommand]
```

## Subcommands

- `(none)`: Create new Plan
- `update`: Update existing Plan
- `step <n>`: Display details of a specific step

## Processing

### 1. Check Prerequisites

Get active work. Require `02_SPEC.md` exists.

### 2. Load and Analyze Spec

Extract: Affected Components, Detailed Changes, Test Strategy.

### 3. Codebase Investigation

1. Identify target files (modify, create, test)
2. Analyze dependencies between files, determine change order
3. Assess risks (complex changes, side effects)

### 4. Step Division Principles

- **1 Step = 1 `/wf5-implement` execution** (committable unit)
- Size: ~50-200 lines changed, 1-5 files, single logical change
- Foundational changes first; tests with or immediately after implementation
- Split complex changes for easy rollback

### 5. Create Plan

Load template `~/.claude/templates/03_PLAN.md`. Divide into ~5-10 steps. Fill Progress table rows for each step.

### 6. User Confirmation

Confirm: step count validity, dependency order, parallel execution opportunities, risk assessment.

### 7. Update state.json

Set `current: "wf3-plan"`, `next: "wf4-review"`. Add `plan: { total_steps: <n>, current_step: 0, steps: {} }`.

### 8. Commit

`docs(wf): create plan <work-id>` (or `update plan`). Include step count and work-id.

### 9. Completion Message

Show file path, step list with sizes, total count, next step (`/wf4-review` or `/wf5-implement`).

## step Subcommand

Display specific step details: Title, Purpose, Target Files, Tasks, Completion Criteria, Estimate, Dependencies.

## Notes

- Do not exceed Spec scope
- Strictly respect dependency order
- Each step should be independently testable

## Agent Reference

This skill delegates to the [planner agent](../../agents/workflow/planner.md).
