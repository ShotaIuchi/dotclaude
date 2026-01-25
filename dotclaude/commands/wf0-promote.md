---
description: Promote local workflow to GitHub Issue or Jira
argument-hint: "[github | jira] [work-id]"
---

# /wf0-promote

Promote a local workflow to GitHub Issue or Jira ticket.

## Usage

```
/wf0-promote github [work-id]
/wf0-promote jira [work-id]
```

## Arguments

- `github`: Create GitHub Issue from local workflow
- `jira`: Create Jira ticket from local workflow
- `work-id`: (Optional) Target work-id. Uses active work if omitted.

## Prerequisites

```bash
# For GitHub
command -v gh >/dev/null || echo "ERROR: gh is required"
gh auth status || echo "ERROR: Please run gh auth login"

# For Jira (if configured)
# Requires Jira CLI or API token in config
```

## Processing

### 1. Validate Current Work

```bash
work_id="${ARG_WORK_ID:-$(jq -r '.active_work // empty' .wf/state.json)}"

if [ -z "$work_id" ]; then
  echo "ERROR: No active work. Specify work-id or run /wf1-kickoff first."
  exit 1
fi

# Check source type
source_type=$(jq -r ".works[\"$work_id\"].source.type" .wf/state.json)

if [ "$source_type" != "local" ]; then
  echo "ERROR: Work '$work_id' is already linked to $source_type"
  echo "Current source: $(jq -r ".works[\"$work_id\"].source.id" .wf/state.json)"
  exit 1
fi
```

### 2. Load Kickoff Information

```bash
kickoff_path="docs/wf/$work_id/00_KICKOFF.md"

if [ ! -f "$kickoff_path" ]; then
  echo "ERROR: Kickoff not found: $kickoff_path"
  exit 1
fi
```

Extract from `00_KICKOFF.md`:
- **Title**: From work source title in state.json
- **Goal**: From Goal section
- **Success Criteria**: From Success Criteria section
- **Body**: Compile Goal + Success Criteria + Constraints + link to local docs

### 3. Promote to GitHub Issue

```bash
# Get title from state.json
title=$(jq -r ".works[\"$work_id\"].source.title" .wf/state.json)

# Get type for label
work_type=$(echo "$work_id" | cut -d'-' -f1)
case "$work_type" in
  FEAT) label="enhancement" ;;
  FIX)  label="bug" ;;
  RFC)  label="rfc" ;;
  *)    label="" ;;
esac

# Create issue body from kickoff
body=$(cat <<EOF
## Goal

$(sed -n '/^## Goal/,/^## /p' "$kickoff_path" | sed '1d;$d')

## Success Criteria

$(sed -n '/^## Success Criteria/,/^## /p' "$kickoff_path" | sed '1d;$d')

---
📁 Local workflow: \`$work_id\`
EOF
)

# Create GitHub Issue
if [ -n "$label" ]; then
  result=$(gh issue create --title "$title" --body "$body" --label "$label")
else
  result=$(gh issue create --title "$title" --body "$body")
fi

# Extract issue number and URL
issue_url="$result"
issue_number=$(echo "$result" | grep -oE '[0-9]+$')
```

### 4. Promote to Jira

```bash
# Get Jira configuration
jira_project=$(jq -r '.jira.project // empty' .wf/config.json)

if [ -z "$jira_project" ]; then
  echo "Jira project not configured."
  echo "Enter Jira project key (e.g., ABC):"
  read jira_project
fi

# Get title and description
title=$(jq -r ".works[\"$work_id\"].source.title" .wf/state.json)
description="Goal: $(sed -n '/^## Goal/,/^## /p' "$kickoff_path" | sed '1d;$d')"

# Create Jira ticket (using jira-cli or API)
# This is a placeholder - actual implementation depends on Jira setup
echo "Creating Jira ticket in project $jira_project..."
echo "Title: $title"
echo "Description: $description"

# If using jira-cli:
# jira_id=$(jira issue create -p "$jira_project" -t Task -s "$title" -b "$description" --no-input)

# Prompt for manual creation if no CLI
echo ""
echo "Please create the Jira ticket manually and enter the ticket ID:"
read jira_id

jira_url="https://your-domain.atlassian.net/browse/$jira_id"
```

### 5. Update state.json

```bash
# For GitHub
jq --arg id "$issue_number" \
   --arg url "$issue_url" \
   --arg old_type "local" \
   ".works[\"$work_id\"].source = {
     type: \"github\",
     id: \$id,
     title: .works[\"$work_id\"].source.title,
     url: \$url,
     promoted_from: \$old_type,
     promoted_at: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
   }" .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json

# For Jira
jq --arg id "$jira_id" \
   --arg url "$jira_url" \
   --arg old_type "local" \
   ".works[\"$work_id\"].source = {
     type: \"jira\",
     id: \$id,
     title: .works[\"$work_id\"].source.title,
     url: \$url,
     promoted_from: \$old_type,
     promoted_at: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
   }" .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json
```

### 6. Update 00_KICKOFF.md Header

Update the Issue reference in kickoff:

```bash
# For GitHub
sed -i '' "s|^> Issue:.*|> Issue: #$issue_number|" "$kickoff_path"

# For Jira
sed -i '' "s|^> Issue:.*|> Issue: $jira_id|" "$kickoff_path"
```

### 7. Optionally Rename Work-ID

Ask user if they want to update work-id to include the issue number:

```
Work-ID を更新しますか？

現在: FEAT-myid-add-feature
提案: FEAT-123-add-feature (GitHub Issue #123)

1. はい、更新する
2. いいえ、現在のままにする
```

If yes:
1. Generate new work-id with issue number
2. Rename `docs/wf/<old-work-id>/` to `docs/wf/<new-work-id>/`
3. Update state.json (rename key in works, update active_work)
4. Update git branch name (optional, with user confirmation)

### 8. Commit Changes

```bash
git add .wf/state.json "$kickoff_path"
git commit -m "docs(wf): promote $work_id to $target_type

Promoted to: $target_type $target_id
URL: $target_url
"
```

### 9. Completion Message

```
✅ Workflow promoted successfully

Work ID: <work-id>
Promoted to: GitHub Issue #123 / Jira ABC-456
URL: <issue_url>

The local workflow is now linked to the external issue.
All future updates will reference this issue.
```

## Notes

- Only works with `source.type: "local"` workflows
- Preserves all existing kickoff content
- Records promotion history in state.json (`promoted_from`, `promoted_at`)
- GitHub labels are auto-assigned based on work type (FEAT→enhancement, FIX→bug)
- Jira requires project configuration or manual input
