---
description: Create a new workspace and Kickoff document
argument-hint: "github=<n> | jira=<id> | local=<id> [update | revise \"<instruction>\" | chat]"
---

# /wf1-kickoff

Command to create a new workspace and Kickoff document in one step.

## Usage

```
/wf1-kickoff github=<number>
/wf1-kickoff jira=<jira-id> [title="title"]
/wf1-kickoff local=<id> title="title" [type=<TYPE>]
/wf1-kickoff [update | revise "<instruction>" | chat]
```

## Arguments

### Source Arguments (for new workspace)

Specify one of the following (mutually exclusive):

- `github`: GitHub Issue number
- `jira`: Jira ticket ID (e.g., `ABC-123`)
- `local`: Local ID (arbitrary string)

Optional arguments:

- `title`: Title (required for jira/local, ignored for github)
- `type`: Work type (local only. FEAT/FIX/REFACTOR/CHORE/RFC. Default: FEAT)

### Subcommands (for existing workspace)

- `(none)`: Create new workspace and Kickoff
- `update`: Update existing Kickoff
- `revise "<instruction>"`: Revise based on instruction
- `chat`: Brainstorming dialogue mode

## Processing

Parse $ARGUMENTS and execute the following processing.

### Phase 1: Workspace Setup (for new workspace)

#### 1. Check Prerequisites

```bash
# Check if jq is available
command -v jq >/dev/null || echo "ERROR: jq is required"

# Check gh only for github mode
if [ -n "$github" ]; then
  command -v gh >/dev/null || echo "ERROR: gh is required"
  gh auth status || echo "ERROR: Please run gh auth login"
fi
```

#### 2. Get ID Information and Generate work-id

##### 2a. For github mode

```bash
gh issue view <issue_number> --json number,title,labels,body,url
```

Determine from the retrieved information:
- **TYPE**: Determine from labels (feature/enhancement→FEAT, bug→FIX, refactor→REFACTOR, chore→CHORE, rfc→RFC)
- **slug**: Generate from title (lowercase, alphanumeric and hyphens only, max 40 characters)
- **work-id**: `<TYPE>-<issue>-<slug>` format

##### 2b. For jira mode

- **TYPE**: Use Jira ID prefix as-is, or infer from title
- **slug**: Generate from title (lowercase, alphanumeric and hyphens only, max 40 characters)
- **work-id**: `JIRA-<jira-id>-<slug>` format (e.g., `JIRA-ABC-123-add-login`)

##### 2c. For local mode

- **TYPE**: Specified in argument (default: FEAT)
- **slug**: Generate from title (lowercase, alphanumeric and hyphens only, max 40 characters)
- **work-id**: `<TYPE>-<local-id>-<slug>` format (e.g., `FEAT-myid-add-feature`)

##### 2d. Ask for Issue/Jira Creation (local mode only)

After determining work-id in local mode, ask user:

```
ローカルワークフローを作成します。
外部システムにも作成しますか？

1. ローカルのみ (後で /wf0-promote で昇格可能)
2. GitHub Issue も作成
3. Jira チケットも作成
```

**If user selects GitHub Issue:**

1. Create GitHub Issue using `gh issue create`:
   ```bash
   gh issue create \
     --title "<title>" \
     --body "Created from local workflow: <work-id>" \
     --label "<type-label>"
   ```
2. Get created issue number from output
3. Update source info:
   ```json
   {
     "source": {
       "type": "github",
       "id": "<issue_number>",
       "title": "<title>",
       "url": "<issue_url>",
       "promoted_from": "local"
     }
   }
   ```
4. Optionally update work-id to include issue number: `<TYPE>-<issue>-<slug>`

**If user selects Jira:**

1. Prompt for Jira project key (e.g., `ABC`)
2. Create Jira ticket using jira-cli or API (see `/wf0-promote` Prerequisites for setup)
3. Update source info with Jira details

**If user selects local only:**

Continue with local source type. Can be promoted later with `/wf0-promote`.

#### 3. Select Base Branch

Use `default_base_branch` from `.wf/config.json` as default.
Use `main` if not present.

Confirm with user:
> Base branch: Is `<branch>` OK?

#### 4. Create Work Branch

