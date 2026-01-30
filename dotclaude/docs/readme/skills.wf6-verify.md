# /wf6-verify

実装の検証を行うコマンド。

## 使用方法

```
/wf6-verify
```

## 処理

1. 前提条件チェック（全ステップ完了確認）
2. テスト/ビルド/Lint実行（config.json優先、なければプロジェクトファイルから自動検出）
3. 成功条件チェック（Kickoffとの比較）
4. 検証サマリー表示（PASS/FAIL）
5. state.json更新
   - PASS時: `current: "wf6-verify"`, `next: "wf7-pr"`
   - FAIL時: `current: "wf6-verify"`, `next: "wf6-verify"`

## 検証失敗時

- 失敗項目を一覧表示
- 修正方法を提案
- 修正後に再度`/wf6-verify`を実行するよう案内

## 注意事項

- 成功条件の未完了項目は警告表示
- 複数回の再実行が可能
- PR作成は検証PASS後に`/wf7-pr`で行う
