---
name: wf0-nexttask
description: Execute next task from schedule
argument-hint: "[--dry-run] [--until <phase>] [--all]"
---

**Always respond in Japanese.**

# /wf0-nexttask

Select and execute the next task from schedule.json, respecting dependency order.

## Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Display task info only, do not execute |
| `--until <phase>` | Auto-execute until specified phase (skip selection) |
| `--all` | Auto-execute all remaining tasks (max 50, safety limit) |

## Processing

Parse $ARGUMENTS and execute the following.

### 1. Load Schedule

Read `.wf/schedule.json`. Error if missing (suggest `/wf0-schedule create`). Exit if `.status == "completed"`.

### 2. Get Next Task

From `.works`, find the first pending work (sorted by `.priority`) whose `.dependencies` are all completed. If none found, display blocked tasks and exit.

### 3. Display Task Info

Show: work ID, source type/ID, title, dependencies.

### 4. Dry Run

If `--dry-run`: show progress (completed/total, pending count) and exit.

### 5. Execution Range Selection

If neither `--until` nor `--all` specified, use AskUserQuestion:

```
AskUserQuestion(
  questions: [{
    question: "Where would you like to stop?",
    header: "Execute",
    options: [
      { label: "wf1-kickoff only", description: "Start work, then pause for review" },
      { label: "Until wf3-plan", description: "Complete design phase" },
      { label: "Until wf4-review", description: "Complete review phase" },
      { label: "Until wf6-verify (Recommended)", description: "Complete entire task" },
      { label: "Complete all tasks", description: "Execute all remaining tasks in schedule" }
    ],
    multiSelect: false
  }]
)
```

Selection mapping: 1→wf1-kickoff, 2→wf3-plan, 3→wf4-review, 4→wf6-verify, 5→execute_all.

### 6. Execute Workflow

1. Update schedule: set work status to `"running"`, record `started_at`, update `.progress`
2. Execute `/wf1-kickoff {work_id}` via Skill tool
3. If target is beyond wf1-kickoff, loop `/wf0-nextstep {work_id}` until `current == target_phase` or `next == "complete"`

### 7. Mark Complete and Show Remaining

If PR created (`.works[work_id].pr.url` exists in state.json):
- Update schedule: status→`"completed"`, record `completed_at`, update `.progress`

Show remaining task count. If zero, set schedule `.status = "completed"`.

For `--all` / selection 5: loop steps 2-7 for each available task.

## Relationship with wf0-nextstep

| Command | Scope |
|---------|-------|
| `wf0-nextstep` | Phase transition within a single work (wf1→wf2→...→wf6) |
| `wf0-nexttask` | Task selection across multiple works in schedule.json |

## Notes

- Schedule must exist (create with `/wf0-schedule create`)
- Tasks execute in priority order respecting dependencies
- `--all` has a 50-task safety limit per invocation
