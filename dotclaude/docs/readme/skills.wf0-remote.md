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

## Auto モード

未対応のGitHub Issueを自動検出してノンストップで実行するモード。

### 使用方法

```
/wf0-remote auto              # 自動検出モード開始
/wf0-remote auto stop         # 停止
/wf0-remote auto status       # 状態確認
/wf0-remote auto --max 3      # 最大3件処理
/wf0-remote auto --dry-run    # 実行せずIssue一覧表示
/wf0-remote auto --once       # 1件だけ処理して終了
```

### オプション

| オプション | 説明 |
|-----------|------|
| `--max <N>` | 最大処理件数（デフォルト: 5） |
| `--cooldown <MIN>` | Issue間の待機分（デフォルト: 5） |
| `--dry-run` | 実行せずにIssue確認のみ |
| `--once` | 1件処理後終了 |

### 動作フロー

1. `auto-workflow` ラベル付きのIssueを検索
2. 古い順に1件選択、ブランチ作成
3. `/wf1-kickoff` → `/wf0-nextstep` ループ実行
4. 成功時: `completed` ラベル追加
5. 失敗時: Issueにエラーコメント、スキップ
6. クールダウン後、次のIssueへ

### 設定

`.wf/config.json`:

```json
{
  "auto": {
    "query": "auto-workflow",
    "exclude_labels": ["blocked", "wip"],
    "complete_label": "completed",
    "max_issues": 5,
    "cooldown_minutes": 5
  }
}
```

## セキュリティ

- コラボレーター権限（admin/write/maintain）のみ処理
- セッション最大10ステップ
- 実行は `/wf0-nextstep` のみ
- 詳細は `rules/remote-operation.md` 参照
