---
name: wf4-review
description: Create review records for Plan or code
argument-hint: "[plan | code | pr]"
---

**Always respond in Japanese.**

# /wf4-review

Create review records for Plan, implementation code, or PR status.

## Usage

```
/wf4-review [subcommand]
```

## Subcommands

- `(none)` or `plan`: Review the Plan
- `code`: Review implementation code
- `pr`: Check and review PR status

## Processing

### 1. Check Prerequisites

Get active work. Set review path: `docs/wf/<work-id>/03_REVIEW.md`.

### 2. Plan Review (Default)

Review Plan from these perspectives:

- **Completeness**: All Spec requirements covered, test plan included, rollback procedure clear
- **Feasibility**: Work volume per step reasonable, dependencies correct, risks assessed
- **Quality**: Coding conventions, performance impact, security

Record in `03_REVIEW.md` using template `~/.claude/templates/03_REVIEW.md`.

### 3. Code Review

Get diff via `git diff <base>...HEAD`. Review: code style, error handling, test coverage, security, performance.

### 4. PR Review

Check via `gh pr view --json number,state,reviews,checks`. Display: PR state, CI checks status, review approvals/requests, blocking issues, next action.

### 5. Update state.json

Set `current: "wf4-review"`. Set `next` based on result:
- Approved → `"wf5-implement"`
- Changes requested → `"wf3-plan"`
- Needs discussion → `"wf4-review"` (another review needed)

### 6. Completion Message

Show file path, result (Approved/Request Changes/Needs Discussion), findings count (Must Fix/Should Fix/Suggestions), next step.

## Notes

- Always record review results
- Must Fix items are mandatory to resolve
- Keep history for multiple reviews
