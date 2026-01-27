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

1. 前提条件チェック（全ステップ完了確認）
2. テスト/ビルド/Lint実行（config.json優先、なければプロジェクトファイルから自動検出）
3. 成功条件チェック（Kickoffとの比較）
4. 検証サマリー表示（PASS/FAIL）
5. PR作成（prサブコマンド時、検証PASS必須）
6. state.json更新（current: wf6-verify, next: complete）

## 注意事項

- テスト/ビルド失敗時はPR作成不可
- 成功条件の未完了項目は警告表示
- PR作成後も再検証可能
