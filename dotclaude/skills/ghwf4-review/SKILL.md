---
name: ghwf4-review
description: Plan またはコードのレビュー記録を作成
argument-hint: "[plan | code]"
context: fork
agent: general-purpose
---

**Always respond in Japanese. Write all workflow documents (*.md) in Japanese.**

# /ghwf4-review

Plan または実装コードのレビューを行い、記録を作成する。

## Usage

```
/ghwf4-review         # 自動判定
/ghwf4-review plan    # Plan レビュー
/ghwf4-review code    # コードレビュー
```

## Prerequisites

- `ghwf3-plan` 完了済み

## Processing

### 1. Load Context

- Read `state.json` for active work
- Fetch Issue/PR with comments:
  ```bash
  gh issue view <issue> --json body,comments
  gh pr view <pr> --json comments,reviews
  ```

### 2. Determine Review Target

- 実装前: Plan レビュー
- 実装後: Code レビュー

### 3. Create/Update 04_REVIEW.md

- Template: `~/.claude/templates/04_REVIEW.md`
- Sections:
  - Review Summary
  - Issues Found
  - Recommendations
  - Approval Status

### 4. Commit & Push

**Execute immediately without confirmation:**

```bash
git add docs/wf/<work-id>/04_REVIEW.md
git commit -m "docs(wf): create review <work-id>"
git push
```

### 5. Update PR & Labels

- PR チェックリスト更新
- `ghwf:step-4` ラベル追加

### 6. Update State

```json
{
  "current": "ghwf4-review",
  "next": "ghwf5-implement",
  "last_execution": "<ISO8601>"
}
```
