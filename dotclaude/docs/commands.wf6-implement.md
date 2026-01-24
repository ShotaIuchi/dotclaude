# /wf6-implement

Planの1ステップを実装するコマンド。

## 使用方法

```
/wf6-implement [step_number]
```

## 引数

- `step_number`: 実装するステップ番号（オプション）
  - 省略時: 次の未完了ステップを自動選択

## 重要な制約

⚠️ **計画外変更の禁止**: このコマンドはPlanに記載されたステップのみを実装
⚠️ **1実行 = 1ステップ**: 1回の実行で1ステップのみ実装

## 処理内容

1. **前提条件チェック**
   - Planドキュメントの存在確認

2. **実装対象ステップの決定**
   - 引数またはstate.jsonから次のステップを取得

3. **ステップ情報の抽出**
   - タイトル、目的、対象ファイル、タスク、完了基準

4. **依存ステップのチェック**
   - 依存ステップが完了しているか確認

5. **実装開始**
   - ステップ情報を表示

6. **実装作業**
   - Planのタスクに従って実装
   - **計画外変更は禁止**
   - テスト実行、失敗時は修正

7. **実装ログの記録**
   - `04_IMPLEMENT_LOG.md`に追記

8. **state.jsonの更新**
   - ステップステータス、current_step更新

9. **完了基準の検証**

10. **コミット**
    - タイプ自動検出: bug/fix→fix、refactor→refactor、test→test、その他→feat

## 出力例

```
✅ Step 2 completed

Changed Files:
- src/services/auth.ts (+50, -10)
- src/types/auth.ts (+20, -0)

Completion Criteria:
- [✓] ログインAPIが動作する
- [✓] トークン生成が正しく動作する

Progress: 2/5 steps completed

Next step:
- If remaining steps exist: /wf6-implement
- All steps complete: /wf7-verify
```

## 計画外変更について

Planに記載されていない変更が必要な場合:

1. **軽微な修正**（タイポ、import追加など）
   → 実装ログのNotesセクションに記録して継続

2. **重要な変更**（設計変更、追加機能など）
   → 実装を中断してPlan更新を提案

```
⚠️ Off-plan changes are needed

Discovered Issue:
- 認証フローにリフレッシュトークンが必要

Suggestion:
- Please update the Plan with /wf4-plan update
```

## 注意事項

- **1回の実行で1ステップのみ**
- **計画外変更は原則禁止**
- 依存ステップが未完了の場合はエラー
- テスト失敗は完了前に修正
- コミットメッセージはConventional Commits形式
