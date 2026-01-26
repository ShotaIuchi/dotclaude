# /wf0-batch

スケジュールされたワークフローのバッチ実行制御コマンド。
worktreeを使用して並列実行し、依存関係を解決しながら処理する。

## 使用方法

```
/wf0-batch <サブコマンド> [オプション...]
```

## サブコマンド

| サブコマンド | 説明 |
|-------------|------|
| `start [--parallel N]` | バッチ実行を開始 |
| `stop [--all \| work-id...]` | 実行を停止 |
| `status` | 実行状況を表示 |
| `resume` | 一時停止/失敗から再開 |

## オプション

| オプション | 説明 |
|----------|------|
| `--parallel N` | 並列ワーカー数（デフォルト: config設定値） |
| `--dry-run` | 実行せずに計画のみ表示 |
| `--all` | 全ワーカーを対象（stop用） |

## 実行アーキテクチャ

```
┌─────────────────────────────────────┐
│ wf-batch-scheduler (tmux)           │
│   - ワークの割り当て                  │
│   - 依存関係の解決                    │
│   - 進捗の更新                       │
└─────────────────────────────────────┘
              │
     ┌────────┼────────┐
     ▼        ▼        ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│worker-1 │ │worker-2 │ │worker-3 │
│(tmux)   │ │(tmux)   │ │(tmux)   │
└─────────┘ └─────────┘ └─────────┘
```

## 実行フロー（完全自動）

`/wf0-batch start` を実行すると、**完全自動**でワークフローが実行される。

```
/wf0-batch start
     ↓
┌─────────────────────────────────────┐
│ 各ワーカーが自動で実行:              │
│                                     │
│  wf1-kickoff → wf2-spec → wf3-plan  │
│  → wf4-review → wf5-implement       │
│  → wf6-verify → push                │
│                                     │
│ 全ワークが完了するまで繰り返す        │
└─────────────────────────────────────┘
     ↓
完了（または失敗で停止）
```

### 人間がやること

| タイミング | 操作 | 目的 |
|------------|------|------|
| 開始時 | `/wf0-batch start` | 実行開始 |
| 任意 | `/wf0-batch status` | 進捗確認 |
| 問題発生時 | `/wf0-batch stop` | 停止 |
| 失敗後 | `/wf0-batch resume` | 再開 |

**開始後は基本的に放置でOK。** 完了またはエラーで自動停止する。

### wf0-remote との違い

| | wf0-batch | wf0-remote |
|---|-----------|------------|
| 承認 | **不要**（完全自動） | 各フェーズで `/approve` 必要 |
| 用途 | 大量の定型タスク処理 | 1件ずつ確認しながら進める |
| 介入 | エラー時のみ | 毎フェーズ |

## worktree構造

```
.worktrees/
├── feat-123-auth/       # 作業中のワーク
│   ├── .git             # worktree gitリンク
│   ├── src/             # プロジェクトファイル
│   └── .wf -> ../.wf    # 共有state
├── feat-124-export/
└── fix-456-login/
```

## 出力例

### 実行開始

```
🚀 Starting Batch Execution
═══════════════════════════════════════

Workers:       3
Pending works: 5

Execution Plan:
───────────────────────────────────────

Priority 1 (1 works):
  - FEAT-100-database

Priority 2 (2 works):
  - FEAT-123-auth <- FEAT-100-database
  - FEAT-125-api <- FEAT-100-database

═══════════════════════════════════════

✅ Scheduler daemon started
✅ Worker 1 started
✅ Worker 2 started
✅ Worker 3 started

Batch execution started!
```

### ステータス表示

```
📊 Batch Execution Status
═══════════════════════════════════════

Progress:
  ✅ Completed:   2
  🔄 In Progress: 2
  ⏳ Pending:     1

Workers:
  📋 Scheduler: ✅ running
  🔧 Worker 1: FEAT-123-auth (running)
  🔧 Worker 2: FEAT-125-api (running)
  🔧 Worker 3: idle

═══════════════════════════════════════
Works in Progress:

  - FEAT-123-auth
    Worktree: .worktrees/feat-123-auth
```

### 停止

```
🛑 Stopping Batch Execution
═══════════════════════════════════════

✅ Stopped:
  - scheduler
  - wf-batch-worker-1
  - wf-batch-worker-2

Use '/wf0-batch resume' to continue execution
```

## 使用例

### 基本的な実行

```bash
# スケジュール作成
/wf0-schedule create github="label:scheduled"

# 2ワーカーで開始
/wf0-batch start --parallel 2

# 進捗確認
/wf0-batch status

# 停止
/wf0-batch stop
```

### 失敗後の再開

```bash
# ステータス確認
/wf0-batch status

# 再開（失敗したワークをリセット）
/wf0-batch resume
```

### ドライラン

```bash
# 実行計画をプレビュー
/wf0-batch start --dry-run
```

## 監視方法

### ログ表示

```bash
# スケジューラーログ
tmux attach -t wf-batch-scheduler

# ワーカーログ
tmux attach -t wf-batch-worker-1
```

## 設定

`config.json`で設定：

```json
{
  "batch": {
    "default_parallel": 2,
    "max_parallel": 5,
    "auto_worktree": true,
    "cleanup_worktree": true
  },
  "worktree": {
    "enabled": true,
    "root_dir": ".worktrees"
  }
}
```

## 依存関係

- `tmux`（セッション管理用）
- `git worktree`（並列作業用）
- `jq`（JSON処理）

## 注意事項

- スケジュールは事前に`/wf0-schedule create`で作成が必要
- 各ワーカーはClaude Code CLIを実行
- 失敗したワークは`/wf0-batch resume`で再試行可能
- worktreeは完了後に自動削除（設定で変更可能）
