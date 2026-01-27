# /doc-fix

`docs/reviews/<path>.<filename>.md`ファイルで特定された問題を修正し、元のドキュメントに変更を適用するコマンド。
複数レビューファイルの並列処理をサポート。

## 使用方法

```
/doc-fix [file_path...] [--all]
```

## 引数

- `file_path`: レビューファイルまたは元ファイルへのパス（オプション）
  - `docs/reviews/commands.wf0-status.md` → レビューファイルとして直接使用
  - `commands/wf0-status.md` → `docs/reviews/commands.wf0-status.md`を自動検索
  - `docs/reviews/*.md` → 複数ファイル用Globパターン
  - 省略時 → reviewsディレクトリ内の`*.md`ファイルを検索
- `--all`: インタラクティブ選択なしで全修正を適用（並列モードでは必須）

## 処理モード

| ファイル数 | --allフラグ | 処理モード |
|-----------|-----------|-----------|
| 1 | なし | インタラクティブ（ユーザーが項目選択） |
| 1 | あり | サブエージェントでバッチ処理 |
| 2+ | なし | エラー: "--all required" |
| 2+ | あり | サブエージェントで並列処理 |

## 完了メッセージ

```
Fix completed

Summary:
  Total:     5 files
  Succeeded: 3 files
  Partial:   1 file
  Failed:    1 file
```

## 注意事項

- 問題は優先度順に表示: 高 → 中 → 将来検討
- レビューファイルは修正状況で更新される
- 並列処理で複数ファイルのパフォーマンスが向上
