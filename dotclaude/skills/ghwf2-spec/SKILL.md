---
name: ghwf2-spec
description: 仕様書ドキュメントを作成
argument-hint: "[update | revise]"
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /ghwf2-spec

GitHub Issue とキックオフドキュメントから仕様書を作成する。

## Usage

```
/ghwf2-spec           # 新規作成
/ghwf2-spec update    # 対話形式で更新
/ghwf2-spec revise    # フィードバックに基づいて更新
```

## Prerequisites

- `ghwf1-kickoff` 完了済み
- `01_KICKOFF.md` が存在

## Processing

### 1. Load Context

- Read `state.json` for active work
- Read `01_KICKOFF.md`
- Fetch Issue with comments:
  ```bash
  gh issue view <issue> --json body,comments
  ```
  - Include comments as additional requirements

### 2. Create 02_SPEC.md

- Template: `~/.claude/templates/02_SPEC.md`
- Sections:
  - Functional Requirements
  - Non-functional Requirements
  - Data Model
  - API/Interface Design
  - Edge Cases

### 3. Commit & Push

```bash
git add docs/wf/<work-id>/02_SPEC.md
git commit -m "docs(wf): create spec <work-id>"
git push
```

### 4. Update PR Body

チェックリスト更新:
```markdown
- [x] ghwf1-kickoff
- [x] ghwf2-spec  ← チェック
- [ ] ghwf3-plan
...
```

### 5. Update Labels

```bash
gh issue edit <issue> --add-label "ghwf:step-2"
```

### 6. Update State

```json
{
  "current": "ghwf2-spec",
  "next": "ghwf3-plan",
  "last_execution": "<ISO8601>"
}
```

## Revise Processing

1. Check for updates since last execution
2. Incorporate feedback into spec
3. Append revision entry
4. Commit: `docs(wf): revise spec <work-id>`
