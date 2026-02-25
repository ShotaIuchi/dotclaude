---
name: ghwf5-implement
description: Planの全ステップを一括実装
argument-hint: ""
context: fork
agent: general-purpose
---

**Always respond in Japanese. Write all workflow documents (*.md) in Japanese.**

# /ghwf5-implement

Implement all steps of the plan in a single execution. Each step is committed individually; push is done once at the end.

## Usage

```
/ghwf5-implement          # 全ステップを一括実装
```

## Prerequisites

- `ghwf4-review` completed (Plan review)
- `03_PLAN.md` exists

## Processing

### 1. Load Context

- Read `state.json` for active work
- Read `03_PLAN.md` and extract all steps
- Fetch Issue/PR with comments:
  ```bash
  gh issue view <issue> --json body,comments
  gh pr view <pr> --json comments,reviews
  ```
- Determine starting step (first incomplete step from state)

### 2. Implement All Steps (Loop)

For each remaining step (from current to last):

#### 2a. Implement Step N

- Write code according to plan for step N
- Follow existing code patterns
- Add tests if applicable

#### 2b. Commit Step N

**Commit immediately without confirmation (do NOT push yet):**

```bash
git add .
git commit -m "<type>(<scope>): <description>

Implements step N of <work-id>"
```

Auto-detect commit type from step content:
- `bug`/`fix`/`repair` → `fix`
- `refactor` → `refactor`
- `test` → `test`
- `doc`/`documentation` → `docs`
- otherwise → `feat`

#### 2c. Update Progress

- Update `implement.current_step` in state.json
- Continue to next step

### 3. Update 05_IMPLEMENTATION.md

After all steps are complete:
- Record all completed steps with summary
- Note any deviations from plan

### 4. Push

**Push once after all steps are committed:**

```bash
git push
```

### 5. Update PR & Labels

- Update PR checklist
- Add `ghwf:step-5` label

### 6. Update State

```json
{
  "current": "ghwf5-implement",
  "next": "ghwf6-verify",
  "last_execution": "<ISO8601>",
  "implement": {
    "current_step": M,
    "total_steps": M
  }
}
```

## Error Handling

- If a step fails to implement, commit all successfully completed steps, push, and stop
- Record the failure in 05_IMPLEMENTATION.md with the failing step number
- Set `next: "ghwf5-implement"` so the remaining steps can be retried
