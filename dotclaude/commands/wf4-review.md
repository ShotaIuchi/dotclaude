# /wf4-review

Command to create review records. Used for Plan review or code review after implementation.

## Usage

```
/wf4-review [subcommand]
```

## Subcommands

- `(none)` or `plan`: Review the Plan
- `code`: Review implementation code
- `pr`: Check and review PR status

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Check Prerequisites

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
review_path="$docs_dir/03_REVIEW.md"
```

### 2. Plan Review (Default)

Review Plan content from the following perspectives:

**Checklist:**

1. **Completeness**
   - [ ] All Spec requirements are covered
   - [ ] Test plan is included
   - [ ] Rollback procedure is clear

2. **Feasibility**
   - [ ] Work volume for each step is reasonable
   - [ ] Dependencies are correct
   - [ ] Risks are properly assessed

3. **Quality**
   - [ ] Coding conventions compliance is considered
   - [ ] Performance impact is examined
   - [ ] Security is considered

Record review results in `03_REVIEW.md`:

**Template reference:** Load and use `~/.claude/templates/03_REVIEW.md`.

Replace template placeholders with review results.

### 3. Code Review

Review implemented code:

```bash
# Get base branch from state.json
base_branch=$(jq -r ".works[\"$work_id\"].git.base" .wf/state.json)

# Check changed files
git diff "$base_branch"...HEAD --name-only

# Check diff
git diff "$base_branch"...HEAD
```

Review perspectives:
- Code style
- Error handling
- Test coverage
- Security
- Performance

### 4. PR Review

Check GitHub PR status:

```bash
branch=$(jq -r ".works[\"$work_id\"].git.branch" .wf/state.json)
gh pr view --json number,state,reviews,checks
```

Display:
```
📋 PR Review Status: <work-id>
═══════════════════════════════════════

PR: #<number> - <title>
State: <open/closed/merged>

Checks:
- [✓] CI/CD Pipeline
- [✓] Code Coverage
- [→] Security Scan (running)

Reviews:
- @reviewer1: Approved
- @reviewer2: Changes Requested

Comments: 5

Blocking Issues:
- Security Scan has not completed

Next Action:
- Please wait for Security Scan to complete
```

### 5. Update state.json

```bash
# When review is complete
jq ".works[\"$work_id\"].current = \"wf4-review\"" .wf/state.json > tmp && mv tmp .wf/state.json

# If approved
jq ".works[\"$work_id\"].next = \"wf5-implement\"" .wf/state.json > tmp && mv tmp .wf/state.json

# If changes requested
jq ".works[\"$work_id\"].next = \"wf3-plan\"" .wf/state.json > tmp && mv tmp .wf/state.json

# If needs discussion
jq ".works[\"$work_id\"].next = \"wf4-review\"" .wf/state.json > tmp && mv tmp .wf/state.json
# Note: "Needs Discussion" keeps next as wf4-review, requiring another review after discussion
```

### 6. Completion Message

```
✅ Review complete

File: docs/wf/<work-id>/03_REVIEW.md

Result: <Approved / Request Changes / Needs Discussion>

Findings:
- Must Fix: 1
- Should Fix: 2
- Suggestions: 3

Next step:
- Approved: Run /wf5-implement
- Request Changes: Fix issues and run /wf4-review again
```

## Notes

- Always record review results
- Treat Must Fix items as mandatory to resolve
- Record reviewer names
- Keep history for multiple reviews
