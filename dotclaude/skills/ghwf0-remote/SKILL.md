---
name: ghwf0-remote
description: GitHub Issue/PR のラベル監視デーモン制御
argument-hint: "<start|stop|status>"
---

**Always respond in Japanese. Write all workflow documents (*.md) in Japanese.**

# /ghwf0-remote

GitHub Issue/PR のラベルを監視し、ワークフローを自動実行するデーモンを制御する。

## Usage

```
/ghwf0-remote start    # デーモン起動
/ghwf0-remote stop     # デーモン停止
/ghwf0-remote status   # 状態確認
```

## Label Schema

### Opt-in Label (Required)

| Label | Description |
|-------|-------------|
| `ghwf` | デーモン監視を有効化（必須） |

**Note**: `ghwf` ラベルがないIssueは、コマンドラベルがあっても無視されます。

### State Labels (Daemon Managed)

| Label | Description |
|-------|-------------|
| `ghwf:executing` | 実行中 |
| `ghwf:waiting` | 承認待ち |
| `ghwf:completed` | 完了 |

### Command Labels (User Assigned)

| Label | Description | Requires Update |
|-------|-------------|-----------------|
| `ghwf:exec` | 次ステップを実行 | No |
| `ghwf:redo` | 現在ステップ再実行 | Yes |
| `ghwf:redo-N` | step N から再実行 | Yes |
| `ghwf:revision` | wf1 から全体再実行 | Yes |
| `ghwf:stop` | 監視停止 | No |

### Progress Labels (Daemon Managed)

`ghwf:step-1` 〜 `ghwf:step-7`

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `POLL_INTERVAL` | 60 | Polling interval in seconds |
| `MAX_STEPS_PER_SESSION` | 0 (unlimited) | Max workflow steps before daemon pauses |
| `VERBOSE` | false | Enable detailed logging |

### Retry Settings

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `GHWF_RETRY_MAX` | 3 | Max retry attempts for API calls |
| `GHWF_RETRY_DELAY` | 5 | Initial retry delay (seconds) |
| `GHWF_RETRY_BACKOFF` | 2 | Backoff multiplier |
| `GHWF_CLAUDE_RETRY_MAX` | 2 | Max retries for Claude calls |
| `GHWF_CLAUDE_RETRY_DELAY` | 30 | Initial delay for Claude retries |

Example:
```bash
GHWF_RETRY_MAX=5 MAX_STEPS_PER_SESSION=20 /ghwf0-remote start
```

## Daemon Behavior

### Polling (60秒間隔)

```
1. Query: Issues/PRs with ghwf + ghwf:* command labels
2. For each:
   a. ghwf:exec → 次ステップ実行
   b. ghwf:redo* → 更新チェック → step N から実行
   c. ghwf:revision → 更新チェック → step 1 から実行
   d. ghwf:stop → 監視停止
3. ラベル更新
4. Push
```

### Update Detection (redo*/revision)

以下のいずれかの更新がなければ待機:

1. Issue/PR に新しいコメント (bot 除く)
2. Issue 本文の更新
3. PR レビューコメント

Bot コメントの判定:
- author: `github-actions[bot]}`
- body が `🤖` で始まる

## Processing

### start

1. Check prerequisites: `gh auth status`, `tmux`
2. Launch tmux session `ghwf-daemon`
3. Run `~/.claude/scripts/ghwf/ghwf-daemon.sh`
4. Confirm startup

### stop

1. Kill tmux session `ghwf-daemon`
2. Confirm shutdown

### status

Check commands:
```bash
# Daemon status
tmux ls 2>&1 | grep -E "ghwf-daemon"

# Active Claude process
ps aux | grep -E "claude.*ghwf" | grep -v grep

# Current execution info (if running)
cat .wf/ghwf-current.json 2>/dev/null

# Claude output log (stream-json format)
cat .wf/ghwf-claude.log 2>/dev/null | tail -50

# Recent daemon log
tmux capture-pane -t ghwf-daemon -p -S -20
```

Display (table format):

```
ghwf-daemon ステータス
┌──────────────────┬───────────────────────────┐
│       項目       │           状態            │
├──────────────────┼───────────────────────────┤
│ デーモン         │ ✅ 実行中                 │
│ tmux session     │ ghwf-daemon               │
│ 起動時刻         │ 2026-02-02 11:32:31 (JST) │
│ 最終ポーリング   │ 2026-02-02 11:32:36 (JST) │
│ 実行済みステップ │ 0                         │
└──────────────────┴───────────────────────────┘

実行中のClaudeプロセス
┌───────────┬──────────────────────────────────────┐
│   項目    │                 状態                 │
├───────────┼──────────────────────────────────────┤
│ コマンド  │ /ghwf1-kickoff revise                │
│ 対象      │ Issue #1                             │
│ 実行時間  │ 21秒                                 │
│ CPU使用率 │ 2.3%                                 │
└───────────┴──────────────────────────────────────┘

監視中のワーク
- なし

Claude詳細出力 (直近)
{"type":"tool_use","name":"Read","input":{"file_path":"/path/to/file"}}
{"type":"tool_result","content":"file contents..."}
{"type":"text","content":"ファイルを読み込みました。"}

最近のログ (直近10行)
[2026-02-02 11:32:31] Polling for ghwf:* labels...
[2026-02-02 11:32:35] Processing issue #1 with label: ghwf:revision
[2026-02-02 11:32:36] Executing step 1: ghwf1-kickoff
```

If no Claude process running, show:
```
実行中のClaudeプロセス
なし（待機中）

Claude詳細出力
なし（実行中のプロセスがありません）
```

## State Files

### `.wf/ghwf-state.json` (Daemon state)

```json
{
  "daemon": {
    "enabled": true,
    "started_at": "2026-01-31T10:00:00Z",
    "last_poll": "2026-01-31T10:05:00Z",
    "tmux_session": "ghwf-daemon"
  },
  "works": {
    "<work-id>": {
      "issue": 123,
      "pr": 456,
      "current_step": 3,
      "last_execution": "2026-01-31T10:00:00Z"
    }
  }
}
```

### `.wf/ghwf-current.json` (Current execution)

Claude実行中のみ存在。実行完了時に削除される。

```json
{
  "step": 1,
  "command": "ghwf1-kickoff",
  "mode": "revise",
  "issue": 1,
  "started_at": "2026-02-02T02:32:36Z",
  "pid": 12345
}
```

### `.wf/ghwf-claude.log` (Claude output)

`claude --print --output-format stream-json` の出力。
各行がJSONオブジェクト（tool_use, tool_result, text等）。

```
{"type":"tool_use","name":"Read","input":{"file_path":"..."}}
{"type":"tool_result","content":"..."}
{"type":"text","content":"処理完了"}
```

## Security

| Rule | Description |
|------|-------------|
| Collaborator-only | `admin`/`write`/`maintain` 権限のみ |
| Command whitelist | `ghwf:*` ラベルのみ処理 |
| Bot ignore | 自動コメントは更新判定から除外 |
