# /wf0-remote

GitHub Issueコメント経由でのリモートワークフロー操作コマンド。モバイルからの承認をPCデーモンが実行。

## 使用方法

```
/wf0-remote start [target...]
/wf0-remote stop [target...]
/wf0-remote status
```

## ターゲット指定

- `<work-id>...`: 1つ以上のwork ID
- `--all`: GitHub sourceの全work
- `<pattern>`: ワイルドカード（例: `FEAT-*`）
- 省略時: active_workを使用

## リモートコマンド（Issueコメント）

| コマンド | 説明 |
|---------|------|
| `/approve` or `/next` | 次のワークフローステップを実行 |
| `/pause` | 監視を一時停止 |
| `/stop` | 監視を完全停止 |

## セキュリティ

- コラボレーター権限（admin/write/maintain）のみ処理
- セッション最大10ステップ
- 実行は `/wf0-nextstep` のみ
- 詳細は `rules/remote-operation.md` 参照