```bash
# Branch name: <prefix>/<issue>-<slug>
git checkout -b <branch_name> <base_branch>
```

#### 5. Initialize WF Directory

Create `.wf/` directory if it doesn't exist:

```bash
source "$HOME/.claude/scripts/wf-init.sh"
wf_init_project
```

#### 6. Create Document Directory

```bash
mkdir -p docs/wf/<work-id>/
```

### Phase 2: Kickoff Creation

#### 7. Get Source Information

Extract Issue number from work-id and get information:

```bash
# Get source type from state.json
source_type=$(jq -r ".works[\"$work_id\"].source.type" .wf/state.json)

if [ "$source_type" = "github" ]; then
  # Extract issue number from state.json (most reliable source)
  issue_number=$(jq -r ".works[\"$work_id\"].source.id" .wf/state.json)

  # Fallback: Extract from work-id if not in state.json
  # Pattern: <TYPE>-<number>-<slug> where TYPE can be FEAT, FIX, etc.
  # Note: For JIRA-prefixed work-ids, use the Jira source type instead
  if [ -z "$issue_number" ] || [ "$issue_number" = "null" ]; then
    # Extract the second segment which should be the issue number
    issue_number=$(echo "$work_id" | cut -d'-' -f2)
    # Validate it's a number
    if ! echo "$issue_number" | grep -qE '^[0-9]+$'; then
      echo "ERROR: Could not extract issue number from work-id: $work_id"
      echo "Hint: Ensure work-id follows <TYPE>-<number>-<slug> format for GitHub source"
      exit 1
    fi
  fi
  gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone

elif [ "$source_type" = "jira" ]; then
  # For Jira, get info from state.json
  # Note: For Jira CLI setup and configuration, see /wf0-promote Prerequisites section
  # Recommended: jira-cli (https://github.com/ankitpokhrel/jira-cli)
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
  # For Plan Mode processing, see section 7.1
fi
```

#### 7.1. Plan Mode for Local Work (source_type = "local")

When source_type is "local" and creating a new Kickoff (no existing `00_KICKOFF.md`), use Plan Mode to explore requirements interactively.

> **Note**: Plan Mode uses Claude Code's built-in planning feature. When entering Plan Mode, Claude will engage in an interactive dialogue to explore requirements without making changes. This is particularly useful for local workflows where there is no pre-existing Issue or ticket to reference. The `EnterPlanMode` and `ExitPlanMode` tools are internal to Claude Code and automatically manage the planning state.

**Plan file path:**
```
.wf/<work-id>/plan.md
```

##### Flow

1. **Check for existing plan.md**
   - If `plan.md` exists → Proceed to step 4 (use as Kickoff input)
   - If `plan.md` does not exist → Continue to step 2

2. **Enter Plan Mode**
   - Start the planning session
   - Display the work title and any available context
   - Guide user through requirements exploration:
     - What problem are you solving?
     - What is the desired outcome?
     - What constraints exist?
     - What is out of scope?
     - What dependencies exist?

3. **Create plan.md**
   - After Plan Mode dialogue, save the plan to `.wf/<work-id>/plan.md`
   - Format:
     ```markdown
     # Plan: <work-title>

     ## Problem Statement
     <what problem we're solving>

     ## Goals
     <desired outcomes>

     ## Constraints
     <technical/business constraints>

     ## Non-Goals
     <explicitly out of scope>

     ## Dependencies
     <dependencies on other work, external services, or APIs>

     ## Approach
     <high-level approach discussed>

     ## Open Questions
     <unresolved questions, if any>
     ```
   - Exit Plan Mode to complete the planning phase

4. **Use plan.md as Kickoff input**
   - Read `plan.md` content
   - Map plan sections to Kickoff template sections:
     | plan.md | 00_KICKOFF.md |
     |---------|---------------|
     | Problem Statement | Background |
     | Goals | Goal, Success Criteria |
     | Constraints | Constraints |
     | Non-Goals | Non-Goals |
     | Dependencies | Dependencies |
     | Approach | Notes |
     | Open Questions | Notes |
   - Proceed to create `00_KICKOFF.md` with this input

##### Skip Plan Mode

To skip Plan Mode for local work, user can:
- Create `plan.md` manually before running `/wf1-kickoff`
- Use `/wf1-kickoff chat` for free-form dialogue instead

