# /wf1-kickoff

Command to create or update the Kickoff document.

## Usage

```
/wf1-kickoff [subcommand] [options]
```

## Subcommands

- `(none)`: Create new or confirm in interactive mode
- `update`: Update existing Kickoff
- `revise "<instruction>"`: Revise based on instruction
- `chat`: Brainstorming dialogue mode

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Check Current Work Status

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
if [ -z "$work_id" ]; then
  echo "No active work"
  echo "Please run /wf0-workspace or /wf0-restore"
  exit 1
fi

docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
revisions_path="$docs_dir/05_REVISIONS.md"
```

### 2. Get Source Information

Extract Issue number from work-id and get information:

```bash
# Get source type from state.json
source_type=$(jq -r ".works[\"$work_id\"].source.type" .wf/state.json)

if [ "$source_type" = "github" ]; then
  # Extract issue number using regex that handles various prefixes
  # Pattern: <TYPE>-<number>-<slug> where TYPE can be any alphanumeric string
  issue_number=$(echo "$work_id" | grep -oE '[0-9]+' | head -1)
  if [ -z "$issue_number" ]; then
    echo "ERROR: Could not extract issue number from work-id: $work_id"
    exit 1
  fi
  gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone

elif [ "$source_type" = "jira" ]; then
  # For Jira, get info from state.json (Jira API access would require separate config)
  source_id=$(jq -r ".works[\"$work_id\"].source.id" .wf/state.json)
  source_title=$(jq -r ".works[\"$work_id\"].source.title" .wf/state.json)
  source_url=$(jq -r ".works[\"$work_id\"].source.url // empty" .wf/state.json)
  echo "Jira ticket: $source_id - $source_title"
  [ -n "$source_url" ] && echo "URL: $source_url"

elif [ "$source_type" = "local" ]; then
  # For local, use info from state.json
  source_id=$(jq -r ".works[\"$work_id\"].source.id" .wf/state.json)
  source_title=$(jq -r ".works[\"$work_id\"].source.title" .wf/state.json)
  echo "Local work: $source_id - $source_title"
fi
```

### 3. Subcommand-Specific Processing

#### New Creation (no subcommand)

1. Analyze Issue content
2. Dialogue with user to confirm:
   - Goal
   - Success Criteria
   - Constraints
   - Non-goals
   - Dependencies

3. Create `00_KICKOFF.md`

**Template reference:** Load and use `~/.claude/templates/00_KICKOFF.md`.

Replace template placeholders with content determined through dialogue.

#### update

1. Load current `00_KICKOFF.md`
2. Dialogue with user to confirm changes
3. Update `00_KICKOFF.md`
4. Append history to `05_REVISIONS.md`
   - **Template reference:** Load and use `~/.claude/templates/05_REVISIONS.md`
5. Increment `kickoff.revision` in state.json

#### revise "<instruction>"

1. Load current `00_KICKOFF.md`
2. Auto-revise based on instruction
3. Confirm changes with user
4. Update if approved
5. Append history to `05_REVISIONS.md`

#### chat

1. Load current `00_KICKOFF.md` (if exists)
2. Display Issue information
3. Free dialogue mode for questions and discussion
4. Dialogue content can be reflected in Notes section

### 4. Update state.json

```bash
# Update current
jq ".works[\"$work_id\"].current = \"wf1-kickoff\"" .wf/state.json > tmp && mv tmp .wf/state.json

# Update next after completion
jq ".works[\"$work_id\"].next = \"wf2-spec\"" .wf/state.json > tmp && mv tmp .wf/state.json

# Update kickoff information
jq ".works[\"$work_id\"].kickoff.revision = <new_revision>" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].kickoff.last_updated = \"<timestamp>\"" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 5. Commit

Commit Kickoff document changes:

```bash
# For new creation
git add "$kickoff_path" .wf/state.json
git commit -m "docs(wf): create kickoff <work-id>

Work: <work-id>
"

# For update/revise
git add "$kickoff_path" "$revisions_path" .wf/state.json
git commit -m "docs(wf): update kickoff <work-id>

Revision: <new_revision>
Work: <work-id>
"
```

### 6. Brainstorming Dialogue Guide

When creating Kickoff, dialogue with user on the following aspects:

**About Goal:**
- What do you want to achieve with this work?
- Why is this feature/fix needed?
- What value does it provide to users?

**About Success Criteria:**
- What conditions indicate completion?
- How will you measure success?
- What is the minimum that must be achieved?

**About Constraints:**
- Are there technical constraints?
- Are there performance requirements?
- Are there compatibility requirements?

**About Non-goals:**
- What will not be addressed this time?
- What will be left as future work?

**About Dependencies:**
- Does this depend on other work?
- Are there dependencies on external services or APIs?

### 7. Completion Message

```
✅ Kickoff document created

File: docs/wf/<work-id>/00_KICKOFF.md
Revision: 1

Next step: Run /wf2-spec to create the specification
```

## Notes

- Always confirm before overwriting existing content
- Always maintain Revision history
- Check for contradictions with Issue content
