---
name: wf0-nextstep
description: Execute the next workflow step
argument-hint: "[work-id]"
---

**Always respond in Japanese.**

# /wf0-nextstep

Immediately execute the next workflow command without confirmation.

## Usage

```
/wf0-nextstep [work-id]
```

## Arguments

- `work-id`: Optional. Uses `active_work` from state.json if omitted.

## Processing

### 1. Resolve Work

Load state.json. Resolve work-id (argument or active_work). Get `current` and `next` fields.

### 2. Determine Action

| `next` value | Action |
|---|---|
| null/empty | Error: suggest `/wf0-status` |
| `"complete"` + PR exists | Display "work complete" with PR URL |
| `"complete"` + no PR | Suggest `/wf6-verify pr` |
| `"wf5-implement"` | Check `plan.current_step < plan.total_steps`, execute `/wf5-implement <next_step>` |
| Other phase | Execute `/<next_phase>` |

### 3. Execute

Use Skill tool to invoke the determined command immediately. No user confirmation.

## Notes

- Executes immediately without confirmation
- For wf5-implement, passes the next step number as argument
- Prompts `/wf1-kickoff` if state.json missing
