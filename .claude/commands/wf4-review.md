# /wf4-review

レビュー記録を作成するコマンド。Plan のレビューや実装後のコードレビューに使用。

## 使用方法

```
/wf4-review [サブコマンド]
```

## サブコマンド

- `(なし)` または `plan`: Plan のレビュー
- `code`: 実装コードのレビュー
- `pr`: PR の状態確認とレビュー

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. 前提条件の確認

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
review_path="$docs_dir/03_REVIEW.md"
```

### 2. Plan レビュー（デフォルト）

Plan の内容を確認し、以下の観点でレビュー：

**チェックリスト:**

1. **完全性**
   - [ ] すべての Spec 要件がカバーされている
   - [ ] テスト計画が含まれている
   - [ ] ロールバック手順が明確

2. **実現可能性**
   - [ ] 各ステップの作業量が妥当
   - [ ] 依存関係が正しい
   - [ ] リスクが適切に評価されている

3. **品質**
   - [ ] コーディング規約への準拠が考慮されている
   - [ ] パフォーマンスへの影響が検討されている
   - [ ] セキュリティが考慮されている

レビュー結果を `03_REVIEW.md` に記録：

```markdown
# Review: <work-id>

> Plan: [02_PLAN.md](./02_PLAN.md)
> Reviewed: <timestamp>
> Reviewer: <reviewer>

## Review Summary

<レビュー全体の所見>

## Checklist

### Code Quality
- [x] コードスタイルがプロジェクト規約に準拠
- [x] 適切なエラーハンドリング
- [ ] 不要なコメント・デバッグコードの除去

### Functionality
- [x] 仕様通りに動作する
- [ ] エッジケースが考慮されている
- [x] パフォーマンスに問題がない

...

## Findings

### Must Fix (Blocking)

| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | Step 2 | DB接続のエラーハンドリングが不足 | try-catch の追加 |

### Should Fix (Non-blocking)

| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | Step 1 | 変数名が不明確 | より説明的な名前に変更 |

### Suggestions (Optional)

- ログ出力の追加を検討

## Decision

**Status:** Request Changes

**Comments:**
Step 2 のエラーハンドリングを追加後、再レビューしてください。

## Follow-up Actions

- [ ] Step 2 にエラーハンドリングを追加
```

### 3. Code レビュー

実装済みコードのレビュー：

```bash
# 変更されたファイルを確認
git diff <base_branch>...HEAD --name-only

# 差分を確認
git diff <base_branch>...HEAD
```

レビュー観点：
- コードスタイル
- エラーハンドリング
- テストカバレッジ
- セキュリティ
- パフォーマンス

### 4. PR レビュー

GitHub PR の状態を確認：

```bash
branch=$(jq -r ".works[\"$work_id\"].git.branch" .wf/state.json)
gh pr view --json number,state,reviews,checks
```

表示内容：
```
📋 PR Review Status: <work-id>
═══════════════════════════════════════

PR: #<number> - <title>
State: <open/closed/merged>

Checks:
- [✓] CI/CD Pipeline
- [✓] Code Coverage
- [→] Security Scan (running)

Reviews:
- @reviewer1: Approved
- @reviewer2: Changes Requested

Comments: 5

Blocking Issues:
- Security Scan が完了していません

次のアクション:
- Security Scan の完了を待ってください
```

### 5. state.json の更新

```bash
# レビュー完了時
jq ".works[\"$work_id\"].current = \"wf4-review\"" .wf/state.json > tmp && mv tmp .wf/state.json

# 承認された場合
jq ".works[\"$work_id\"].next = \"wf5-implement\"" .wf/state.json > tmp && mv tmp .wf/state.json

# 変更要求の場合
jq ".works[\"$work_id\"].next = \"wf3-plan\"" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 6. 完了メッセージ

```
✅ レビューが完了しました

ファイル: docs/wf/<work-id>/03_REVIEW.md

結果: <Approved / Request Changes / Needs Discussion>

Findings:
- Must Fix: 1
- Should Fix: 2
- Suggestions: 3

次のステップ:
- Approved: /wf5-implement を実行
- Request Changes: 指摘事項を修正後、再度 /wf4-review
```

## 注意事項

- レビュー結果は必ず記録
- Must Fix は解決必須として扱う
- レビュアーの名前を記録
- 複数回のレビューは履歴として残す
