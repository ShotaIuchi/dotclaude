# Review: agent.md

> Reviewed: 2026-01-22
> Original: dotclaude/commands/agent.md

## 概要 (Summary)

サブエージェントを直接呼び出すコマンドの仕様書。ワークフロー支援型（research、spec-writer等）、タスク特化型（reviewer、test-writer等）、プロジェクト分析型（codebase、dependency等）の3カテゴリ、11種類のエージェントをサポート。Claude CodeのTaskツールを使用してサブエージェントを起動する。エージェント定義ファイルの検索パス、パラメータ形式、エラーハンドリング、将来ロードマップも明確に定義されている。

## 評価 (Evaluation)

### 品質 (Quality)

- [x] **完全性 (Completeness)**: 必要な情報が網羅されている
- [x] **明確性 (Clarity)**: 読者にとって分かりやすい
- [x] **一貫性 (Consistency)**: 用語・スタイルが統一されている

### 技術的正確性 (Technical Accuracy)

- [x] **情報の正確性 (Correct information)**: 記載内容が正確
- [ ] **最新性 (Up-to-date content)**: 情報が最新の状態

## 改善点 (Improvements)

### 優先度高 (High Priority)

| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| 1 | Agent List | 11種類のエージェントがリストされているが、対応する定義ファイルが存在するか不明 | 各エージェント定義ファイルの存在確認と、不足分の作成を行う |

### 優先度中 (Medium Priority)

| # | 箇所 | 問題 | 提案 |
|---|------|------|------|
| 1 | セクション3 | `_base/context.md`と`_base/constraints.md`の共通ファイルへの参照があるが、内容が不明 | 共通コンテキストの内容を明記するか、参照ドキュメントを作成する |
| 2 | Usage Examples | `files="src/auth/*.ts"`のようなglob指定がエージェントでどう処理されるか不明 | パラメータのパース・展開方法を明記する |

### 将来の検討事項 (Future Considerations)

- `/agent list` サブコマンドの仕様詳細化（出力フォーマット、フィルタリングオプション等）
- エージェント実行のタイムアウト設定
- 実行ログの永続化オプション

## 総評 (Overall Assessment)

サブエージェントへの統一的なアクセスを提供する有用なコマンド。3カテゴリへの分類が明確で、用途に応じたエージェント選択が容易。エージェント定義ファイルの検索パス（プロジェクト固有→グローバル→dotclaude）も優先順位が明確に定義されている。Base Typeとsubagent_typeの対応表も追加されており、実装しやすい。タイムスタンプはUTC固定に修正済み。Future Roadmapセクションも追加され、今後の展望が明確になっている。主な課題は、参照されているエージェント定義ファイルが実際に存在するかの確認と、共通コンテキストファイルの整備。
