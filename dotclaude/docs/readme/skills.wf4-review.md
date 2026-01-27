# /wf4-review

Plan、実装コード、またはPRステータスのレビュー記録を作成するコマンド。

## 使用方法

```
/wf4-review [subcommand]
```

## サブコマンド

- `(なし)` or `plan`: Planレビュー
- `code`: 実装コードレビュー
- `pr`: PRステータス確認

## 処理

1. **Planレビュー**: 完全性・実現可能性・品質の観点で評価。`03_REVIEW.md`に記録
2. **コードレビュー**: `git diff <base>...HEAD`でdiff取得。スタイル・エラー処理・テスト・セキュリティ・パフォーマンスを確認
3. **PRレビュー**: `gh pr view`でCI/レビュー状況を表示
4. state.json更新: Approved→next: wf5-implement / Changes→next: wf3-plan / Discussion→next: wf4-review

## 注意事項

- レビュー結果は必ず記録
- Must Fix項目は解決必須
- 複数回レビューの履歴を保持
