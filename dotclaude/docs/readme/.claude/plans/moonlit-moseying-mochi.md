# skills/ と agents/workflow/ の統合プラン

## 背景

- 現在 skills/wf*/ と agents/workflow/ が分離している
- ユーザーの意図：`/wf1-kickoff`で呼び出し、メイントークンを節約してサブエージェントで処理

## 解決策

`context: fork` を使用して skills/ に統合。agents/workflow/ の内容を skills/ に移動。

## 修正内容

### 1. skills/wf1-kickoff/SKILL.md

frontmatterに追加：
```yaml
---
name: wf1-kickoff
description: Create workspace and Kickoff document
context: fork
agent: general-purpose
---
```

本文に agents/workflow/research.md の内容を統合：
- Issue Analysis
- Codebase Investigation
- Dependency Analysis
- Technical Background

### 2. skills/wf2-spec/SKILL.md

frontmatterに追加：
```yaml
---
name: wf2-spec
description: Create the Specification document
context: fork
agent: general-purpose
---
```

本文に agents/workflow/spec-writer.md の内容を統合：
- Requirements Structuring (FR/NFR)
- Scope Clarification
- Acceptance Criteria (Given/When/Then)
- Use Case Organization

### 3. skills/wf3-plan/SKILL.md

frontmatterに追加：
```yaml
---
name: wf3-plan
description: Create the Implementation Plan
context: fork
agent: Plan
---
```

本文に agents/workflow/planner.md の内容を統合：
- Step Decomposition
- Technical Approach Selection
- Risk Analysis
- Rollback Planning

### 4. skills/wf5-implement/SKILL.md

frontmatterに追加：
```yaml
---
name: wf5-implement
description: Implement one step of the Plan
context: fork
agent: general-purpose
---
```

本文に agents/workflow/implementer.md の内容を統合：
- Code Implementation
- Test Execution
- Implementation Log Update

### 5. agents/workflow/ の処理

統合後、以下の選択肢：

**A. 削除**（推奨）
- 重複排除
- skills/が唯一の定義

**B. 参照として残す**
- 他の用途（`/agent research`）で使う場合
- agents/README.md を更新

### 6. agents/README.md の更新

ワークフロー支援型セクションを更新：
```markdown
### ワークフロー支援型 (workflow/)

> **Note:** これらのエージェントは skills/wf*/ に統合されました。
> `/wf1-kickoff` 等のスキルを直接使用してください。
```

または、agents/workflow/ を削除する場合は該当セクションを削除。

## 対象ファイル一覧

| 操作 | ファイル |
|------|---------|
| 編集 | skills/wf1-kickoff/SKILL.md |
| 編集 | skills/wf2-spec/SKILL.md |
| 編集 | skills/wf3-plan/SKILL.md |
| 編集 | skills/wf5-implement/SKILL.md |
| 編集 | agents/README.md |
| 削除候補 | agents/workflow/research.md |
| 削除候補 | agents/workflow/spec-writer.md |
| 削除候補 | agents/workflow/planner.md |
| 削除候補 | agents/workflow/implementer.md |

## 検証方法

1. `/wf1-kickoff github=123` を実行
2. サブエージェントとして起動されることを確認
3. 結果がサマリとして返されることを確認
4. メインコンテキストのトークン消費が抑えられていることを確認

## 注意事項

- `context: fork` 時は親の会話履歴が継承されない
- デフォルトタイムアウト: 10分
- 並列実行可能（複数のforkを同時起動できる）
