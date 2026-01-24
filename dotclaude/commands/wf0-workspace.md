---
description: Create a new workspace from GitHub, Jira, or local work
argument-hint: "github=<n> | jira=<id> | local=<id>"
---

# /wf0-workspace

Command to create a new workspace.

## Usage

```
/wf0-workspace github=<number>
/wf0-workspace jira=<jira-id> [title="title"]
/wf0-workspace local=<id> title="title" [type=<TYPE>]
```

## Arguments

Specify one of the following (mutually exclusive):

- `github`: GitHub Issue number
- `jira`: Jira ticket ID (e.g., `ABC-123`)
- `local`: Local ID (arbitrary string)

Optional arguments:

- `title`: Title (required for jira/local, ignored for github)
- `type`: Work type (local only. FEAT/FIX/REFACTOR/CHORE/RFC. Default: FEAT)

## Processing

Parse $ARGUMENTS to get ID information and execute the following processing.

### 1. Check Prerequisites

```bash
# Check if jq is available
command -v jq >/dev/null || echo "ERROR: jq is required"

# Check gh only for github mode
if [ -n "$github" ]; then
  command -v gh >/dev/null || echo "ERROR: gh is required"
  gh auth status || echo "ERROR: Please run gh auth login"
fi
```

### 2. Get ID Information and Generate work-id

#### 2a. For github mode

```bash
gh issue view <issue_number> --json number,title,labels,body,url
```

Determine from the retrieved information:
- **TYPE**: Determine from labels (feature/enhancement→FEAT, bug→FIX, refactor→REFACTOR, chore→CHORE, rfc→RFC)
- **slug**: Generate from title (lowercase, alphanumeric and hyphens only, max 40 characters)
- **work-id**: `<TYPE>-<issue>-<slug>` format

#### 2b. For jira mode

- **TYPE**: Use Jira ID prefix as-is, or infer from title
- **slug**: Generate from title (lowercase, alphanumeric and hyphens only, max 40 characters)
- **work-id**: `JIRA-<jira-id>-<slug>` format (e.g., `JIRA-ABC-123-add-login`)

#### 2c. For local mode

- **TYPE**: Specified in argument (default: FEAT)
- **slug**: Generate from title (lowercase, alphanumeric and hyphens only, max 40 characters)
- **work-id**: `<TYPE>-<local-id>-<slug>` format (e.g., `FEAT-myid-add-feature`)

### 3. Select Base Branch

Use `default_base_branch` from `.wf/config.json` as default.
Use `main` if not present.

Confirm with user:
> Base branch: Is `<branch>` OK?

### 4. Create Work Branch

```bash
# Branch name: <prefix>/<issue>-<slug>
git checkout -b <branch_name> <base_branch>
```

### 5. Initialize WF Directory

Create `.wf/` directory if it doesn't exist:

```bash
source "$HOME/.claude/scripts/wf-init.sh"
wf_init_project
```

### 6. Create Document Directory

```bash
mkdir -p docs/wf/<work-id>/
```

### 7. Update state.json

```json
{
  "active_work": "<work-id>",
  "works": {
    "<work-id>": {
      "current": "wf0-workspace",
      "next": "wf1-kickoff",
      "source": {
        "type": "github|jira|local",
        "id": "<original_id>",
        "title": "<title>",
        "url": "<issue_url>"
      },
      "git": {
        "base": "<base_branch>",
        "branch": "<feature_branch>"
      },
      "kickoff": {
        "revision": 0,
        "last_updated": null
      },
      "created_at": "<timestamp>"
    }
  }
}
```

### 8. Create worktree (Optional)

If `config.worktree.enabled` is `true`:

```bash
git worktree add .worktrees/<branch-name> <branch>
```

Record worktree path in `local.json`.

### 9. Commit

Commit initial workspace state:

```bash
git add .wf/state.json docs/wf/<work-id>/
git commit -m "docs(wf): create workspace <work-id>

Source: <source_type> #<source_id>
"
```

### 10. Completion Message

```
✅ Workspace created

Work ID: <work-id>
Branch: <branch_name>
Base: <base_branch>
Docs: docs/wf/<work-id>/

Next step: Run /wf1-kickoff to create the Kickoff document
```

## Notes

- Display warning if existing work exists
- Error if branch name already exists
- github mode: Error if Issue not found
- jira/local mode: Error if title is not specified
- github/jira/local are mutually exclusive (error if multiple specified)
