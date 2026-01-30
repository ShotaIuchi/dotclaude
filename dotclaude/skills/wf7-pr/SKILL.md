---
name: wf7-pr
description: PRを作成または更新
argument-hint: "[update]"
---

**Always respond in Japanese.**

# /wf7-pr

Create or update a Pull Request after verification passes.

## Usage

```
/wf7-pr [subcommand]
```

## Subcommands

- `(none)`: Create a new PR
- `update`: Update existing PR (push changes and optionally update description)

## Processing

### 1. Check Prerequisites

Get active work from state.json. Verify current phase is `wf6-verify` or later. Check that verification has passed (no test/build failures recorded).

### 2. Check Existing PR

Query `gh pr view` to check if a PR already exists for the current branch. If exists and no `update` subcommand, inform user and suggest `update`.

### 3. Push Branch

```bash
git push -u origin <branch>
```

Get branch name from state.json.

### 4. Generate PR Title

1. Read Goal from `01_KICKOFF.md`
2. For GitHub source: append `(#<issue_number>)` to link the issue
3. Keep title concise (under 72 characters)

### 5. Create PR (`gh pr create`)

Generate PR body with:

```markdown
## Summary

<1-3 bullet points from Kickoff Goal and Spec>

## Changes

<List of main changes from Plan steps>

## Test Plan

<Testing approach from Spec or verification results>

## Related Issues

Closes #<issue_number>

---
📄 [Kickoff](docs/wf/<work-id>/01_KICKOFF.md) | [Spec](docs/wf/<work-id>/02_SPEC.md) | [Plan](docs/wf/<work-id>/03_PLAN.md)
```

Execute:
```bash
gh pr create --title "<title>" --body "<body>"
```

### 6. Update PR (`update` subcommand)

1. Push latest changes: `git push`
2. Optionally update PR description via `gh pr edit` if significant changes

### 7. Update state.json

```json
{
  "current": "wf7-pr",
  "next": "complete",
  "pr": {
    "number": 123,
    "url": "https://github.com/..."
  }
}
```

### 8. Completion Message

Display:
- PR number and URL
- PR title
- Base ← Branch
- Suggest requesting review

## Error Handling

| Error | Action |
|-------|--------|
| Verification not passed | Instruct to run `/wf6-verify` first |
| PR already exists | Suggest `update` subcommand |
| Push fails | Show error, suggest checking remote status |
| `gh` not authenticated | Instruct `gh auth login` |

## Notes

- Cannot create PR if verification has not passed
- Issue number is automatically linked via `(#N)` in title and `Closes #N` in body
- Existing PR is detected and handled gracefully
