# Review: wf0-status.md

> Reviewed: 2026-01-22
> Original: dotclaude/commands/wf0-status.md

## 概要 (Summary)

現在のワークフローステータスを表示するコマンドの仕様書。単一のワークまたは全ワークの一覧を表示し、フェーズ進捗、ドキュメント存在状況、Git状態、worktree情報を視覚的に提示する。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [x] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: 記載内容が正確
- [x] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| - | - | 優先度高の指摘事項なし | - |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| 1 | セクション3 | Phase Progressの「→ current」表示が曖昧 | `current`と`next`両方を明確に区別できる表記にする（例：`[◆] current`, `[→] next`） |
| 2 | セクション4 | Uncommitted changesの行数カウントが`wc -l`のみ | staged/unstagedの内訳も表示すると便利 |
| 3 | セクション5 | local.json未存在時のworktree一覧表示が冗長 | 簡潔なメッセージと復旧手順のみ表示する |

### 将来の検討事項 (Future Considerations)

- JSON形式での出力オプション（他ツールとの連携用）
- フィルタリング機能（特定フェーズのワークのみ表示等）
- タイムスタンプの相対表示（「3時間前」等）

## 総評 (Overall Assessment)

ステータス表示コマンドとして十分な情報量を持つ。視覚的な表現（絵文字、罫線、進捗バー等）が適切で、ユーザーが現在の状態を把握しやすい。単一/全ワーク表示の切り替え、Git状態の追加表示、worktree情報の条件付き表示など、機能が充実している。03_REVIEW.mdの生成元（wf5-review）も注記されており、ドキュメント構造が明確。
