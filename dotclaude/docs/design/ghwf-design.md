# GitHub Workflow (ghwf) Design

## Overview

GitHub Issue/PR をラベルで制御するワークフローシステム。

## Label Schema

### Opt-in Label (Required)

| Label | Description |
|-------|-------------|
| `ghwf` | Enable daemon monitoring for this issue |

**Note**: Issues without the `ghwf` label are ignored, even if they have command labels.

### State Labels (Daemon Managed)

| Label | Description |
|-------|-------------|
| `ghwf:executing` | Currently executing a step |
| `ghwf:waiting` | Waiting for user approval |
| `ghwf:completed` | All steps completed |

### Command Labels (User Assigned)

| Label | Description | Requires Update |
|-------|-------------|-----------------|
| `ghwf:exec` | Execute next step | No |
| `ghwf:redo` | Redo current step | Yes |
| `ghwf:redo-N` | Redo from step N (1-7) | Yes |
| `ghwf:revision` | Full revision from step 1 | Yes |
| `ghwf:stop` | Stop monitoring | No |

### Progress Labels (Daemon Managed)

| Label | Description |
|-------|-------------|
| `ghwf:step-1` | ghwf1-kickoff completed |
| `ghwf:step-2` | ghwf2-spec completed |
| `ghwf:step-3` | ghwf3-plan completed |
| `ghwf:step-4` | ghwf4-review completed |
| `ghwf:step-5` | ghwf5-implement completed |
| `ghwf:step-6` | ghwf6-verify completed |
| `ghwf:step-7` | ghwf7-pr completed |

## Workflow Steps

| Step | Command | Description |
|------|---------|-------------|
| 1 | ghwf1-kickoff | Fetch Issue, create branch, create Draft PR, kickoff doc |
| 2 | ghwf2-spec | Create specification document |
| 3 | ghwf3-plan | Create implementation plan |
| 4 | ghwf4-review | Review plan or code |
| 5 | ghwf5-implement | Implement one step from plan |
| 6 | ghwf6-verify | Verify implementation |
| 7 | ghwf7-pr | Convert Draft PR to Ready for Review |

## Flow Diagram

### Normal Flow

```
[Human] Create Issue + add ghwf + ghwf:exec labels
    ↓
[Daemon] Detect ghwf:exec (on ghwf-labeled issue)
    ↓
[Daemon] Remove ghwf:exec, Add ghwf:executing
    ↓
[Daemon] Execute ghwf1-kickoff
    ├── Create branch
    ├── Create 01_KICKOFF.md
    ├── Push
    └── Create Draft PR (Closes #<issue>)
    ↓
[Daemon] Remove ghwf:executing, Add ghwf:waiting + ghwf:step-1
    ↓
[Human] Review, add ghwf:exec
    ↓
[Daemon] Execute ghwf2-spec ...
    ↓
... repeat ...
    ↓
[Daemon] Execute ghwf7-pr (Draft → Ready for Review)
    ↓
[Daemon] Remove ghwf:waiting, Add ghwf:completed
```

### Label Usage

| Action | Use Label |
|--------|-----------|
| Execute next step | `ghwf:exec` |
| Redo current/specific step | `ghwf:redo` / `ghwf:redo-N` |
| Full revision | `ghwf:revision` |
| Stop workflow | `ghwf:stop` |

### Redo Flow

```
[Human] Add comment: "Fix the parallel processing section"
    ↓
[Human] Add ghwf:redo-3 label
    ↓
[Daemon] Detect ghwf:redo-3
    ↓
[Daemon] Check for updates since last execution:
    - New comments (excluding bot comments)
    - Issue body changes
    - PR review comments
    ↓
[If updates found]
    ↓
[Daemon] Remove ghwf:redo-3, Add ghwf:executing
    ↓
[Daemon] Execute ghwf3-plan with instruction from comment
    ↓
[Daemon] Continue: ghwf4 → ghwf5 → ghwf6 → ghwf7
    ↓
[Daemon] Remove ghwf:executing, Add ghwf:waiting/ghwf:completed
```

### Revision Flow

```
[Human] Review PR, add feedback comments
    ↓
[Human] Add ghwf:revision label
    ↓
[Daemon] Detect ghwf:revision
    ↓
[Daemon] Check for updates (same as redo)
    ↓
[If updates found]
    ↓
[Daemon] ghwf1-kickoff revise (incorporate feedback)
    ↓
[Daemon] Full workflow: ghwf2 → ... → ghwf7
    ↓
[Daemon] Push additional commits to existing PR
```

