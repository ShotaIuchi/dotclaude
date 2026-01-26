# スケジューリングコマンド実装計画

## 概要

複数のIssue/Jira/Localワークフローを読み込み、依存関係を分析し、並行作業を考慮したスケジュールを作成。worktreeを使用して非同期並列実行を行う。

## コマンド構成

| コマンド | 目的 |
|----------|------|
| `wf0-schedule` | スケジュール作成・管理 |
| `wf0-batch` | バッチ実行制御 |

---

## 1. wf0-schedule コマンド

### サブコマンド

```
/wf0-schedule create [sources...]   # スケジュール作成
/wf0-schedule show                   # スケジュール表示
/wf0-schedule edit [work-id]         # 優先順位・依存関係編集
/wf0-schedule validate               # 検証（循環依存チェック等）
/wf0-schedule clear                  # スケジュール削除
```

### ソース指定例

```bash
/wf0-schedule create github="label:scheduled"
/wf0-schedule create jira="project=PROJ AND sprint=current"
/wf0-schedule create local=FEAT-001,FIX-002
/wf0-schedule create --all  # config.jsonの設定から全取得
```

### 依存関係自動検出パターン

Issue本文から以下のパターンを検出：
- `depends on #123`
- `blocked by #456`
- `requires PROJ-789`
- `after: FEAT-001`

---

## 2. wf0-batch コマンド

### サブコマンド

```
/wf0-batch start [--parallel N]  # 実行開始（デフォルト並列数は設定による）
/wf0-batch stop [--all | work-id...]  # 実行停止
/wf0-batch status                # 実行状況表示
/wf0-batch resume                # 一時停止/失敗からの再開
```

### 実行方式

- **worktree使用**：各ワークを独立したworktreeで実行
- **並列実行**：依存関係を解決しながら最大N個を同時実行
- **tmuxセッション**：ワーカーとスケジューラーを分離

---

## 3. ファイル構成

### 新規作成ファイル

| ファイル | 説明 |
|----------|------|
| `commands/wf0-schedule.md` | スケジュールコマンド定義 |
| `commands/wf0-batch.md` | バッチコマンド定義 |
| `scripts/batch/batch-daemon.sh` | スケジューラーデーモン |
| `scripts/batch/batch-worker.sh` | ワーカープロセス |
| `scripts/batch/batch-utils.sh` | 共通ユーティリティ |
| `skills/wf0-schedule/SKILL.md` | スキル定義 |
| `skills/wf0-batch/SKILL.md` | スキル定義 |
| `docs/readme/commands.wf0-schedule.md` | 日本語ドキュメント |
| `docs/readme/commands.wf0-batch.md` | 日本語ドキュメント |

### 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `examples/config.json` | batch設定セクション追加 |
| `examples/state.json` | schedule_id参照追加 |

---

## 4. schedule.json スキーマ

```json
{
  "version": "1.0",
  "created_at": "2026-01-26T10:00:00Z",
  "status": "pending|running|paused|completed",
  "sources": [
    {"type": "github", "query": "label:scheduled"}
  ],
  "works": {
    "FEAT-123-auth": {
      "source": {"type": "github", "id": "123", "title": "..."},
      "priority": 1,
      "dependencies": ["FEAT-100-database"],
      "status": "pending|running|completed|failed",
      "worktree_path": ".worktrees/feat-123-auth"
    }
  },
  "execution": {
    "max_parallel": 3,
    "sessions": {
      "session-1": {"work_id": "FEAT-100", "status": "running"}
    }
  },
  "progress": {
    "total": 5,
    "completed": 1,
    "in_progress": 2,
    "pending": 2
  }
}
```

---

## 5. 実行フロー

```
/wf0-schedule create github="label:scheduled"
    │
    ├─ GitHub Issueを取得（gh issue list）
    ├─ 依存関係を解析（Issue本文パース）
    ├─ DAG構築、循環検出
    ├─ 優先順位計算
    └─ .wf/schedule.json 保存

/wf0-batch start --parallel 3
    │
    ├─ schedule.json読込・検証
    ├─ tmuxセッション起動
    │   ├─ wf-batch-scheduler（デーモン）
    │   ├─ wf-batch-worker-1
    │   ├─ wf-batch-worker-2
    │   └─ wf-batch-worker-3
    │
    └─ 各ワーカーが独立してワークを実行
        ├─ worktree作成
        ├─ wf1-kickoff → wf6-verify
        ├─ 完了通知 → デーモンが次を割り当て
        └─ 依存解決後に次のワークを開始
```

---

## 6. config.json 追加設定

```json
{
  "batch": {
    "default_parallel": 2,
    "max_parallel": 5,
    "auto_worktree": true,
    "dependency_patterns": [
      "depends on #(\\d+)",
      "blocked by #(\\d+)",
      "requires ([A-Z]+-\\d+)",
      "after: ([A-Z]+-\\d+-\\w+)"
    ]
  }
}
```

---

## 7. 実装順序

| Phase | タスク |
|-------|--------|
| 1 | `wf0-schedule create/show`（単一ソース、依存関係なし） |
| 2 | 依存関係検出・DAG構築・循環チェック |
| 3 | `wf0-batch start/stop/status`（順次実行） |
| 4 | worktree連携・並列実行 |
| 5 | 複数ソース対応（GitHub + Jira + Local） |
| 6 | resume、通知、レポート機能 |

---

## 8. 検証方法

1. **単体テスト**
   - 依存関係パース関数のテスト
   - DAG構築・循環検出のテスト

2. **統合テスト**
   - テスト用Issueを作成してスケジュール生成
   - バッチ実行で複数ワークが正しく処理されるか確認

3. **手動検証**
   ```bash
   # スケジュール作成
   /wf0-schedule create github="label:test-batch"
   /wf0-schedule show

   # バッチ実行（dry-run）
   /wf0-batch start --parallel 2 --dry-run

   # 実際の実行
   /wf0-batch start --parallel 2
   /wf0-batch status
   ```

---

## 9. 主要ファイルパス

- `dotclaude/commands/wf0-schedule.md`
- `dotclaude/commands/wf0-batch.md`
- `dotclaude/scripts/batch/batch-daemon.sh`
- `dotclaude/scripts/batch/batch-worker.sh`
- `dotclaude/scripts/batch/batch-utils.sh`
- `dotclaude/skills/wf0-schedule/SKILL.md`
- `dotclaude/skills/wf0-batch/SKILL.md`
