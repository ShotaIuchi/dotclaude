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
| `auto` | Start auto-discovery mode |
| `auto stop` | Stop auto mode |
| `auto status` | Show auto mode status |

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

## Auto Mode

Auto mode automatically discovers GitHub Issues with a specific label and processes them without manual intervention. It also supports **revision mode** for re-processing issues after PR review feedback.

### Usage

```
/wf0-remote auto              # Start auto-discovery mode
/wf0-remote auto stop         # Stop auto mode
/wf0-remote auto status       # Show current status
/wf0-remote auto --max 3      # Process maximum 3 issues
/wf0-remote auto --dry-run    # List issues without executing
/wf0-remote auto --once       # Process one issue and exit
```

### Options

| Option | Description |
|--------|-------------|
| `--max <N>` | Maximum issues to process (default: 5) |
| `--cooldown <MIN>` | Minutes between issues (default: 5) |
| `--dry-run` | Query issues without executing |
| `--once` | Process once and exit |

### Configuration

Add to `.wf/config.json`:

```json
{
  "auto": {
    "query": "auto-workflow",
    "exclude_labels": ["blocked", "wip"],
    "complete_label": "completed",
    "revision_label": "needs-revision",
    "max_issues": 5,
    "cooldown_minutes": 5
  }
}
```

### Workflow (New Issues)

1. Query GitHub Issues with configured label (excluding `completed`)
2. For each issue (oldest first):
   - Create feature branch from base
   - Execute `/wf1-kickoff #<issue>`
   - Run `/wf0-nextstep` loop until completion
   - Push changes and add `completed` label
3. On failure: post error comment and skip to next issue
4. Cooldown between issues to prevent rate limiting

### Revision Mode

When a PR needs changes after review, the revision workflow automatically processes feedback:

#### Trigger

Add `needs-revision` label to an issue that already has `completed` label.

#### Revision Workflow

1. Auto-daemon detects issue with both `completed` and `needs-revision` labels
2. **Revisions are prioritized** over new issues
3. Existing workspace is restored via `/wf0-restore`
4. `/wf1-kickoff revise` incorporates:
   - PR review comments
   - Issue body updates
   - New Issue comments
5. Full workflow re-executes (wf2 → ... → wf6 → wf7)
6. Additional commits are pushed to existing PR
7. `needs-revision` label is removed (keeping `completed`)

#### Revision Flow Diagram

```
[Human] Reviews PR, adds feedback comments
    ↓
[Human] Adds `needs-revision` label to Issue/PR
    ↓
[auto-daemon] Detects: completed + needs-revision
    ↓
[auto-daemon] wf0-restore (existing work-id)
    ↓
[auto-daemon] wf1-kickoff revise (PR/Issue feedback)
    ↓
[auto-daemon] wf0-nextstep loop (wf2 → ... → wf6)
    ↓
[auto-daemon] wf7-pr update (additional commits)
    ↓
[auto-daemon] Remove `needs-revision` label
```

### State File

Auto mode maintains state in `.wf/auto.json`:

```json
{
  "enabled": true,
  "session_start": "2026-01-30T10:00:00Z",
  "processed_count": 2,
  "current_issue": 456,
  "is_revision": false,
  "tmux_session": "wf-auto"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | boolean | Auto mode is running |
| `session_start` | string | Session start time (ISO8601) |
| `processed_count` | number | Issues processed this session |
| `current_issue` | number | Currently processing issue |
| `is_revision` | boolean | Current issue is a revision |
| `tmux_session` | string | tmux session name |

## Notes

- Requires `gh` CLI and `tmux`
- See `rules/remote-operation.md` for detailed security rules
