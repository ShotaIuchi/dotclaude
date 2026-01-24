# /wf6-verify

実装の検証とPR作成を行うコマンド。

## 使用方法

```
/wf6-verify [subcommand]
```

## サブコマンド

- `(なし)`: 検証のみ実行
- `pr`: 検証後にPR作成
- `update`: 既存PRを更新

## 処理

### 検証

1. 前提条件チェック（全ステップ完了確認）
2. テスト実行
3. ビルドチェック
4. Lint/フォーマットチェック
5. 成功条件チェック（Kickoffとの比較）
6. 検証サマリー表示

### PR作成（prサブコマンド）

1. リモートにプッシュ
2. PRタイトル生成
3. PRボディ作成（Summary, Changes, Test Plan, Related Issues, Documents）
4. `gh pr create`実行
5. `state.json`にPR情報を記録

## 検証サマリー

```
📋 Verification Summary: <work-id>
═══════════════════════════════════════

Implementation:
- Steps: <current>/<total> completed
- Files changed: <n>
- Lines: +<added>, -<removed>

Tests:
- Total: <n>
- Passed: <n>
- Failed: <n>

Build: ✓ Success

Lint: ✓ No issues

Success Criteria: <n>/<m> completed

Overall: <PASS / FAIL>
```

## 完了メッセージ（PR作成時）

```
✅ PR created

PR: #<number>
URL: <pr_url>

Title: <title>
Base: <base> ← <branch>

Next steps:
- Request review
- Confirm CI/CD completion
```

## 検証失敗時

```
❌ Verification failed

Failed Items:
- [ ] Tests: 2 failed
  - test_user_login
  - test_export_csv
- [ ] Success Criteria: 1 incomplete
  - User manual update

Response:
1. Fix failed tests
2. Address incomplete Success Criteria
3. Run /wf6-verify again
```

## 注意事項

- テスト失敗時はPR作成不可
- ビルド失敗時はPR作成不可
- 成功条件の未完了項目は警告表示
- PR作成後も再検証可能
