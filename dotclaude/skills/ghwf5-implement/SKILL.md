---
name: ghwf5-implement
description: Plan の1ステップを実装
argument-hint: "[step-number]"
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /ghwf5-implement

実装計画の1ステップを実装する。

## Usage

```
/ghwf5-implement          # 次のステップを実装
/ghwf5-implement <N>      # ステップ N を実装
```

## Prerequisites

- `ghwf4-review` 完了済み (Plan レビュー)
- `03_PLAN.md` が存在

## Processing

### 1. Load Context

- Read `state.json` for active work
- Read `03_PLAN.md`
- Fetch Issue/PR with comments:
  ```bash
  gh issue view <issue> --json body,comments
  gh pr view <pr> --json comments,reviews
  ```
- Identify next step to implement

### 2. Implement

- Write code according to plan
- Follow existing code patterns
- Add tests if applicable

### 3. Update 05_IMPLEMENTATION.md

- Track completed steps
- Note any deviations from plan

### 4. Commit & Push

**Execute immediately without confirmation:**

```bash
git add .
git commit -m "feat(<scope>): <description>

Implements step N of <work-id>"
git push
```

### 5. Check Completion

- All steps done → next: ghwf6-verify
- More steps → next: ghwf5-implement (same step)

### 6. Update PR & Labels

- PR チェックリスト更新
- `ghwf:step-5` ラベル追加 (完了時)

### 7. Update State

```json
{
  "current": "ghwf5-implement",
  "next": "ghwf6-verify",  // or "ghwf5-implement"
  "last_execution": "<ISO8601>",
  "implement": {
    "current_step": N,
    "total_steps": M
  }
}
```
