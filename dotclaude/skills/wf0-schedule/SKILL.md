---
name: wf0-schedule
description: Schedule management for batch workflow execution
argument-hint: "<create | show | edit | validate | clear> [args...]"
---

**Always respond in Japanese.**

# /wf0-schedule

Command for creating and managing workflow schedules with dependency analysis.
Reads Issues/Jiras/Local works, analyzes dependencies, and builds execution schedule.

## Usage

```
/wf0-schedule <subcommand> [arguments...]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `create [sources...]` | Create schedule from specified sources |
| `show` | Display current schedule |
| `edit [work-id]` | Edit priority or dependencies |
| `validate` | Validate schedule (circular dependency check) |
| `clear` | Delete current schedule |

## Source Specification

### GitHub Issues

```bash
# By label
/wf0-schedule create github="label:scheduled"
/wf0-schedule create github="label:batch,label:priority"

# By milestone
/wf0-schedule create github="milestone:v1.0"

# Multiple labels (AND condition)
/wf0-schedule create github="label:feature,label:approved"
```

### Jira Issues

```bash
# By JQL query
/wf0-schedule create jira="project=PROJ AND sprint=current"
/wf0-schedule create jira="project=PROJ AND status='To Do'"
```

### Local Works

```bash
# By work-id (comma-separated)
/wf0-schedule create local=FEAT-001,FIX-002,REFACTOR-003
```

### Combined Sources

```bash
# Multiple sources
/wf0-schedule create github="label:scheduled" jira="sprint=current"

# All sources from config.json
/wf0-schedule create --all
```

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Subcommand and Arguments

```bash
subcommand=$(echo "$ARGUMENTS" | awk '{print $1}')
remaining_args=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}' | xargs)

if [ -z "$subcommand" ]; then
  echo "ERROR: Subcommand required (create|show|edit|validate|clear)"
  exit 1
fi
```

### 2. Load Configuration

```bash
# Check for .wf directory
if [ ! -d .wf ]; then
  echo "WF system is not initialized"
  echo "Please run /wf1-kickoff first"
  exit 1
fi

# Load config.json
CONFIG_FILE=".wf/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  CONFIG_FILE="$HOME/.claude/examples/config.json"
fi

# Load schedule.json if exists
SCHEDULE_FILE=".wf/schedule.json"
```

### 3. Execute Subcommand

#### 3.1 create

Create a new schedule from specified sources.

#### 3.2 show

Display current schedule.

```
Current Schedule
===

Status:     pending
Created:    2026-01-26T10:00:00Z

Progress:   0/3 completed
            0 in progress
            3 pending

===
Works (by priority):

[1] FEAT-100-database
    Status: pending
    Source: github #100
    Deps: (none)

[2] FEAT-123-auth
    Status: pending
    Source: github #123
    Deps: FEAT-100-database

[3] FEAT-124-export
    Status: pending
    Source: github #124
    Deps: FEAT-123-auth

===

Commands:
  /wf0-schedule edit <work-id>  - Edit priority/dependencies
  /wf0-schedule validate        - Check for issues
  /wf0-nexttask                 - Execute next task
```

#### 3.3 edit

Edit priority or dependencies for a work.

```
Edit: $work_id
===

Current priority: $current_priority
Current dependencies: ${current_deps:-"(none)"}

To update, specify:
  priority=<1-10>       (1=highest)
  depends=<work-id,...> (comma-separated)
  remove-dep=<work-id>  (remove dependency)

Example: priority=1 depends=FEAT-100,FEAT-101
```

#### 3.4 validate

Validate the schedule for issues.

```
Validating Schedule
===

Checking circular dependencies...
  OK No circular dependencies

Checking dependency references...
  OK All dependencies resolved

Checking priority conflicts...
  OK No priority conflicts

===
Validation passed
```

#### 3.5 clear

Delete current schedule.

## Dependency Detection Patterns

The following patterns are detected from Issue/Jira body text:

| Pattern | Example | Detected Dependency |
|---------|---------|---------------------|
| `depends on #N` | depends on #123 | Issue #123 |
| `blocked by #N` | blocked by #456 | Issue #456 |
| `requires PROJ-N` | requires PROJ-789 | Jira PROJ-789 |
| `after: WORK-ID` | after: FEAT-001-auth | Work FEAT-001-auth |

Custom patterns can be configured in `config.json`:

```json
{
  "batch": {
    "dependency_patterns": [
      "depends on #(\\d+)",
      "blocked by #(\\d+)"
    ]
  }
}
```

## Schedule JSON Schema

The `status` field uses these values consistently throughout:
- Schedule status: `pending`, `running`, `paused`, `completed`
- Work status: `pending`, `running`, `completed`, `failed`

```json
{
  "version": "1.0",
  "created_at": "2026-01-26T10:00:00Z",
  "status": "pending",
  "sources": [
    {"type": "github", "query": "label:scheduled"},
    {"type": "jira", "query": "sprint=current"},
    {"type": "local", "ids": "FEAT-001,FIX-002"}
  ],
  "works": {
    "FEAT-123-auth": {
      "work_id": "FEAT-123-auth",
      "source": {"type": "github", "id": "123", "title": "Add authentication"},
      "priority": 1,
      "dependencies": ["FEAT-100-database"],
      "status": "pending",
      "started_at": "2026-01-26T10:00:00Z",
      "completed_at": "2026-01-26T12:00:00Z"
    }
  },
  "progress": {
    "total": 5,
    "completed": 1,
    "in_progress": 2,
    "pending": 2
  }
}
```

## Output Examples

### Create Success

```
Creating Schedule
===

Sources:
  - github: label:scheduled

Fetching from GitHub (label:scheduled)...
  - #123: Add user authentication
  - #124: Implement export feature
  - #125: Fix login bug

Analyzing dependencies...
  OK No circular dependencies

===
Schedule created: 3 works

Use '/wf0-schedule show' to view the schedule
Use '/wf0-nexttask' to execute the next task
```

### Show Display

```
Current Schedule
===

Status:     pending
Created:    2026-01-26T10:00:00Z

Progress:   0/3 completed
            0 in progress
            3 pending

===
Works (by priority):

[1] FEAT-100-database
    Status: pending
    Source: github #100
    Deps: (none)

[2] FEAT-123-auth
    Status: pending
    Source: github #123
    Deps: FEAT-100-database

[3] FEAT-124-export
    Status: pending
    Source: github #124
    Deps: FEAT-123-auth

===

Commands:
  /wf0-schedule edit <work-id>  - Edit priority/dependencies
  /wf0-schedule validate        - Check for issues
  /wf0-nexttask                 - Execute next task
```

## Notes

- Requires `gh` CLI for GitHub integration
- Requires `jq` for JSON processing
- Jira integration requires API token configuration
- Schedule is stored in `.wf/schedule.json`
- Works are processed in priority order respecting dependencies
