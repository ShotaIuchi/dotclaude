---
name: ghwf6-verify
description: 実装を検証
argument-hint: ""
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /ghwf6-verify

実装の検証を行う。

## Usage

```
/ghwf6-verify
```

## Prerequisites

- `ghwf5-implement` 完了済み
- 全実装ステップ完了

## Processing

### 1. Load Context

- Read `state.json` for active work
- Fetch Issue/PR with comments:
  ```bash
  gh issue view <issue> --json body,comments
  gh pr view <pr> --json comments,reviews
  ```

### 2. Run Verification

- Lint: `pnpm lint`
- Type check: `pnpm type-check`
- Build: `pnpm build`
- Test: `pnpm test`

### 3. Code Review

- Review implementation against spec
- Check for security issues
- Verify edge cases handled

### 4. Create/Update 06_VERIFY.md

- Test results
- Review findings
- Issues to address

### 5. Handle Issues

If issues found:
- Fix issues
- Re-run verification
- Update documentation

### 6. Commit & Push

**Execute immediately without confirmation:**

```bash
git add .
git commit -m "docs(wf): verify implementation <work-id>"
git push
```

### 7. Update PR & Labels

- PR チェックリスト更新
- `ghwf:step-6` ラベル追加

### 8. Update State

```json
{
  "current": "ghwf6-verify",
  "next": "ghwf7-pr",
  "last_execution": "<ISO8601>"
}
```
