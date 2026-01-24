# Agent: doc-fixer

## 概要

レビューファイル (`docs/reviews/<path>.<filename>.md`) から修正を適用し、元のドキュメントを更新するエージェント。`/doc-fix` コマンドから呼び出され、複数レビューファイルの並列処理に対応している。

## メタデータ

| 項目 | 値 |
|------|-----|
| ID | doc-fixer |
| Base Type | general |
| Category | task |

## 入力パラメータ

| パラメータ | 必須 | 説明 |
|-----------|------|------|
| `review_file` | 必須 | レビューファイルのパス（単一ファイルのみ） |
| `issues` | 任意 | 修正する Issue ID リスト。`["H1", "H2", "M1"]` または `"all"`（デフォルト: `"all"`） |

## 機能

1. **レビューファイル解析**: High Priority / Medium Priority テーブル、Future Considerations リストから Issue を抽出
2. **修正適用**: 元ファイルの該当箇所を特定し、提案された変更を適用
3. **ステータス追跡**: 改善テーブルに Status 列を追加し、修正済み項目にタイムスタンプを付与

## 制約事項

- 1回の呼び出しで1ファイルのみ処理
- 元ファイルとレビューファイルの両方を変更
- 優先度順に修正を適用（High → Medium → Future）
- バックアップ: 主に git を利用、git が無い場合は `.bak` ファイルを作成

## 処理フロー

1. **入力検証**: `review_file` の存在確認
2. **元ファイル特定**: レビューファイル名から元ファイルパスを導出
3. **レビュー解析**: Issue を優先度別に抽出
4. **フィルタリング**: 指定された Issue のみを対象に
5. **修正適用**: 各 Issue に対して変更を適用（リテラル適用 or コンテキスト実装）
6. **レビュー更新**: Status 列を追加し修正済みをマーク
7. **結果返却**: 成功/失敗の構造化結果

## 出力形式

```json
{
  "status": "success" | "partial" | "failure",
  "review_file": "<path>",
  "original_file": "<path>",
  "fixed": ["H1", "H2"],
  "failed": [{"id": "M1", "error": "..."}],
  "summary": {
    "high": {"fixed": 2, "total": 2},
    "medium": {"fixed": 0, "total": 1},
    "future": {"fixed": 0, "total": 0}
  }
}
```

## ステータス値

| ステータス | 条件 |
|-----------|------|
| `success` | 全ての修正が成功 |
| `partial` | 一部成功、一部失敗 |
| `failure` | 全て失敗またはクリティカルエラー |

## 使用例

```
# 全ての Issue を修正
review_file="docs/reviews/commands.wf0-status.md"
issues="all"

# 特定の Issue のみ修正
review_file="docs/reviews/CLAUDE.md"
issues=["H1", "M2"]
```

## 関連ファイル

- テンプレート: `dotclaude/templates/DOC_REVIEW.md` または `~/.claude/templates/DOC_REVIEW.md`
