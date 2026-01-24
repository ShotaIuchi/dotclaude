# /wf5-implement

Planの1ステップを実装するコマンド。

## 使用方法

```
/wf5-implement [step_number]
```

## 引数

- `step_number`: 実装するステップ番号（省略時: 次の未完了ステップを自動選択）

## 重要な制約

- **計画外の変更禁止**: Planに記載されたステップのみを実装
- **1実行 = 1ステップ**: 1回の実行で1ステップのみ実装

## 処理

1. 前提条件チェック（Planが存在するか確認）
2. 実装対象ステップの決定
3. Planからステップ情報を抽出
4. 依存ステップの完了確認
5. 実装作業
6. 実装ログに記録
7. `state.json`更新
8. 完了条件の確認
9. コミット

## コミットタイプの自動判定

- `bug`, `fix`, `repair` → `fix`
- `refactor` → `refactor`
- `test` → `test`
- `doc`, `documentation` → `docs`
- その他 → `feat`

## 完了メッセージ

```
✅ Step <n> completed

Changed Files:
- <file1> (+10, -5)
- <file2> (+3, -0)

Completion Criteria:
- [✓] <condition1>
- [✓] <condition2>

Progress: <n>/<total> steps completed

Next step:
- If remaining steps exist: /wf5-implement
- All steps complete: /wf6-verify
```

## 計画外変更について

1. **軽微な修正**（タイポ、import追加など）: 実装ログのNotes欄に記録して続行
2. **大きな変更**（設計変更、機能追加など）: 実装を中断しPlan更新を提案

## 注意事項

- **1回の実行で1ステップのみ**
- **計画外変更は原則禁止**
- 依存ステップが未完了ならエラー
- テスト失敗は完了前に修正
