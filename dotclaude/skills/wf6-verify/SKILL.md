---
name: wf6-verify
description: 実装を検証
argument-hint: ""
---

**Always respond in Japanese.**

# /wf6-verify

Verify implementation quality.

## Usage

```
/wf6-verify
```

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

### 5. Update state.json

- On PASS: Set `current: "wf6-verify"`, `next: "wf7-pr"`
- On FAIL: Set `current: "wf6-verify"`, `next: "wf6-verify"` (re-run after fixes)

### 6. Completion Message

- PASS: Show results, inform that `/wf7-pr` is next step
- FAIL: List failed items, suggest fixes, instruct to re-run `/wf6-verify`

## Handling Failure

If verification fails: list failed items, suggest fixes, instruct to re-run `/wf6-verify`.

## Notes

- Warning for incomplete Success Criteria
- Verification can be re-run multiple times
- PR creation is handled by `/wf7-pr` after verification passes
