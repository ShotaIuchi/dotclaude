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

### 1. Run Verification

- Lint: `pnpm lint`
- Type check: `pnpm type-check`
- Build: `pnpm build`
- Test: `pnpm test`

### 2. Code Review

- Review implementation against spec
- Check for security issues
- Verify edge cases handled

### 3. Create/Update 06_VERIFY.md

- Test results
- Review findings
- Issues to address

### 4. Handle Issues

If issues found:
- Fix issues
- Re-run verification
- Update documentation

### 5. Commit & Push

```bash
git add .
git commit -m "docs(wf): verify implementation <work-id>"
git push
```

### 6. Update PR & Labels

- PR チェックリスト更新
- `ghwf:step-6` ラベル追加

### 7. Update State

```json
{
  "current": "ghwf6-verify",
  "next": "ghwf7-pr",
  "last_execution": "<ISO8601>"
}
```
