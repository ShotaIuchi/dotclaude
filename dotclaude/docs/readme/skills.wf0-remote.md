# /wf0-remote

GitHub Issueコメントを介したリモートワークフロー操作コマンド。
外出中でも携帯からワークフローを監視・承認し、PCで自動実行できる。

## 使用方法

```
/wf0-remote <サブコマンド> [work-id]
```

## サブコマンド

| サブコマンド | 説明 |
|-------------|------|
| `start [work-id]` | リモート監視を開始（tmuxセッションで起動） |
| `stop [work-id]` | リモート監視を停止 |
| `status` | 現在の監視状態を表示 |

## 引数

- `work-id`: 対象の作業ID（オプション）
  - 省略時: `state.json`の`active_work`を使用

## 仕組み

```
User (携帯)              GitHub Issue              PC (Daemon)
     |                        |                        |
     |-- Issue確認 -----------|                        |
     |<-- 進捗コメント表示 ---|                        |
     |                        |                        |
     |-- `/approve` コメント->|                        |
     |                        |<-- 60秒ごとにポーリング|
     |                        |-- コメント返却 -------->|
     |                        |                        |-- `/approve`検出
     |                        |                        |-- Claude Code起動
     |                        |                        |-- wf0-nextstep実行
     |                        |                        |-- git push
     |                        |<-- 結果コメント投稿 ---|
     |<-- 通知 --------------|                        |
```

## Issueコメントで使用できるコマンド

| コマンド | 説明 |
|----------|------|
| `/approve` | 次のワークフローステップを実行 |
| `/next` | `/approve`と同じ |
| `/pause` | 監視を一時停止（`/approve`で再開） |
| `/stop` | 監視を完全停止 |

## 処理内容

### start

1. 対象work-idのソースIssue番号を取得
2. tmuxセッションでデーモンを起動
3. state.jsonにリモート設定を保存
4. 開始メッセージを表示

### stop

1. tmuxセッションを終了
2. state.jsonのリモート設定を無効化
3. 停止メッセージを表示

### status

1. リモート有効な全作業を取得
2. 各作業のステータスを表示
3. tmuxセッションの実行状態を確認

## 出力例

### 開始時

```
🚀 Remote monitoring started for FEAT-123-auth

Session: wf-remote-FEAT-123-auth
Issue: #123

Available commands in Issue comments:
  /approve  - Execute next workflow step
  /next     - Same as /approve
  /pause    - Pause monitoring temporarily
  /stop     - Stop monitoring completely

To view daemon output:
  tmux attach -t wf-remote-FEAT-123-auth
```

### ステータス表示

```
📡 Remote Monitoring Status
═══════════════════════════════════════

Work: FEAT-123-auth
  Issue:      #123
  Status:     waiting_approval
  Session:    wf-remote-FEAT-123-auth (✅ running)
  Last check: 2026-01-24T10:05:00Z
```

### Issue への進捗コメント（自動投稿）

```markdown
## 🤖 wf3-plan 完了

**ステータス**: 待機中（承認待ち）
**次のステップ**: wf4-review

### 成果物
- `docs/wf/FEAT-123/02_PLAN.md` 作成

---
💡 `/approve` で次のステップを実行
```

## セキュリティ

- コラボレーター以外のコメントは無視
- 1セッション最大10ステップ（無限ループ防止）
- `/stop`で即時停止可能
- 詳細は `rules/remote-operation.md` を参照

## 依存関係

- `gh` CLI（認証済み）
- `tmux`（デーモンセッション管理用）
- `jq`（JSON処理）

## 注意事項

- ソースIssueが設定されている作業のみ対象
- デーモンの出力は`tmux attach`で確認可能
- ネットワーク切断時は再接続後に自動継続
