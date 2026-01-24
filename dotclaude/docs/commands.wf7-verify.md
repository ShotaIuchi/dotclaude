# /wf7-verify

実装を検証してPRを作成するコマンド。

## 使用方法

```
/wf7-verify [subcommand]
```

## サブコマンド

- `(なし)`: 検証のみ実行
- `pr`: 検証後にPR作成
- `update`: 既存PRの更新

## 処理内容

1. **前提条件チェック**
   - すべてのステップが完了しているか確認
   - 未完了の場合は警告

2. **テスト実行**
   - config.jsonのtest設定を使用
   - またはpackage.json、pytest.ini等から自動検出
   - テスト結果を記録

3. **ビルドチェック**
   - config.jsonのbuild設定を使用
   - またはパッケージ設定から自動検出

4. **Lint/フォーマットチェック**
   - config.jsonのlint設定を使用
   - またはプロジェクト設定から自動検出

5. **Success Criteriaチェック**
   - Kickoffの成功基準と比較

6. **検証サマリー表示**

7. **PR作成**（prサブコマンド）
   - ブランチをプッシュ
   - PRタイトル・ボディを生成して作成

## 検証サマリー

```
📋 Verification Summary: FEAT-123-export-csv
═══════════════════════════════════════

Implementation:
- Steps: 5/5 completed
- Files changed: 12
- Lines: +450, -120

Tests:
- Total: 150
- Passed: 150
- Failed: 0

Build: ✓ Success

Lint: ✓ No issues

Success Criteria: 4/4 completed

Overall: PASS
```

## 出力例（検証のみ）

```
✅ Verification complete

Result: PASS

Tests: 150/150 passed
Build: Success
Lint: No issues
Success Criteria: 4/4 completed

To create PR: /wf7-verify pr
```

## 出力例（PR作成）

```
✅ PR created

PR: #42
URL: https://github.com/org/repo/pull/42

Title: CSVエクスポート機能 (#123)
Base: develop ← feat/123-export-csv

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
3. Run /wf7-verify again
```

## 注意事項

- テストが失敗するとPR作成不可
- ビルドが失敗するとPR作成不可
- Success Criteria未完了項目は警告表示
- PR作成後も検証は再実行可能
