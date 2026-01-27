---
name: wf0-promote
description: Promote local workflow to GitHub Issue or Jira
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
# Recommended: jira-cli (https://github.com/ankitpokhrel/jira-cli)
# Install: brew install ankitpokhrel/jira-cli/jira-cli
# Setup: jira init
# Alternatively: Configure API token in .wf/config.json
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
# Note: Using awk for cross-platform compatibility (sed -i differs between macOS and Linux)
extract_section() {
  local file="$1"
  local section="$2"
  awk "/^## $section/,/^## /" "$file" | sed '1d;$d'
}

body=$(cat <<EOF
## Goal

$(extract_section "$kickoff_path" "Goal")

## Success Criteria

$(extract_section "$kickoff_path" "Success Criteria")

---
Local workflow: \`$work_id\`
EOF
)

# Create GitHub Issue with error handling
if [ -n "$label" ]; then
  result=$(gh issue create --title "$title" --body "$body" --label "$label" 2>&1) || {
    echo "ERROR: Failed to create GitHub Issue"
    echo "$result"
    exit 1
  }
else
  result=$(gh issue create --title "$title" --body "$body" 2>&1) || {
    echo "ERROR: Failed to create GitHub Issue"
    echo "$result"
    exit 1
  }
fi

# Validate result
if [ -z "$result" ] || ! echo "$result" | grep -qE 'https://'; then
  echo "ERROR: Unexpected response from gh issue create"
  echo "Response: $result"
  exit 1
fi

# Extract issue number and URL
issue_url="$result"
issue_number=$(echo "$result" | grep -oE '[0-9]+$')
```

### 4. Promote to Jira

```bash
# Get Jira configuration from config file or environment
jira_project="${JIRA_PROJECT:-$(jq -r '.jira.project // empty' .wf/config.json 2>/dev/null)}"
jira_domain="${JIRA_DOMAIN:-$(jq -r '.jira.domain // empty' .wf/config.json 2>/dev/null)}"

# Fallback to interactive input only if not in CI and no config
if [ -z "$jira_project" ]; then
  if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    echo "ERROR: Jira project not configured. Set JIRA_PROJECT environment variable or .wf/config.json"
    exit 1
  fi
  echo "Jira project not configured."
  echo "Enter Jira project key (e.g., ABC):"
  read jira_project
fi

if [ -z "$jira_domain" ]; then
  if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    echo "ERROR: Jira domain not configured. Set JIRA_DOMAIN environment variable or .wf/config.json"
    exit 1
  fi
  echo "Enter Jira domain (e.g., your-company.atlassian.net):"
  read jira_domain
fi

# Get title and description
title=$(jq -r ".works[\"$work_id\"].source.title" .wf/state.json)
description="Goal: $(extract_section "$kickoff_path" "Goal")"

# Create Jira ticket (using jira-cli or API)
# NOTE: Jira integration is partially implemented. Full support planned for future release.
echo "Creating Jira ticket in project $jira_project..."
echo "Title: $title"
echo "Description: $description"

# Check if jira-cli is available
if command -v jira >/dev/null 2>&1; then
  jira_id=$(jira issue create -p "$jira_project" -t Task -s "$title" -b "$description" --no-input 2>&1) || {
    echo "ERROR: Failed to create Jira ticket: $jira_id"
    exit 1
  }
else
  # Prompt for manual creation if no CLI (non-CI only)
  if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    echo "ERROR: jira-cli not found and running in CI. Install jira-cli or configure API."
    exit 1
  fi
  echo ""
  echo "Please create the Jira ticket manually and enter the ticket ID:"
  read jira_id
fi

jira_url="https://$jira_domain/browse/$jira_id"
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
# Cross-platform sed -i implementation
sed_inplace() {
  local file="$1"
  local pattern="$2"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$pattern" "$file"
  else
    sed -i "$pattern" "$file"
  fi
}

# For GitHub
sed_inplace "$kickoff_path" "s|^> Issue:.*|> Issue: #$issue_number|"

# For Jira
sed_inplace "$kickoff_path" "s|^> Issue:.*|> Issue: $jira_id|"
```

### 7. Optionally Rename Work-ID

Ask user if they want to update work-id to include the issue number:

```
Do you want to update the Work-ID?

Current: FEAT-myid-add-feature
Proposed: FEAT-123-add-feature (GitHub Issue #123)

1. Yes, update it
2. No, keep current
```

If yes, execute the following steps:

```bash
# Generate new work-id
old_work_id="$work_id"
work_type=$(echo "$work_id" | cut -d'-' -f1)
work_suffix=$(echo "$work_id" | cut -d'-' -f3-)
new_work_id="${work_type}-${issue_number}-${work_suffix}"

# 1. Rename workflow directory
if [ -d "docs/wf/$old_work_id" ]; then
  mv "docs/wf/$old_work_id" "docs/wf/$new_work_id"
fi

# 2. Update state.json (rename key in works, update active_work)
jq --arg old "$old_work_id" --arg new "$new_work_id" '
  .works[$new] = .works[$old] |
  del(.works[$old]) |
  if .active_work == $old then .active_work = $new else . end
' .wf/state.json > .wf/state.json.tmp && mv .wf/state.json.tmp .wf/state.json

# 3. Update git branch name (with user confirmation)
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$current_branch" = "$old_work_id" ]; then
  echo "Current git branch matches old work-id."
  echo "Rename branch to '$new_work_id'? (y/N)"
  read -r confirm
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    git branch -m "$old_work_id" "$new_work_id"
    echo "Branch renamed to: $new_work_id"
  fi
fi

work_id="$new_work_id"
kickoff_path="docs/wf/$work_id/00_KICKOFF.md"
```

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
Workflow promoted successfully

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
- GitHub labels are auto-assigned based on work type (FEAT->enhancement, FIX->bug)
- Jira requires project configuration or manual input