#### 8. Brainstorming Dialogue

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

#### 9. Create 00_KICKOFF.md

**Template reference:** Load and use `~/.claude/templates/00_KICKOFF.md`.

Replace template placeholders with content determined through dialogue (or plan.md for local).

### Phase 3: Finalization

#### 10. Update state.json

```json
{
  "active_work": "<work-id>",
  "works": {
    "<work-id>": {
      "current": "wf1-kickoff",
      "next": "wf2-spec",
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
        "revision": 1,
        "last_updated": "<timestamp>"
      },
      "created_at": "<timestamp>"
    }
  }
}
```

#### 11. Commit

Commit workspace and Kickoff:

```bash
git add .wf/state.json docs/wf/<work-id>/
git commit -m "docs(wf): create workspace and kickoff <work-id>

Source: <source_type> #<source_id>
"
```

#### 12. Completion Message

```
✅ Workspace and Kickoff created

Work ID: <work-id>
Branch: <branch_name>
Base: <base_branch>
Docs: docs/wf/<work-id>/

File: docs/wf/<work-id>/00_KICKOFF.md
Revision: 1

Next step: Run /wf2-spec to create the specification
```

## Subcommand Processing (for existing workspace)

### Check Current Work Status

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
if [ -z "$work_id" ]; then
  echo "No active work"
  echo "Please run /wf1-kickoff with github=, jira=, or local= argument"
  exit 1
fi

docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
revisions_path="$docs_dir/05_REVISIONS.md"
```

### update Subcommand

1. Load current `00_KICKOFF.md`
2. Dialogue with user to confirm changes
3. Update `00_KICKOFF.md`
4. Append history to `05_REVISIONS.md`
   - **Template reference:** Load and use `~/.claude/templates/05_REVISIONS.md`
5. Increment `kickoff.revision` in state.json

### revise "<instruction>" Subcommand

1. Load current `00_KICKOFF.md`
2. Auto-revise based on instruction
3. Confirm changes with user
4. Update if approved
5. Append history to `05_REVISIONS.md`

### chat Subcommand

1. Load current `00_KICKOFF.md` (if exists)
2. Display Issue information
3. Free dialogue mode for questions and discussion
4. Dialogue content can be reflected in Notes section

### Subcommand Commit

```bash
# For update/revise
git add "$kickoff_path" "$revisions_path" .wf/state.json
git commit -m "docs(wf): update kickoff <work-id>

Revision: <new_revision>
Work: <work-id>
"
```

**Note on plan.md**: The `.wf/<work-id>/plan.md` file is NOT committed to git. It serves as a temporary working document during the Kickoff creation process and can be deleted after `00_KICKOFF.md` is created.

## Create worktree (Optional)

If `config.worktree.enabled` is `true` in `.wf/config.json`:

```json
// .wf/config.json
{
  "worktree": {
    "enabled": true,
    "base_path": ".worktrees"
  }
}
```

```bash
git worktree add .worktrees/<branch-name> <branch>
```

Record worktree path in `.wf/local.json` (git-ignored, local machine specific):

```json
// .wf/local.json
{
  "worktrees": {
    "<work-id>": ".worktrees/<branch-name>"
  }
}
```

## Error Handling

| Error Scenario | Behavior | Recovery |
|----------------|----------|----------|
| Branch already exists | Display error with existing branch name | Use different slug or delete existing branch |
| GitHub Issue not found | Display error with issue number | Verify issue number and repository |
| Title not specified (jira/local) | Display error prompting for title | Re-run with `title="..."` argument |
| Multiple source types specified | Display error listing conflicting arguments | Re-run with single source type |
| Branch creation fails | Display git error | Check git status, resolve conflicts |
| state.json update fails | Display error, rollback branch creation | Check file permissions, disk space |
| Directory creation fails | Display error | Check permissions on docs/wf/ |
| gh CLI not authenticated | Display auth error | Run `gh auth login` |

## Notes

- Display warning if existing work exists
- Error if branch name already exists
- github mode: Error if Issue not found
- jira/local mode: Error if title is not specified
- github/jira/local are mutually exclusive (error if multiple specified)
- Always confirm before overwriting existing content
- Always maintain Revision history
- Check for contradictions with Issue content
