---
name: wf0-schedule
description: Schedule management for batch workflow execution
references:
  - path: ../../commands/wf0-schedule.md
  - path: ../../commands/wf0-batch.md
---

# /wf0-schedule

Schedule management command for batch workflow execution.
Creates and manages execution schedules with dependency analysis.

## Core Functions

1. **Source Aggregation** - Collect works from GitHub, Jira, and local sources
2. **Dependency Detection** - Auto-detect dependencies from issue descriptions
3. **DAG Validation** - Detect circular dependencies before execution
4. **Priority Calculation** - Order works by dependency depth

## Subcommands

| Subcommand | Purpose |
|------------|---------|
| `create [sources...]` | Create schedule from specified sources |
| `show` | Display current schedule |
| `edit [work-id]` | Edit priority or dependencies |
| `validate` | Validate schedule (circular dependency check) |
| `clear` | Delete current schedule |

## Source Types

### GitHub

```bash
/wf0-schedule create github="label:scheduled"
/wf0-schedule create github="label:batch,milestone:v1.0"
```

### Jira

```bash
/wf0-schedule create jira="project=PROJ AND sprint=current"
```

### Local

```bash
/wf0-schedule create local=FEAT-001,FIX-002
```

### Combined

```bash
/wf0-schedule create github="label:scheduled" jira="sprint=current"
/wf0-schedule create --all  # Uses config.json batch.sources
```

## Dependency Patterns

The following patterns are detected from issue body text:

| Pattern | Example |
|---------|---------|
| `depends on #N` | depends on #123 |
| `blocked by #N` | blocked by #456 |
| `requires PROJ-N` | requires PROJ-789 |
| `after: WORK-ID` | after: FEAT-001-auth |

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

## Schedule File

Schedules are stored in `.wf/schedule.json`:

```json
{
  "version": "1.0",
  "status": "pending|running|paused|completed",
  "works": {
    "FEAT-123-auth": {
      "source": {"type": "github", "id": "123"},
      "priority": 1,
      "dependencies": ["FEAT-100-database"],
      "status": "pending"
    }
  },
  "progress": {
    "total": 5,
    "completed": 0,
    "pending": 5
  }
}
```

## Workflow Integration

1. Create schedule: `/wf0-schedule create github="label:batch"`
2. Review: `/wf0-schedule show`
3. Validate: `/wf0-schedule validate`
4. Execute: `/wf0-batch start`

## Detailed Reference

- [wf0-schedule Command](../../commands/wf0-schedule.md)
- [wf0-batch Command](../../commands/wf0-batch.md)
