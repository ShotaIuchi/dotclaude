---
name: wf0-restore
description: Restore an existing workspace
argument-hint: "[work-id]"
---

**Always respond in Japanese.**

# /wf0-restore

Command to restore an existing workspace. Used for resuming work on a different PC or recreating a worktree.

## Usage

```
/wf0-restore [work-id]
```

## Arguments

- `work-id`: ID of the work to restore (optional)
  - If omitted: Use `active_work` from `state.json`
  - If `active_work` is also not set: Present candidates for selection

## Processing

Parse $ARGUMENTS to get work-id and execute the following processing.

### 1. Check Prerequisites

```bash
# Check for required commands
command -v jq >/dev/null || { echo "ERROR: jq is required"; exit 1; }
command -v git >/dev/null || { echo "ERROR: git is required"; exit 1; }
```

### 2. Resolve work-id

```bash
# Use argument if provided
work_id="$ARGUMENTS"

# If empty, check active_work
if [ -z "$work_id" ]; then
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi

# If still empty, present candidates using AskUserQuestion
if [ -z "$work_id" ]; then
  echo "Available work-ids:"
  jq -r '.works | keys[]' .wf/state.json

  # Use AskUserQuestion tool for selection
  # Build options from available work-ids (max 4 options)
  # {
  #   "questions": [{
  #     "question": "Which workspace do you want to restore?",
  #     "header": "Select work",
  #     "options": [
  #       {"label": "<work-id-1>", "description": "Branch: <branch>, Phase: <current>"},
  #       {"label": "<work-id-2>", "description": "Branch: <branch>, Phase: <current>"},
  #       ...
  #     ],
  #     "multiSelect": false
  #   }]
  # }
fi
```

### 3. Fetch Latest Information from Remote

```bash
git fetch --all --prune
```

### 4. Restore Branch

Get work information from state.json:

```bash
branch=$(jq -r ".works[\"$work_id\"].git.branch" .wf/state.json)
base=$(jq -r ".works[\"$work_id\"].git.base" .wf/state.json)
```

Check branch existence and restore:

```bash
# Check if exists locally
if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Local branch exists: $branch"
  git checkout "$branch"
# Check if exists on remote
elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  echo "Creating from remote branch: $branch"
  git checkout -b "$branch" "origin/$branch"
else
  echo "ERROR: Branch not found: $branch"
  exit 1
fi
```

### 5. Restore worktree (Optional)

If `config.worktree.enabled` is `true`:

```bash
worktree_root=$(jq -r '.worktree.root_dir // ".worktrees"' .wf/config.json)
worktree_path="$worktree_root/${branch//\//-}"

if [ ! -d "$worktree_path" ]; then
  git worktree add "$worktree_path" "$branch"
  echo "worktree created: $worktree_path"
fi

# Update local.json (using temp file for safe update)
tmp_file=$(mktemp)
jq ".works[\"$work_id\"].worktree_path = \"$worktree_path\"" .wf/local.json > "$tmp_file" && mv "$tmp_file" .wf/local.json
```

### 6. Update active_work

```bash
jq ".active_work = \"$work_id\"" .wf/state.json > .wf/state.json.tmp
mv .wf/state.json.tmp .wf/state.json
```

### 7. Display Status

```
Workspace restored

Work ID: <work-id>
Branch: <branch>
Base: <base>
Current: <current_phase>
Next: <next_phase>

Documents:
- docs/wf/<work-id>/

Next step: Run /<next_phase>
```

## Notes

- Error if state.json does not exist
- Error if specified work-id does not exist in state.json
- Error if branch exists neither locally nor on remote
- Worktree root directory is created automatically
