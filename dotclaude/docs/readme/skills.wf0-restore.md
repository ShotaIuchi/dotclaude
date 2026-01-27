# /wf0-restore

既存ワークスペースを復元するコマンド。別PCでの作業再開やworktree再作成に使用。

## 使用方法

```
/wf0-restore [work-id]
```

## 処理

1. work-id解決（引数 → active_work → AskUserQuestionで選択）
2. `git fetch --all --prune`
3. ブランチ復元（ローカル → リモート → エラー）
4. worktree復元（有効時）
5. active_work設定
6. ステータス表示

## 注意事項

- state.json未存在またはwork-id不明の場合はエラー
- worktreeルートディレクトリは自動作成
