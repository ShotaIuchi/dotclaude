---
name: sh1-create
description: バッチワークフロー実行のスケジュール管理
argument-hint: "<create | show | edit | validate | clear> [args...]"
---

**Always respond in Japanese.**

# /sh1-create

Create and manage workflow schedules with dependency analysis.

## Usage

```
/sh1-create <subcommand> [arguments...]
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

```bash
# GitHub Issues (by label or milestone)
/sh1-create create github="label:scheduled"
/sh1-create create github="milestone:v1.0"

# Jira (by JQL)
/sh1-create create jira="project=PROJ AND sprint=current"

# Local works (comma-separated)
/sh1-create create local=FEAT-001,FIX-002

# Combined / All from config
/sh1-create create github="label:scheduled" jira="sprint=current"
/sh1-create create --all
```

## Processing

### create

1. Fetch issues from specified sources
2. Generate work-ids for each
3. Detect dependencies from issue body text (patterns: `depends on #N`, `blocked by #N`, `requires PROJ-N`, `after: WORK-ID`)
4. Check for circular dependencies
5. Assign priorities (configurable via `config.json` `batch.dependency_patterns`)
6. Save to `.wf/schedule.json`

### show

Display: status, created date, progress (completed/in_progress/pending), works sorted by priority with deps.

### edit

Edit priority (`priority=<1-10>`) or dependencies (`depends=<ids>`, `remove-dep=<id>`) for a work.

### validate

Check: circular dependencies, unresolved dependency references, priority conflicts.

### clear

Delete `.wf/schedule.json` with confirmation.

## Schedule JSON Schema

```json
{
  "version": "1.0",
  "created_at": "<timestamp>",
  "status": "pending|running|paused|completed",
  "sources": [{"type": "github", "query": "label:scheduled"}],
  "works": {
    "<work-id>": {
      "source": {"type": "github", "id": "123", "title": "..."},
      "priority": 1,
      "dependencies": ["<other-work-id>"],
      "status": "pending|running|completed|failed",
      "started_at": null,
      "completed_at": null
    }
  },
  "progress": { "total": 5, "completed": 0, "in_progress": 0, "pending": 5 }
}
```

## Notes

- Requires `gh` for GitHub, `jq` for JSON
- Schedule stored in `.wf/schedule.json`
- Works processed in priority order respecting dependencies
