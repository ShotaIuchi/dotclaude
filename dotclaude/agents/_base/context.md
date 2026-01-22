# Common Context

Basic context shared by all sub-agents.

## WF Management System Overview

This system is a workflow management system for AI (Claude Code) and humans to work while viewing the same state and artifacts.

### Basic Principles

1. **State Sharing**: AI and humans grasp the same work state
2. **Unified Artifact Management**: Manage documents and code in a linked manner
3. **Work Reproducibility**: Continue work on different PCs or sessions
4. **Prevention of Off-Plan Changes**: Implement only planned work

## File Structure

### Configuration Files

```
.wf/
├── config.json      # Shared configuration (committed)
├── state.json       # Shared state (committed)
└── local.json       # Local configuration (gitignored)
```

### Documents

```
docs/wf/<work-id>/
├── 00_KICKOFF.md        # Goal and success criteria definition
├── 01_SPEC.md           # Change specification
├── 02_PLAN.md           # Implementation plan
├── 03_REVIEW.md         # Review record
├── 04_IMPLEMENT_LOG.md  # Implementation log
└── 05_REVISIONS.md      # Change history
```

## Reading State

### state.json

```json
{
  "active_work": "<work-id>",
  "works": {
    "<work-id>": {
      "current": "wf5-implement",
      "next": "wf6-verify",
      "git": {
        "base": "develop",
        "branch": "feat/123-export-csv"
      },
      "kickoff": {
        "revision": 2,
        "last_updated": "2026-01-17T14:30:00+09:00"
      },
      "plan": {
        "total_steps": 5,
        "current_step": 3
      },
      "agents": {
        "last_used": "research",
        "sessions": {}
      }
    }
  }
}
```

### How to Read

```bash
# Get active work ID
work_id=$(jq -r '.active_work // empty' .wf/state.json)

# Get work details
jq ".works[\"$work_id\"]" .wf/state.json

# Document path
docs_dir="docs/wf/$work_id"
```

## Getting Issue Information

```bash
# Extract Issue number from work-id
issue_number=$(echo "$work_id" | sed 's/^[^-]*-\([0-9]*\)-.*/\1/')

# Get Issue information via GitHub CLI
gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone
```

## Workflow Order

```
wf0-workspace → wf1-kickoff → wf2-spec → wf3-plan → wf4-review → wf5-implement → wf6-verify
```

Documents generated at each phase:

| Phase | Document |
|-------|----------|
| wf1-kickoff | 00_KICKOFF.md |
| wf2-spec | 01_SPEC.md |
| wf3-plan | 02_PLAN.md |
| wf4-review | 03_REVIEW.md |
| wf5-implement | 04_IMPLEMENT_LOG.md |
| wf1-kickoff (update) | 05_REVISIONS.md |
