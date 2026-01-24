# /wf4-review

Planまたはコードのレビュー記録を作成するコマンド。

## 使用方法

```
/wf4-review [subcommand]
```

## サブコマンド

- `(なし)` または `plan`: Planのレビュー
- `code`: 実装コードのレビュー
- `pr`: PRのステータスチェックとレビュー

## 処理

### Planレビュー

チェックリスト:
- 完全性: Spec要件が全てカバーされているか
- 実現可能性: 各ステップの作業量が妥当か
- 品質: セキュリティ・パフォーマンスを考慮しているか

### コードレビュー

観点:
- コードスタイル
- エラーハンドリング
- テストカバレッジ
- セキュリティ
- パフォーマンス

### PRレビュー

GitHub PRのステータス確認:
- CIチェック状況
- レビュアーのコメント
- ブロッキング項目

## state.json更新

- 承認時: `next = "wf5-implement"`
- 変更要求時: `next = "wf3-plan"`
- 議論継続時: `next = "wf4-review"`

## 完了メッセージ

```
✅ Review complete

File: docs/wf/<work-id>/03_REVIEW.md

Result: <Approved / Request Changes / Needs Discussion>

Findings:
- Must Fix: 1
- Should Fix: 2
- Suggestions: 3

Next step:
- Approved: Run /wf5-implement
- Request Changes: Fix issues and run /wf4-review again
```

## 注意事項

- レビュー結果は必ず記録
- Must Fix項目は解決必須
- レビュアー名を記録
- 複数回レビューの履歴を保持
