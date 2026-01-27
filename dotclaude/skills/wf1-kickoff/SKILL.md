---
name: wf1-kickoff
description: Create a new workspace and Kickoff document
argument-hint: "<github=N | jira=ID | local=ID> [title=...] [type=...] [--no-branch]"
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /wf1-kickoff

Create a new workspace and Kickoff document, or update an existing one.

## Usage

```
/wf1-kickoff github=<number> [--no-branch]
/wf1-kickoff jira=<jira-id> [title="title"] [--no-branch]
/wf1-kickoff local=<id> title="title" [type=<TYPE>] [--no-branch]
/wf1-kickoff [update | revise "<instruction>" | chat]
```

## Arguments

### Source (mutually exclusive, for new workspace)

- `github`: GitHub Issue number
- `jira`: Jira ticket ID (e.g., `ABC-123`)
- `local`: Local ID (arbitrary string)
- `title`: Title (required for jira/local)
- `type`: FEAT/FIX/REFACTOR/CHORE/RFC (local only, default: FEAT)
- `--no-branch`: Skip branch creation, use current branch as work branch

### Subcommands (for existing workspace)

- `update`: Update existing Kickoff via dialogue
- `revise "<instruction>"`: Auto-revise based on instruction
- `chat`: Brainstorming dialogue mode

## Processing (New Workspace)

### Phase 1: Workspace Setup

1. **Check prerequisites**: `jq` required. `gh` required for github mode (check `gh auth status`).

2. **Generate work-id**:
   - github: Fetch issue via `gh issue view`. TYPE from labels (enhancement→FEAT, bug→FIX, etc.). Format: `<TYPE>-<issue>-<slug>`
   - jira: Format: `JIRA-<jira-id>-<slug>`
   - local: Format: `<TYPE>-<local-id>-<slug>`. Ask if user also wants to create GitHub Issue/Jira (can promote later with `/wf0-promote`).
   - slug: lowercase, alphanumeric+hyphens, max 40 chars

3. **Select base branch**: Priority: current branch (default) > `default_base_branch` from `.wf/config.json` > `main`. Confirm with user.

4. **Create work branch**:
   > **CRITICAL**: Working on main/master directly is forbidden. All work MUST happen on a feature branch.

   **If `--no-branch` is specified:**
   - Skip branch creation. Use the current branch as the work branch.
   - **Verify**: current branch MUST NOT be main/master. If it is, **ABORT** with error "Cannot use --no-branch on main/master".
   - Record the current branch name as `git.branch`.

   **Otherwise (default):**
   - `git checkout -b <prefix>/<issue>-<slug> <base_branch>`
   - **Verify immediately**: if still on main/master, **ABORT entire process**.

5. **Initialize WF directory**: Run `source "$HOME/.claude/scripts/wf-init.sh" && wf_init_project`

6. **Early branch recording** (CRITICAL: do NOT defer to Phase 3):
   - Verify again not on main/master
   - Write `git.base` and `git.branch` to state.json immediately

7. **Create document directory**: `mkdir -p docs/wf/<work-id>/`

### Phase 2: Kickoff Creation

8. **Get source information**: Fetch from GitHub/Jira/state.json based on source type.

9. **Plan Mode for local works**: If local and no existing `01_KICKOFF.md`:
   - Check for `.wf/<work-id>/plan.md` (temp working doc, not committed)
   - If absent, enter Plan Mode to explore requirements interactively
   - Save plan, then use as Kickoff input

10. **Brainstorming dialogue**: Discuss Goal, Success Criteria, Constraints, Non-goals, Dependencies with user.

11. **Create 01_KICKOFF.md**: Load template from `~/.claude/templates/01_KICKOFF.md`, fill with dialogue results.

### Phase 3: Finalization

12. **Update state.json**:
    > **GUARD**: Verify `git.branch` is NOT null/main/master before writing. ABORT if so.

    Set: `active_work`, `current: "wf1-kickoff"`, `next: "wf2-spec"`, source info, git info, `kickoff.revision: 1`, `created_at`.

13. **Commit**: `git add .wf/state.json docs/wf/<work-id>/` with message `docs(wf): create workspace and kickoff <work-id>`

14. **Completion message**: Show Work ID, Branch, Base, Docs path, next step (`/wf2-spec`).

## Subcommand Processing (Existing Workspace)

Get active work from state.json. Require `01_KICKOFF.md` exists.

- **update**: Dialogue → update `01_KICKOFF.md` → append to `06_REVISIONS.md` (template: `~/.claude/templates/06_REVISIONS.md`) → increment `kickoff.revision`
- **revise**: Auto-revise from instruction → confirm → update → append revision history
- **chat**: Free dialogue with Issue context. Can reflect in Notes section.
- **Commit**: `docs(wf): update kickoff <work-id>` with revision number.

## Worktree (Optional)

If `config.worktree.enabled` is true: `git worktree add .worktrees/<branch-name> <branch>`. Record in `.wf/local.json`.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Branch already exists | Error with existing branch name |
| GitHub Issue not found | Error with issue number |
| Title missing (jira/local) | Prompt for title |
| Multiple source types | Error listing conflicts |
| Still on main/master at Step 5+ | **ABORT immediately** |
| `--no-branch` on main/master | **ABORT** with error message |

## Agent Reference

This skill delegates to the [research agent](../../agents/workflow/research.md).
