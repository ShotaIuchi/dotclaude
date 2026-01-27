---
name: wf0-nexttask
description: Execute next task from schedule
references:
  - path: ../../commands/wf0-nexttask.md
  - path: ../../commands/wf0-schedule.md
---

# /wf0-nexttask

Task selection and execution command for scheduled workflows.
Retrieves a dependency-resolved task from schedule.json and executes workflow phases.

## Core Functions

1. **Task Selection** - Get next available task with resolved dependencies
2. **Execution Range** - Choose how far to execute (kickoff only, until plan, etc.)
3. **Progress Tracking** - Update schedule status as tasks complete
4. **Dependency Awareness** - Only execute tasks when dependencies are satisfied

## Options

| Option | Purpose |
|--------|---------|
| `--dry-run` | Preview task info without executing |
| `--until <phase>` | Auto-execute until specified phase |
| `--all` | Execute all remaining tasks |

## Execution Range Options

When invoked without options, presents these choices:

| Option | Description |
|--------|-------------|
| wf1-kickoff only | Start work, pause for review |
| Until wf3-plan | Complete design phase |
| Until wf4-review | Complete review phase |
| Until wf6-verify | Complete entire task |
| Complete all tasks | Execute all remaining tasks |

## Relationship with Other Commands

| Command | Scope | Purpose |
|---------|-------|---------|
| `/wf0-schedule` | Schedule management | Create/edit/validate schedules |
| `/wf0-nexttask` | Task level | Select and execute next task |
| `/wf0-nextstep` | Phase level | Transition within a single task |

## Workflow Integration

1. Create schedule: `/wf0-schedule create github="label:batch"`
2. Review schedule: `/wf0-schedule show`
3. Execute next task: `/wf0-nexttask`
4. Repeat step 3 until all tasks complete

## Usage Examples

### Basic Usage

```bash
# Execute next available task
/wf0-nexttask

# Preview next task without executing
/wf0-nexttask --dry-run

# Execute until plan phase
/wf0-nexttask --until wf3-plan

# Execute all remaining tasks
/wf0-nexttask --all
```

### Batch Processing Workflow

```bash
# Create schedule from GitHub issues
/wf0-schedule create github="label:scheduled"

# Execute tasks one by one
/wf0-nexttask  # First task
/wf0-nexttask  # Second task
# ... repeat

# Or execute all at once
/wf0-nexttask --all
```

## Output Examples

### Task Selection

```

Next Task: FEAT-123-auth

Source:       github #123
Title:        Add user authentication
Dependencies: FEAT-100-database (completed)

Where would you like to stop?

  1. wf1-kickoff only (Start work)
  2. Until wf3-plan (Design complete)
  3. Until wf4-review (Review complete)
  4. Until wf6-verify (Task complete)
  5. Complete all remaining tasks
```

### Completion Notification

```

Task FEAT-123-auth completed!

Remaining tasks: 2
  Ready:
    - FEAT-124-export
  Blocked:
    - FEAT-125-api (blocked by: FEAT-124-export)

Run '/wf0-nexttask' for the next task
```

## Detailed Reference

- [wf0-nexttask Command](../../commands/wf0-nexttask.md)
- [wf0-schedule Command](../../commands/wf0-schedule.md)
