# Agent: doc-reviewer

## 概要

単一のドキュメントファイルをレビューし、`docs/reviews/<path>.<filename>.md` ファイルを生成するエージェント。`/doc-review` コマンドから呼び出され、複数ファイルの並列処理に対応している。

## メタデータ

| 項目 | 値 |
|------|-----|
| ID | doc-reviewer |
| Base Type | general |
| Category | task |

## 入力パラメータ

| パラメータ | 必須 | 説明 |
|-----------|------|------|
| `file` | 必須 | レビュー対象のドキュメントファイルパス（単一ファイルのみ） |

## 機能

1. **ドキュメント分析**: 目的・役割の特定、完全性評価、明確さ評価、一貫性チェック
2. **技術的正確性レビュー**: 情報の正確性と最新性の検証
3. **改善提案**: 優先度付きの改善推奨事項（具体的な箇所、問題、提案）

## 制約事項

- 1回の呼び出しで1ファイルのみ処理
- 読み取り専用（元ドキュメントは変更しない）
- レビュー内容は日本語で出力
- 出力ファイルが既存の場合は警告なしで上書き

## 評価観点

| 観点 | 評価ポイント |
|------|-------------|
| 目的と役割 | 意図が明確か、対象読者が特定されているか |
| 完全性 | 必要なセクションが揃っているか、重要情報の欠落がないか |
| 明確さ | 論理的構造、明瞭な言語、適切な見出し |
| 一貫性 | 用語の統一、フォーマットの統一 |
| 技術的正確性 | コード例が動作するか、コマンドが有効か、参照が正しいか |
| 改善点 | 影響度で優先順位付け、具体的な箇所と改善提案 |

## 出力パス規則

```
docs/guide.md → docs/reviews/docs.guide.md
commands/wf0-status.md → docs/reviews/commands.wf0-status.md
agents/_base/constraints.md → docs/reviews/agents._base.constraints.md
```

## 出力形式

```json
{
  "status": "success" | "failure",
  "file": "<入力ファイルパス>",
  "output": "<出力ファイルパス>",
  "error": "<エラーメッセージ（失敗時のみ）>"
}
```

## 生成されるレビューファイル構造

```markdown
# Review: <filename>

> Reviewed: YYYY-MM-DD
> Original: <file_path>

## 概要 (Summary)
...

## 評価 (Evaluation)
...

## 改善点 (Improvements)
...

## 総評 (Overall Assessment)
...
```

## 使用例

```
# 単一ファイルのレビュー
file="commands/wf0-status.md"

# 親コマンドから複数ファイルを並列処理
/doc-review commands/*.md
```

## 関連ファイル

- テンプレート優先順位:
  1. `~/.claude/templates/DOC_REVIEW.md`（ユーザーレベル）
  2. `dotclaude/templates/DOC_REVIEW.md`（プロジェクトレベル）
