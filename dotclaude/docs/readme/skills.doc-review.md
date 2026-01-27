# /doc-review

ドキュメントファイルのレビューを作成し、`docs/reviews/<path>.<filename>.md`に出力するコマンド。
複数ファイルの並列処理をサポート。

## 使用方法

```
/doc-review <file_path>
```

## 引数

- `<file_path>`: レビュー対象のファイルパス（必須）
  - 単一ファイル: `docs/README.md`
  - 複数ファイル: `docs/README.md docs/INSTALL.md`
  - Globパターン: `docs/*.md`

## 処理モード

| ファイル数 | 処理モード |
|-----------|-----------|
| 1 | サブエージェント（単一呼び出し） |
| 2-5 | 非同期並列（一括起動） |
| 6+ | バッチ並列（5ファイルずつ） |

## 完了メッセージ

```
Review complete

Summary:
  Total:     5 files
  Succeeded: 4 files
  Failed:    1 file

Generated:
  - docs/reviews/docs.README.md
  - docs/reviews/docs.INSTALL.md
  ...
```

## 注意事項

- レビューファイルはドキュメントの言語に関わらず日本語で作成
- 具体的で建設的なフィードバックを提供
- 複数ファイルの並列処理でパフォーマンスが向上