## Update Detection

When `ghwf:redo*` or `ghwf:revision` is detected:

1. Get last execution timestamp from state.json
2. Check for updates:
   - Issue body `updatedAt` > last execution
   - Comments after last execution (excluding bot)
   - PR review comments after last execution
3. If no updates: stay in `ghwf:waiting`, post notification comment
4. If updates found: proceed with execution

### Bot Comment Detection

Ignore comments from:
- `github-actions[bot]`
- Comments starting with `🤖`
- Comments from the workflow author (configurable)

## Daemon Design

### Single Daemon

```
ghwf0-remote start   → Start daemon
ghwf0-remote stop    → Stop daemon
ghwf0-remote status  → Show status
```

### Safety Limits

| Setting | Default | Description |
|---------|---------|-------------|
| `MAX_STEPS_PER_SESSION` | 10 | Max workflow steps per daemon session |
| `POLL_INTERVAL` | 60 | Polling interval in seconds |

### Retry Strategy

Exponential backoff with configurable parameters:

| Setting | Default | Description |
|---------|---------|-------------|
| `GHWF_RETRY_MAX` | 3 | Max retry attempts for API calls |
| `GHWF_RETRY_DELAY` | 5 | Initial delay between retries (seconds) |
| `GHWF_RETRY_BACKOFF` | 2 | Backoff multiplier |
| `GHWF_CLAUDE_RETRY_MAX` | 2 | Max retries for Claude invocation |
| `GHWF_CLAUDE_RETRY_DELAY` | 30 | Initial delay for Claude retries |

Retry-enabled operations:
- GitHub API calls (issue list, view, edit, comment)
- Git push
- Claude Code invocation

### Security

- **Collaborator-only**: Only users with `admin`/`write`/`maintain` permission can trigger commands
- **Label author check**: Daemon verifies who added the command label via timeline API
- **Bot ignore**: Comments from bots are excluded from update detection

### Polling Logic

```
Every 60 seconds:
1. Query Issues/PRs with ghwf:* labels
2. For each found:
   a. ghwf:exec → execute from step 1 (new issues only)
   b. ghwf:exec → execute next step (step 1+ required)
   c. ghwf:redo* → check updates → execute from step N
   d. ghwf:revision → check updates → execute from step 1
   e. ghwf:stop → stop monitoring this issue
3. Update labels accordingly
4. Push changes
```

### State Management

```json
{
  "works": {
    "<work-id>": {
      "source": {
        "type": "github",
        "issue": 123,
        "pr": 456
      },
      "current": "ghwf3-plan",
      "next": "ghwf4-review",
      "last_execution": "2026-01-31T10:00:00Z",
      "git": {
        "base": "main",
        "branch": "feat/123-feature-name"
      }
    }
  }
}
```

## ghwf1-kickoff Changes

### New Steps

1. Create branch
2. Create 01_KICKOFF.md
3. Commit
4. Push branch
5. **Create Draft PR** (NEW)
   ```bash
   gh pr create --draft \
     --title "WIP: <issue-title>" \
     --body "Closes #<issue-number>

   ## Progress
   - [ ] ghwf1-kickoff
   - [ ] ghwf2-spec
   - [ ] ghwf3-plan
   - [ ] ghwf4-review
   - [ ] ghwf5-implement
   - [ ] ghwf6-verify
   - [ ] ghwf7-pr (Ready for Review)"
   ```
6. **Update labels** (NEW)
   - Add: `ghwf:waiting`, `ghwf:step-1`
   - Remove: `ghwf:exec`, `ghwf:executing`

## ghwf7-pr Changes

1. Convert Draft PR to Ready for Review
   ```bash
   gh pr ready
   ```
2. Update PR body (all checkboxes checked)
3. Update labels:
   - Remove: `ghwf:waiting`
   - Add: `ghwf:completed`, `ghwf:step-7`

## File Structure

```
skills/
├── ghwf0-remote/SKILL.md
├── ghwf1-kickoff/SKILL.md
├── ghwf2-spec/SKILL.md
├── ghwf3-plan/SKILL.md
├── ghwf4-review/SKILL.md
├── ghwf5-implement/SKILL.md
├── ghwf6-verify/SKILL.md
└── ghwf7-pr/SKILL.md

scripts/
└── ghwf/
    ├── ghwf-daemon.sh
    └── ghwf-utils.sh
```

## Migration from wf*

- Keep existing `wf*` commands for local/Jira (deferred)
- `ghwf*` is GitHub-specific, optimized for label-based control
- No breaking changes to existing workflows
