# /doc-review

ドキュメントファイルをレビューし、`docs/reviews/<path>.<filename>.md`として出力するコマンド。
doc-reviewerサブエージェントを使用した複数ファイルの並列処理をサポート。

## 使用方法

```
/doc-review <file_path>
```

## 引数

- `<file_path>`: レビュー対象ファイルのパス（必須）
  - 単一ファイル: `docs/README.md`
  - 複数ファイル: `docs/README.md docs/INSTALL.md`
  - Globパターン: `docs/*.md`, `dotclaude/commands/wf*.md`

## 処理内容

1. **引数の解析**
   - Globパターンを展開してファイルリストを取得
   - ファイルが見つからない場合はエラー

2. **ファイル存在確認**

3. **並列処理の判断**

| ファイル数 | 処理モード |
|-----------|----------|
| 1 | サブエージェント（単一呼び出し） |
| 2-5 | **非同期並列**（一度に全て） |
| 6+ | **非同期バッチ並列**（5ファイルずつ） |

4. **サブエージェント呼び出し**
   - doc-reviewerエージェントを使用
   - 複数ファイル時は`run_in_background: true`で並列実行

5. **結果収集**
   - TaskOutputで完了を待機

## 出力形式

### 進捗表示（処理中）

```
📋 Reviewing 5 files (parallel)
───────────────────────────────────────────────────────────
[1/5] README.md .............. ✓
[2/5] INSTALL.md ............. ✓
[3/5] CONFIG.md .............. ✓
[4/5] API.md ................. ✗ (failed)
[5/5] GUIDE.md ............... ✓
───────────────────────────────────────────────────────────
```

### 完了メッセージ

```
✅ Review complete

Summary:
  Total:     5 files
  Succeeded: 4 files
  Failed:    1 file

Generated:
  - docs/reviews/docs.README.md
  - docs/reviews/docs.INSTALL.md
  - docs/reviews/docs.CONFIG.md
  - docs/reviews/docs.GUIDE.md

Failed:
  - API.md: <error_reason>
```

## エラーハンドリング

- 一部のファイルが失敗しても他のファイルの処理は継続
- 失敗ファイルは最終サマリーで報告
- リトライコマンドを提案

## 注意事項

- レビューファイルはドキュメントの言語に関わらず日本語で作成
- 具体的で建設的なフィードバックを提供
- 改善点は「箇所」「問題」「提案」を明確に記述
- **複数ファイル時は`run_in_background: true`を使用し、すべてのTaskを単一メッセージで呼び出す必要あり**
