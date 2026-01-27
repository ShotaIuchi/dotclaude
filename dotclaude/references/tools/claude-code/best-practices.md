# Best Practices（プロジェクト固有）

公式ドキュメントでカバーされない、本プロジェクト固有のベストプラクティス。

> 公式の Skills / Sub-agents / CLAUDE.md の仕様は [decisions.md](decisions.md) のリンクを参照。

---

## ワークフロースキルの命名

| Prefix | Category | Examples |
|--------|----------|----------|
| `wf0-` | 環境・状態管理 | status, nextstep, restore, remote |
| `wf1-` | キックオフ | kickoff |
| `wf2-` | 仕様作成 | spec |
| `wf3-` | 計画作成 | plan |
| `wf4-` | レビュー | review |
| `wf5-` | 実装 | implement |
| `wf6-` | 検証 | verify |

ユーティリティスキル（agent, commit, doc-review 等）は番号なし。

---

## Processing セクションの構成

スキル本文の処理手順は段階的に記述する：

```markdown
## Processing

### 1. 前提条件の確認
必要なツール・状態の確認

### 2. 入力の解析
$ARGUMENTS のパース

### 3. メイン処理
実際の処理

### 4. 結果の出力
完了メッセージと次のステップ
```

---

## 完了メッセージの形式

次のステップを必ず提示する：

```
✅ Task completed

Summary:
- Created: 3 files
- Modified: 2 files

Next step: Run /wf5-implement to implement the next step
```

---

## スキル本文の制限

- SKILL.md 本文は **500行以下**
- 詳細は `references/` に分離し、`references` フィールドで参照
- 複数スキルで共有するリファレンスは `references/common/` に配置

---

## description の独自ガイドライン

公式の記述ルールに加え、以下を守る：

- 英語で記述（Claude の自動起動判断の精度向上）
- 具体的な技術名・パターン名を含める
- 「This skill should be used when...」のフォーマット推奨

---

## エラーハンドリングのパターン

エラー発生時は次のアクションを必ず提示：

```
Error: No active work found

To fix:
1. Run /wf1-kickoff to create a new workspace
   OR
2. Run /wf0-restore to restore an existing workspace
```
