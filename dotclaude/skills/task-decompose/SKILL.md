---
name: task-decompose
description: >
  JIRA・GitHub Issueをサブタスクに分解するスキル。
  「タスク分解」「サブタスクに分割」「チケット分解」「issue分解」「タスクを細分化」
  「ブレイクダウン」「breakdown」「decompose」等で起動する。
  タスクURLを引数に渡すと、仕様の十分性を評価し、サブタスクに分解して作成する。
argument-hint: <task URL: JIRA issue URL or GitHub Issue URL>
---

# task-decompose: Task Decomposition into Subtasks

Takes a JIRA or GitHub Issue and breaks it down into implementation-ready subtasks. Each subtask targets one commit (one PR) worth of work. If the source task's specification is insufficient for decomposition, proposes updates to the source task first and asks for user approval before proceeding.

## Step 1 — Parse Input and Fetch Task

Parse `$ARGUMENTS` to identify the task source:

| Input Pattern | Platform | Action |
|---------------|----------|--------|
| `*.atlassian.net/browse/PROJ-123` | JIRA | Extract cloudId (site URL) and issue key |
| `*.atlassian.net/jira/*/PROJ-123` | JIRA | Extract cloudId (site URL) and issue key |
| `github.com/owner/repo/issues/N` | GitHub | Extract owner, repo, issue number |
| `PROJ-123` (no URL) | JIRA | Ask user for the site URL, then fetch |
| `owner/repo#N` or `#N` | GitHub | Use `gh` CLI to fetch |

### Fetching the task

**JIRA**: Use `mcp__claude_ai_Atlassian__getJiraIssue` with `responseContentFormat: "markdown"` to get the issue details in readable format. Also fetch the project's issue types with `mcp__claude_ai_Atlassian__getJiraProjectIssueTypesMetadata` to know what subtask type names are available (these vary by project — e.g., "Subtask", "Sub-task", "サブタスク").

**GitHub**: Use `gh issue view <number> --repo <owner/repo> --json title,body,labels,assignees,milestone` to get the issue details.

## Step 2 — Assess Specification Sufficiency

A task is ready for decomposition when it has enough detail to determine concrete implementation steps. Evaluate the specification against these criteria:

### Required for decomposition
- **Goal**: What the task achieves is clearly stated
- **Scope**: What is in-scope and out-of-scope is identifiable
- **Acceptance criteria**: How to verify completion is defined or inferable

### Signs of insufficient specification
- The description is a single sentence with no elaboration
- Key behaviors are ambiguous (e.g., "handle errors appropriately" without specifics)
- Technical approach is referenced but not explained
- Dependencies or preconditions are mentioned but unclear
- Multiple valid interpretations exist with no way to choose between them

### If specification is sufficient
Proceed to Step 3.

### If specification is insufficient

1. **Identify the gaps** — list what's missing or ambiguous
2. **Draft an updated description** that fills those gaps with reasonable proposals
3. **Present the update to the user** in this format:

```markdown
## Specification Gaps Found

The following information is missing or ambiguous:
- [Gap 1]: [Why this matters for decomposition]
- [Gap 2]: [Why this matters for decomposition]

## Proposed Updated Description

[Full updated description with gaps filled in, clearly marking additions]

---
Shall I update the task with this description? (You can also edit the proposed text before I apply it.)
```

4. **Wait for user approval.** Do not proceed until the user confirms.
5. **Apply the update:**
   - **JIRA**: Use `mcp__claude_ai_Atlassian__editJiraIssue` with `contentFormat: "markdown"`
   - **GitHub**: Use `gh issue edit <number> --repo <owner/repo> --body <updated body>`

After updating, proceed to Step 3 using the updated specification.

## Step 3 — Decompose into Subtasks

Break the task down into subtasks where each subtask represents roughly **one commit / one PR** of work. This is the default granularity — if the user specified a different granularity in the arguments or conversation, use that instead.

### Decomposition principles

