---
name: wf6-verify
description: Verify implementation and create PR
argument-hint: "[pr | update]"
---

**Always respond in Japanese.**

# /wf6-verify

Verify implementation quality and optionally create/update a PR.

## Usage

```
/wf6-verify [subcommand]
```

## Subcommands

- `(none)`: Run verification only
- `pr`: Create PR after verification passes
- `update`: Update existing PR

## Processing

### 1. Check Prerequisites

Get active work from state.json. Verify all plan steps are completed (`plan.current_step >= plan.total_steps`). Warn if incomplete.

### 2. Run Verification

Execute each check, using commands from `.wf/config.json` (`verify.test`, `verify.build`, `verify.lint`) with auto-detection fallback based on project files:

| Check | Config Key | Fallback Detection |
|-------|-----------|-------------------|
| Tests | `verify.test` | package.json→npm test, pytest.ini/pyproject.toml→pytest, go.mod→go test |
| Build | `verify.build` | package.json→npm run build, go.mod→go build, Cargo.toml→cargo build |
| Lint | `verify.lint` | .eslintrc→npm run lint, .prettierrc→format:check, pyproject.toml→black --check, .golangci.yml→golangci-lint |

### 3. Check Success Criteria

Compare against Success Criteria from `01_KICKOFF.md`. Mark each as OK or incomplete.

### 4. Verification Summary

Display: implementation progress, test results, build status, lint status, success criteria completion, overall PASS/FAIL.

### 5. Create PR (`pr` subcommand)

Only if verification passes. Cannot create PR if tests or build fail.

1. Get branch/base from state.json
2. `git push -u origin <branch>`
3. Generate PR title from Kickoff Goal. For github source: append `(#<issue_number>)`
4. Create PR via `gh pr create` with body: Summary, Changes, Test Plan, Related Issues (`Closes #N`), Document links

### 6. Update PR (`update` subcommand)

Push changes and optionally update PR description via `gh pr edit`.

### 7. Update state.json

Set `current: "wf6-verify"`, `next: "complete"`. Record PR number/URL if created.

### 8. Completion Message

- Verification only: Show results, suggest `/wf6-verify pr`
- PR created: Show PR number, URL, title, base←branch, suggest requesting review

## Handling Failure

If verification fails: list failed items, suggest fixes, instruct to re-run `/wf6-verify`.

## Notes

- Cannot create PR if tests or build fail
- Warning for incomplete Success Criteria
- Verification can be re-run after PR creation
