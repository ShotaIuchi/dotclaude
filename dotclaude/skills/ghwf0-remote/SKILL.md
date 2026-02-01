---
name: ghwf0-remote
description: GitHub Issue/PR のラベル監視デーモン制御
argument-hint: "<start|stop|status>"
---

**Always respond in Japanese.**

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
| `MAX_STEPS_PER_SESSION` | 10 | Max workflow steps before daemon pauses |
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

Display:
- Daemon running status
- Active works being monitored
- Last poll time

## State File

`.wf/ghwf-state.json`:

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

## Security

| Rule | Description |
|------|-------------|
| Collaborator-only | `admin`/`write`/`maintain` 権限のみ |
| Command whitelist | `ghwf:*` ラベルのみ処理 |
| Bot ignore | 自動コメントは更新判定から除外 |