- **Sequential dependencies**: Order subtasks so each builds on the previous. If task B depends on task A's output, A comes first.
- **Independently testable**: Each subtask should produce a verifiable result — a test passes, an endpoint responds, a UI element renders.
- **Atomic scope**: One subtask should not mix unrelated concerns (e.g., don't combine "add database migration" with "update frontend component" unless they're trivially coupled).
- **Clear boundaries**: The description of each subtask should make it obvious where the work starts and stops.

### What each subtask needs

| Field | Content |
|-------|---------|
| Title | Action-oriented summary (e.g., "Add user validation middleware") |
| Description | What to implement, key files/areas to touch, acceptance criteria |
| Order | Sequence number indicating dependency order |

### Exploring the codebase

To produce accurate subtasks, you often need to understand the existing code structure. Use the Agent tool (subagent_type: `Explore`) to investigate the codebase when:
- The task references existing modules, APIs, or components
- You need to understand the current architecture to plan changes
- File paths or component names need to be identified

This exploration helps produce subtasks with concrete file references and realistic scope rather than vague descriptions.

## Step 4 — Present Subtask Plan

Present the decomposition for user review:

```markdown
# Task Decomposition: [Original Task Title]

Source: [URL]

## Subtasks (N items)

### 1. [Subtask Title]
**Scope**: [What this subtask covers]
**Key files**: [Files likely to be touched, if identifiable]
**Acceptance criteria**:
- [Criterion 1]
- [Criterion 2]
**Depends on**: — (none, or list predecessor subtask numbers)

### 2. [Subtask Title]
**Scope**: ...
**Key files**: ...
**Acceptance criteria**: ...
**Depends on**: #1

...

---
Shall I create these subtasks? You can also ask me to adjust the breakdown first.
```

**Wait for user approval.** The user may want to:
- Merge or split subtasks
- Reorder them
- Add or remove items
- Change descriptions

Incorporate all feedback before proceeding.

## Step 5 — Create Subtasks

Once approved, create the subtasks on the appropriate platform.

### JIRA

Use `mcp__claude_ai_Atlassian__createJiraIssue` for each subtask:

- `cloudId`: The site URL extracted from the original issue
- `projectKey`: Same project as the parent issue
- `issueTypeName`: Use the subtask type name discovered in Step 1 (from project metadata)
- `parent`: The original issue key (e.g., "PROJ-123")
- `summary`: Subtask title
- `description`: Full subtask description with acceptance criteria
- `contentFormat`: "markdown"

Create subtasks sequentially in dependency order so the issue numbers reflect the intended sequence.

### GitHub

Use `gh issue create` for each subtask:

```bash
gh issue create \
  --repo <owner/repo> \
  --title "[Parent#N] Subtask title" \
  --body "Parent: #N\nDepends on: #X\n\n<description>"
```

After creating all subtasks, add a comment to the parent issue listing the created subtasks:

```bash
gh issue comment <parent-number> --repo <owner/repo> \
  --body "## Subtasks\n- [ ] #A Subtask 1\n- [ ] #B Subtask 2\n..."
```

This creates a checklist on the parent issue for tracking progress.

## Step 6 — Summary

Report what was created:

```markdown
# Decomposition Complete

**Source**: [Original task URL]
**Subtasks created**: N

| # | Key/Number | Title | Depends on |
|---|-----------|-------|------------|
| 1 | PROJ-124 / #45 | Add user validation middleware | — |
| 2 | PROJ-125 / #46 | Implement auth endpoint | #1 |
| 3 | PROJ-126 / #47 | Add integration tests | #2 |
```

## Tips

- For large tasks that decompose into more than 8-10 subtasks, consider whether the task itself should be an Epic with Stories rather than a Task with Subtasks. Mention this to the user if applicable.
- If the codebase is available locally, exploring it produces much better subtask descriptions with concrete file paths and component names.
- When creating JIRA subtasks, the `parent` field links them directly to the parent issue. For GitHub, the parent-child relationship is maintained through references in the issue body and the checklist comment.
