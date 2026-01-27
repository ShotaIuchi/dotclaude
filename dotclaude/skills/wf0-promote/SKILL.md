---
name: wf0-promote
description: Promote local workflow to GitHub Issue or Jira
argument-hint: "<github | jira> [work-id]"
---

**Always respond in Japanese.**

# /wf0-promote

Promote a local workflow to GitHub Issue or Jira ticket.

## Usage

```
/wf0-promote github [work-id]
/wf0-promote jira [work-id]
```

## Arguments

- `github` / `jira`: Target platform
- `work-id`: Optional. Uses active work if omitted.

## Prerequisites

- github: `gh` CLI authenticated
- jira: `jira-cli` recommended, or manual input

## Processing

### 1. Validate

Get work from state.json. Error if `source.type` is not `"local"`. Require `01_KICKOFF.md` exists.

### 2. Extract Kickoff Info

From `01_KICKOFF.md`: Title (from state.json), Goal section, Success Criteria section.

### 3. Create External Issue

**GitHub:**
- Create issue via `gh issue create` with title, body (Goal + Success Criteria + local workflow reference)
- Auto-assign label from work type: FEAT→enhancement, FIX→bug, RFC→rfc
- Extract issue number/URL from result

**Jira:**
- Get project/domain from `.wf/config.json` or `JIRA_PROJECT`/`JIRA_DOMAIN` env vars
- Create via `jira-cli` if available, otherwise prompt for manual creation
- Record ticket ID and URL

### 4. Update state.json

Update `source`: set type to github/jira, record id, url, `promoted_from: "local"`, `promoted_at` timestamp.

### 5. Update 01_KICKOFF.md

Update Issue reference line in header.

### 6. Optional: Rename Work-ID

Ask user if they want to update work-id to include the issue number (e.g., `FEAT-myid-...` → `FEAT-123-...`).
If yes: rename docs directory, update state.json key, optionally rename git branch.

### 7. Commit

`docs(wf): promote <work-id> to <target_type>`

## Notes

- Only works with `source.type: "local"` workflows
- Preserves existing kickoff content
- Records promotion history in state.json
- GitHub labels auto-assigned by work type
