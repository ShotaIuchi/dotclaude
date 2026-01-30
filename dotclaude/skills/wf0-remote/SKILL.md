---
name: wf0-remote
description: GitHub Issue経由のリモートワークフロー操作
argument-hint: "<subcommand> [target...]"
---

**Always respond in Japanese.**

# /wf0-remote

Remote workflow monitoring and execution via GitHub Issue comments. Enables mobile approval while PC daemon executes commands.

## Usage

```
/wf0-remote <subcommand> [target...]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `start [target...]` | Start remote monitoring (tmux session) |
| `stop [target...]` | Stop remote monitoring |
| `status` | Show monitoring status |

## Target Specification

- `<work-id>...`: One or more work IDs (variadic)
- `--all`: All works with GitHub source
- `<pattern>`: Wildcard (e.g., `FEAT-*`, `*-auth`, `FIX-???-*`)
- Omitted: Use `active_work` from state.json

## Processing

### 1. Resolve Targets

From state.json `.works`, filter by target type:
- `--all`: works with `source.type == "github"`
- pattern: glob match against work IDs
- multiple: verify each exists
- single/omitted: use specified or active work

### 2. start

For each target work:
1. Get GitHub issue number from state.json source
2. Launch tmux session `wf-remote-<work-id>` running the polling daemon
3. Update state.json with `remote: { enabled: true, source_issue, status: "waiting_approval", tmux_session }`

### 3. stop

Kill tmux sessions for target works. Update state.json `remote.enabled = false`.

### 4. status

Display for each monitored work: issue number, status, tmux session state, last check time.

## Remote Commands (Issue Comments)

| Command | Description |
|---------|-------------|
| `/approve` or `/next` | Execute next workflow step |
| `/pause` | Pause monitoring |
| `/stop` | Stop monitoring completely |

## State JSON Extension

```json
{
  "works": {
    "<work-id>": {
      "remote": {
        "enabled": true,
        "source_issue": 123,
        "poll_interval": 60,
        "last_check": "<ISO8601>",
        "status": "waiting_approval|executing|paused|stopped",
        "tmux_session": "wf-remote-<work-id>"
      }
    }
  }
}
```

## Security

| Rule | Description |
|------|-------------|
| Collaborator-only | Only `admin`/`write`/`maintain` permission comments processed |
| Step limit | Max 10 steps per session |
| Command whitelist | Only `/approve`, `/next`, `/pause`, `/stop` |
| Execution scope | Only `/wf0-nextstep` executed |

## Notes

- Requires `gh` CLI and `tmux`
- See `rules/remote-operation.md` for detailed security rules
