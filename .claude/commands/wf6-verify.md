# /wf6-verify

実装の検証とPR作成を行うコマンド。

## 使用方法

```
/wf6-verify [サブコマンド]
```

## サブコマンド

- `(なし)`: 検証のみ実行
- `pr`: 検証後にPR作成
- `update`: 既存PRを更新

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. 前提条件の確認

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
spec_path="$docs_dir/01_SPEC.md"
plan_path="$docs_dir/02_PLAN.md"
log_path="$docs_dir/04_IMPLEMENT_LOG.md"

# すべてのステップが完了しているか確認
current_step=$(jq -r ".works[\"$work_id\"].plan.current_step // 0" .wf/state.json)
total_steps=$(jq -r ".works[\"$work_id\"].plan.total_steps // 0" .wf/state.json)

if [ "$current_step" -lt "$total_steps" ]; then
  echo "⚠️ 未完了のステップがあります: $current_step/$total_steps"
  echo "/wf5-implement を実行してください"
fi
```

### 2. テストの実行

プロジェクトのテストを実行：

```bash
# package.json の存在確認
if [ -f "package.json" ]; then
  npm test
fi

# pytest の存在確認
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  pytest
fi

# go.mod の存在確認
if [ -f "go.mod" ]; then
  go test ./...
fi
```

テスト結果を記録：

```
📋 Test Results
═══════════════════════════════════════

Total: 150 tests
Passed: 148
Failed: 2
Skipped: 0

Failed Tests:
- test_user_login: AssertionError
- test_export_csv: TimeoutError
```

### 3. ビルドの確認

プロジェクトのビルドを実行：

```bash
# Node.js
if [ -f "package.json" ]; then
  npm run build
fi

# Go
if [ -f "go.mod" ]; then
  go build ./...
fi

# Rust
if [ -f "Cargo.toml" ]; then
  cargo build
fi
```

### 4. Lint/Format チェック

```bash
# ESLint
if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
  npm run lint
fi

# Prettier
if [ -f ".prettierrc" ]; then
  npm run format:check
fi

# Black (Python)
if [ -f "pyproject.toml" ]; then
  black --check .
fi

# golangci-lint
if [ -f ".golangci.yml" ]; then
  golangci-lint run
fi
```

### 5. Success Criteria の確認

Kickoff の Success Criteria と照合：

```
📋 Success Criteria Check
═══════════════════════════════════════

Kickoff の Success Criteria:
- [✓] CSV エクスポート機能が動作する
- [✓] 10万件のデータでも3秒以内に完了
- [✓] エラー時に適切なメッセージが表示される
- [ ] ユーザーマニュアルが更新されている

結果: 3/4 完了
未完了項目があります。
```

### 6. 検証結果サマリー

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

### 7. PR 作成（pr サブコマンド）

検証がパスした場合、PRを作成：

```bash
branch=$(jq -r ".works[\"$work_id\"].git.branch" .wf/state.json)
base=$(jq -r ".works[\"$work_id\"].git.base" .wf/state.json)

# プッシュ
git push -u origin "$branch"

# PR 作成
gh pr create \
  --base "$base" \
  --title "<PR title>" \
  --body "$(cat << EOF
## Summary

<Kickoff の Goal を要約>

## Changes

<主な変更点を箇条書き>

## Test Plan

<テスト方法>

## Related Issues

Closes #<issue_number>

## Documents

- [Kickoff](docs/wf/<work-id>/00_KICKOFF.md)
- [Spec](docs/wf/<work-id>/01_SPEC.md)
- [Plan](docs/wf/<work-id>/02_PLAN.md)
- [Implementation Log](docs/wf/<work-id>/04_IMPLEMENT_LOG.md)
EOF
)"
```

### 8. PR 更新（update サブコマンド）

既存のPRを更新：

```bash
# 変更をプッシュ
git push

# PR の説明を更新（必要に応じて）
gh pr edit --body "$(cat << EOF
...
EOF
)"
```

### 9. state.json の更新

```bash
jq ".works[\"$work_id\"].current = \"wf6-verify\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].next = \"complete\"" .wf/state.json > tmp && mv tmp .wf/state.json

# PR 情報を記録
jq ".works[\"$work_id\"].pr = {\"number\": <pr_number>, \"url\": \"<pr_url>\"}" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 10. 完了メッセージ

#### 検証のみの場合

```
✅ 検証が完了しました

結果: PASS

Tests: 150/150 passed
Build: Success
Lint: No issues
Success Criteria: 4/4 completed

PRを作成する場合: /wf6-verify pr
```

#### PR作成の場合

```
✅ PR を作成しました

PR: #<number>
URL: <pr_url>

Title: <title>
Base: <base> ← <branch>

次のステップ:
- レビューを依頼してください
- CI/CD の完了を確認してください
```

## 検証失敗時の対応

```
❌ 検証に失敗しました

Failed Items:
- [ ] Tests: 2 failed
  - test_user_login
  - test_export_csv
- [ ] Success Criteria: 1 incomplete
  - ユーザーマニュアルの更新

対応:
1. 失敗したテストを修正
2. 未完了の Success Criteria を対応
3. 再度 /wf6-verify を実行
```

## 注意事項

- テスト失敗時はPR作成不可
- ビルド失敗時はPR作成不可
- Success Criteria の未完了項目は警告表示
- PR作成後も検証は再実行可能
