# /wf0-status

ワークフローの現在状態を表示するコマンド。

## 使用方法

```
/wf0-status [work-id | all]
```

## 処理

- **単一work**: work-id、ブランチ、ベース、現在/次フェーズ、ドキュメント存在確認（00-05）、フェーズ進捗、git状態を表示
- **all**: 全workのテーブル表示（Work ID、Branch、Current、Next）
- worktree有効時: worktreeパスも表示

## 注意事項

- state.json未存在時は初期化を案内
- active_work未設定時はメッセージ表示
