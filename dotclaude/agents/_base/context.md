# Common Context

Basic context shared by all sub-agents.

## WF Management System Overview

This system is a workflow management system for AI (Claude Code) and humans to work while viewing the same state and artifacts.

### Basic Principles

1. **State Sharing**: AI and humans grasp the same work state
2. **Unified Artifact Management**: Manage documents and code in a linked manner
3. **Work Reproducibility**: Continue work on different PCs or sessions
4. **Prevention of Off-Plan Changes**: Implement only planned work
   - Enforced via `02_PLAN.md` step tracking in `state.json`
   - Each implementation step must match a planned item
   - See `commands/wf5-implement.md` for implementation constraints

## File Structure

### Configuration Files

```
.wf/
├── config.json      # Shared configuration (committed)
├── state.json       # Shared state (committed)
└── local.json       # Local configuration (gitignored)
```

#### local.json

Local configuration file that is gitignored for environment-specific settings:

```json
{
  "editor": "code",           // Preferred editor command
  "terminal": "iterm2",       // Terminal application
  "browser": "chrome",        // Default browser for previews
  "notifications": true,      // Enable desktop notifications
  "auto_commit": false,       // Auto-commit on workflow completion
  "debug": false              // Enable debug output
}
```

This file allows individual developers to customize their local workflow experience without affecting shared configurations.

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

#### agents.sessions

The `sessions` object tracks sub-agent execution history and context for the current work:

```json
"sessions": {
  "research": {
    "started_at": "2026-01-17T10:00:00+09:00",
    "completed_at": "2026-01-17T10:15:00+09:00",
    "status": "completed",
    "output_ref": "docs/wf/<work-id>/research_output.md"
  },
  "planner": {
    "started_at": "2026-01-17T10:20:00+09:00",
    "status": "in_progress"
  }
}
```

This enables:
- Resuming interrupted agent sessions
- Tracking which agents have been invoked
- Referencing outputs from previous agent executions

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
# work-id format: <type>-<issue_number>-<description>
# Example: feat-123-export-csv → extracts 123
#
# Regex breakdown:
#   ^[^-]*-    Match prefix up to first hyphen (e.g., "feat-")
#   \([0-9]*\) Capture group: one or more digits (the issue number)
#   -.*        Match remaining suffix after issue number
issue_number=$(echo "$work_id" | sed 's/^[^-]*-\([0-9]*\)-.*/\1/')

# Alternative using cut (simpler but assumes consistent format):
# issue_number=$(echo "$work_id" | cut -d'-' -f2)

# Get Issue information via GitHub CLI
gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone
```

## Workflow Order

```
wf1-kickoff → wf2-spec → wf3-plan → wf4-review → wf5-implement → wf6-verify
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

### 05_REVISIONS.md Management

The `05_REVISIONS.md` file tracks changes to the kickoff document:

- **Created**: When `wf1-kickoff` is run with `--update` flag on existing work
- **Updated**: Each subsequent kickoff revision appends a new entry
- **Purpose**: Maintains audit trail of scope/goal changes during development
- **Format**: Includes revision number, timestamp, summary of changes, and reason for update

## Configuration Reference

### config.json

Shared configuration file committed to the repository:

```json
{
  "version": "1.0",
  "project": {
    "name": "project-name",
    "default_branch": "main"
  },
  "workflow": {
    "require_review": true,       // Require wf4-review before implementation
    "auto_create_branch": true,   // Auto-create git branch on kickoff
    "docs_path": "docs/wf"        // Path for workflow documents
  },
  "agents": {
    "enabled": ["research", "planner", "implementer"],
    "timeout": 300                // Agent execution timeout in seconds
  }
}
```

## Error Handling

### Missing state.json

When `state.json` does not exist or is invalid:

```bash
# Check if state file exists
if [ ! -f .wf/state.json ]; then
  echo "Error: .wf/state.json not found. Run 'wf1-kickoff' to initialize."
  exit 1
fi

# Validate JSON format
if ! jq empty .wf/state.json 2>/dev/null; then
  echo "Error: .wf/state.json is not valid JSON"
  exit 1
fi

# Check for active work
work_id=$(jq -r '.active_work // empty' .wf/state.json)
if [ -z "$work_id" ]; then
  echo "No active work. Run 'wf1-kickoff' to start a new work item."
  exit 1
fi
```

### Common Error Scenarios

| Scenario | Action |
|----------|--------|
| No `.wf/` directory | Run `wf1-kickoff` to initialize |
| Invalid JSON in state.json | Check for syntax errors, restore from git if needed |
| No active_work set | Run `wf1-kickoff` or `wf0-restore` |
| Missing workflow documents | Check `docs/wf/<work-id>/` path, may need restoration |

## Sub-Agent Context Sharing

### Context Inheritance

Sub-agents inherit context through a hierarchical structure:

1. **Base Context** (this document): Shared by all sub-agents
2. **Category Context**: Shared within agent categories (analysis, task, workflow)
3. **Agent-Specific Context**: Unique to each agent

### Passing Context Between Agents

When one agent invokes another:

```json
{
  "parent_agent": "research",
  "context": {
    "work_id": "<work-id>",
    "findings": ["..."],
    "recommendations": ["..."]
  },
  "handoff_reason": "Analysis complete, ready for planning"
}
```

The receiving agent can access parent context via `state.json`:

```bash
# Get parent agent's output reference
parent_output=$(jq -r ".works[\"$work_id\"].agents.sessions.research.output_ref" .wf/state.json)
```
