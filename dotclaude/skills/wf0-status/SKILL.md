---
name: wf0-status
description: 現在のワークフロー状態を表示
argument-hint: "[work-id | all]"
---

**Always respond in Japanese.**

# /wf0-status

Display current workflow status.

## Usage

```
/wf0-status [work-id | all]
```

## Arguments

- `work-id`: Specific work to display (optional)
- `all`: Display all works
- Omitted: Use `active_work` from state.json

## Processing

### Single Work Display

Show: work-id, branch, base, current/next phase, created_at, document existence check (00-05), phase progress with current marker, git status (current branch, uncommitted changes count).

If worktree enabled: show worktree path from `.wf/local.json`. If `local.json` missing, show worktree list and suggest `/wf0-restore`.

### All Works Display

Table: Work ID, Branch, Current, Next. Show active work indicator and total count.

## Notes

- Prompt initialization if state.json missing
- Show message if no active_work set
- Error if specified work-id not found
