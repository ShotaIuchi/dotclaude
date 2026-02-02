---
name: ghwf3-plan
description: 実装計画ドキュメントを作成
argument-hint: "[update | revise]"
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /ghwf3-plan

仕様書から実装計画を作成する。

## Usage

```
/ghwf3-plan           # 新規作成
/ghwf3-plan update    # 対話形式で更新
/ghwf3-plan revise    # フィードバックに基づいて更新
```

## Prerequisites

- `ghwf2-spec` 完了済み
- `02_SPEC.md` が存在

## Processing

### 1. Load Context

- Read `state.json` for active work
- Read `01_KICKOFF.md`, `02_SPEC.md`
- Fetch Issue with comments:
  ```bash
  gh issue view <issue> --json body,comments
  ```
- Analyze codebase structure

### 2. Create 03_PLAN.md

- Template: `~/.claude/templates/03_PLAN.md`
- Sections:
  - Implementation Steps (ordered)
  - File Changes
  - Dependencies
  - Risk Assessment

### 3. Commit & Push

**Execute immediately without confirmation:**

```bash
git add docs/wf/<work-id>/03_PLAN.md
git commit -m "docs(wf): create plan <work-id>"
git push
```

### 4. Update PR & Labels

- PR チェックリスト更新
- `ghwf:step-3` ラベル追加

### 5. Update State

```json
{
  "current": "ghwf3-plan",
  "next": "ghwf4-review",
  "last_execution": "<ISO8601>"
}
```
