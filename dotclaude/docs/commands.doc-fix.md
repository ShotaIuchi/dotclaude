# /doc-fix

`reviews/README.<path>.<filename>.md`ファイルで特定された問題を修正し、元のドキュメントに適用するコマンド。
doc-fixerサブエージェントを使用した複数ファイルの並列処理をサポート。

## 使用方法

```
/doc-fix [file_path...] [--all]
```

## 引数

- `file_path`: レビューファイルまたは元ファイルのパス（オプション）
  - `reviews/README.commands.wf0-status.md` → 直接レビューファイルとして使用
  - `commands/wf0-status.md` → `reviews/README.commands.wf0-status.md`を自動検索
  - 省略 → reviewsディレクトリ内の`README.*.md`を検索
- `--all`: インタラクティブ選択なしで全修正を適用（並列モードには必須）

## 処理モード

| ファイル数 | --allフラグ | 処理モード |
|-----------|------------|----------|
| 1 | なし | インタラクティブ（ユーザーが項目を選択） |
| 1 | あり | サブエージェントでバッチ処理 |
| 2+ | なし | エラー: "--all required for multiple files" |
| 2+ | あり | サブエージェントで並列処理 |

## 処理内容

### インタラクティブモード（単一ファイル、--allなし）

1. レビューファイルを解析して問題を抽出
2. 優先度順に表示（高→中→将来検討）
3. ユーザーが修正項目を選択
4. 選択された項目を修正

### 並列モード（複数ファイルまたは--all）

1. doc-fixerサブエージェントを並列起動
2. 各ファイルの全問題を修正
3. 結果を収集

## レビューファイルの更新

修正後、レビューファイルの改善点テーブルにStatus列を追加:

```markdown
| # | 箇所 | 問題 | 提案 | Status |
|---|------|------|------|--------|
| 1 | セクション4.1 | ... | ... | ✓ Fixed (2026-01-24) |
```

## 出力形式

### 完了メッセージ（単一ファイル）

```
✅ Fix completed

Files modified:
- Original: commands/wf0-status.md
- Review:   reviews/README.commands.wf0-status.md

Fixed items:
───────────────────────────────────────────────────────────
🔴 High Priority:     2/2
🟡 Medium Priority:   1/3
🟢 Future:            0/1
───────────────────────────────────────────────────────────

Remaining issues: 3
```

### 完了メッセージ（並列モード）

```
✅ Fix completed

Summary:
  Total:     5 files
  Succeeded: 3 files (all issues fixed)
  Partial:   1 file (some issues fixed)
  Failed:    1 file

Details:
───────────────────────────────────────────────────────────
✓ README.md: 3/3 issues fixed
✓ INSTALL.md: 2/2 issues fixed
△ CONFIG.md: 1/3 issues fixed
✗ API.md: Error reading review file
───────────────────────────────────────────────────────────
```

## 注意事項

- 問題は優先度順に表示: 高→中→将来検討
- インタラクティブモード: 選択した項目のみ修正
- 並列モード（--all）: 各ファイルの全問題を修正
- レビューファイルは追跡のためにステータスが更新される
- 提案が曖昧な場合はコンテキストに基づいて最善の判断
