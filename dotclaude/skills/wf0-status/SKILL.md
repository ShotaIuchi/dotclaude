---
name: wf0-status
description: Display current workflow status
argument-hint: "[work-id]"
---

**Always respond in Japanese.**

# /wf0-status

Command to display current workflow status.

## Usage

```
/wf0-status [work-id]
```

## Arguments

- `work-id`: ID of the work to display (optional)
  - If omitted: Use `active_work` from `state.json`
  - If `all` is specified: Display all works

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Load state.json

```bash
if [ ! -f .wf/state.json ]; then
  echo "WF system is not initialized"
  echo "Please run $HOME/.claude/scripts/wf-init.sh"
  exit 1
fi
```

### 2. Determine Display Target

```bash
arg="$ARGUMENTS"

if [ "$arg" = "all" ]; then
  # Display all works
  show_all=true
elif [ -n "$arg" ]; then
  # Display specified work-id
  work_id="$arg"
else
  # Display active_work
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi
```

### 3. Display Status

#### When displaying a single work

```
WF Status: <work-id>
===

Branch:   <branch>
Base:     <base>
Current:  <current_phase>
Next:     <next_phase>
Created:  <created_at>

Documents:
   docs/wf/<work-id>/
   - 00_KICKOFF.md    [exists/missing]
   - 01_SPEC.md       [exists/missing]
   - 02_PLAN.md       [exists/missing]
   - 03_REVIEW.md     [exists/missing]  (created by wf4-review)
   - 04_IMPLEMENT_LOG.md [exists/missing]
   - 05_REVISIONS.md  [exists/missing]

Phase Progress:
   [->] wf1-kickoff     <- current
   [ ] wf2-spec
   [ ] wf3-plan
   [ ] wf4-review
   [ ] wf5-implement
   [ ] wf6-verify

Next: /<next_phase>
```

#### When displaying all works

```
WF Status: All Works
===

Active: <active_work>

| Work ID | Branch | Current | Next |
|---------|--------|---------|------|
| FEAT-123-export-csv | feat/123-export-csv | wf2-spec | wf3-plan |
| FIX-456-login-error | fix/456-login-error | wf5-implement | wf6-verify |

Total: 2 works
```

### 4. Additional Git Status Display (Optional)

Also display current branch information:

```bash
echo ""
echo "Git Status:"
echo "   Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "   Uncommitted changes: $(git status --porcelain | wc -l | tr -d ' ')"
```

### 5. Worktree Information (If Enabled)

```bash
if [ -f ".wf/config.json" ] && [ "$(jq -r '.worktree.enabled // false' .wf/config.json)" = "true" ]; then
  # Check for local.json existence
  if [ ! -f ".wf/local.json" ]; then
    echo ""
    echo "worktree is enabled but local.json not found"
    echo ""
    echo "Current worktree list:"
    git worktree list
    echo ""
    echo "Please run /wf0-restore to reconfigure worktree"
  else
    worktree_path=$(jq -r ".works[\"$work_id\"].worktree_path // empty" .wf/local.json)
    if [ -n "$worktree_path" ]; then
      echo ""
      echo "Worktree: $worktree_path"
    fi
  fi
fi
```

## Output Format

- Format information for easy reading
- Emphasize important information (current, next)
- Check and display document existence status
- Visually display phase progress

## Notes

- Prompt initialization if state.json does not exist
- Display message if active_work is not set
- Error if specified work-id does not exist
