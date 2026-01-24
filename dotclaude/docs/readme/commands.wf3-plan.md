# /wf3-plan

実装計画（Plan）ドキュメントを作成するコマンド。

## 使用方法

```
/wf3-plan [subcommand]
```

## サブコマンド

- `(なし)`: 新規作成
- `update`: 既存Planを更新
- `step <n>`: 特定ステップの詳細を表示

## 処理

1. 前提条件チェック（Specが存在するか確認）
2. Specの読み込みと分析
3. 詳細なコードベース調査
4. ステップ分割
5. Plan作成
6. ユーザー確認
7. `state.json`更新（current: wf3-plan, next: wf4-review）
8. コミット

## ステップ分割の原則

- 1ステップ = 1回の`/wf5-implement`実行
- 変更行数: 50-200行程度
- 変更ファイル数: 1-5ファイル程度
- 依存関係を考慮した順序

## 完了メッセージ

```
✅ Plan document created

File: docs/wf/<work-id>/02_PLAN.md

Implementation Steps:
1. <step1_title> (small)
2. <step2_title> (medium)
3. <step3_title> (small)

Total: 3 steps

Next step:
- If review is needed: /wf4-review
- To start implementation: /wf5-implement
```

## 注意事項

- Specの範囲を超える変更をPlanに含めない
- 実装順序の依存関係を厳密に考慮
- 各ステップは独立してテスト可能な単位とする
