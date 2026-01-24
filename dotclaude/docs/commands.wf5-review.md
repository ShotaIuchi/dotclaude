# /wf5-review

レビュー記録を作成するコマンド。Planレビューや実装後のコードレビューに使用。

## 使用方法

```
/wf5-review [subcommand]
```

## サブコマンド

- `(なし)` または `plan`: Planのレビュー
- `code`: 実装コードのレビュー
- `pr`: PRステータスの確認・レビュー

## 処理内容

### Plan レビュー（デフォルト）

以下の観点でPlan内容をレビュー:

**チェックリスト:**

1. **完全性**
   - Spec要件がすべてカバーされている
   - テスト計画が含まれている
   - ロールバック手順が明確

2. **実現可能性**
   - 各ステップの作業量が妥当
   - 依存関係が正しい
   - リスクが適切に評価されている

3. **品質**
   - コーディング規約の遵守を考慮
   - パフォーマンス影響を検討
   - セキュリティを考慮

### Code レビュー

```bash
# 変更ファイルの確認
git diff <base>...HEAD --name-only

# 差分の確認
git diff <base>...HEAD
```

観点: コードスタイル、エラーハンドリング、テストカバレッジ、セキュリティ、パフォーマンス

### PR レビュー

GitHub PRのステータス確認:

```
📋 PR Review Status: FEAT-123-export-csv
═══════════════════════════════════════

PR: #42 - CSVエクスポート機能
State: open

Checks:
- [✓] CI/CD Pipeline
- [✓] Code Coverage
- [→] Security Scan (running)

Reviews:
- @reviewer1: Approved
- @reviewer2: Changes Requested
```

## 出力例

```
✅ Review complete

File: docs/wf/FEAT-123-export-csv/03_REVIEW.md

Result: Approved

Findings:
- Must Fix: 1
- Should Fix: 2
- Suggestions: 3

Next step:
- Approved: Run /wf6-implement
- Request Changes: Fix issues and run /wf5-review again
```

## 注意事項

- レビュー結果を必ず記録
- Must Fix項目は解決必須
- レビュアー名を記録
- 複数回レビューの履歴を保持
