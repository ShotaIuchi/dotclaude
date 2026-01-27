---
name: wf0-restore
description: Restore an existing workspace
argument-hint: "[work-id]"
---

**Always respond in Japanese.**

# /wf0-restore

Restore an existing workspace for resuming work on a different PC or recreating a worktree.

## Usage

```
/wf0-restore [work-id]
```

## Arguments

- `work-id`: Optional. Uses `active_work` from state.json, or presents candidates via AskUserQuestion.

## Processing

### 1. Check Prerequisites

Require `jq` and `git`.

### 2. Resolve work-id

Argument → `active_work` → AskUserQuestion with available work-ids (show branch and current phase for each).

### 3. Fetch Remote

`git fetch --all --prune`

### 4. Restore Branch

Get branch/base from state.json. Check local branch → remote branch → error if neither exists. Checkout accordingly.

### 5. Restore Worktree (Optional)

If `config.worktree.enabled`: create worktree if not exists, update `.wf/local.json` with path.

### 6. Update active_work

Set `active_work` in state.json.

### 7. Display Status

Show: Work ID, Branch, Base, Current phase, Next phase, Docs path, next step command.

## Notes

- Error if state.json missing or work-id not found
- Worktree root directory created automatically
