---
name: ghwf7-pr
description: Draft PR を Ready for Review に変更
argument-hint: ""
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /ghwf7-pr

Draft PR を Ready for Review に変更し、ワークフローを完了する。

## Usage

```
/ghwf7-pr
```

## Prerequisites

- `ghwf6-verify` 完了済み
- 全検証パス

## Processing

### 1. Final Check

- All CI checks passing
- No uncommitted changes
- Documentation complete

### 2. Update PR Body

全チェックボックスを完了に:

```markdown
## Progress
- [x] ghwf1-kickoff
- [x] ghwf2-spec
- [x] ghwf3-plan
- [x] ghwf4-review
- [x] ghwf5-implement
- [x] ghwf6-verify
- [x] ghwf7-pr (Ready for Review)
```

### 3. Convert to Ready

```bash
gh pr ready
```

### 4. Update PR Title

Remove "WIP: " prefix:

```bash
gh pr edit --title "<issue-title>"
```

### 5. Update Labels

```bash
gh issue edit <issue> \
  --remove-label "ghwf:waiting" \
  --add-label "ghwf:completed,ghwf:step-7"
```

### 6. Post Completion Comment

```bash
gh pr comment --body "🤖 Workflow completed. Ready for review.

## Summary
- Commits: N
- Files changed: M
- Lines: +X / -Y

## Documents
- [01_KICKOFF.md](link)
- [02_SPEC.md](link)
- [03_PLAN.md](link)
"
```

### 7. Update State

```json
{
  "current": "ghwf7-pr",
  "next": null,
  "completed_at": "<ISO8601>",
  "last_execution": "<ISO8601>"
}
```

## Post-Completion

After PR is reviewed:
- If changes requested: add `ghwf:revision` label
- Daemon will detect and restart workflow
