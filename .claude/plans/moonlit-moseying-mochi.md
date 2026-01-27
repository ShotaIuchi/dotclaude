# Plan: wf0-batch 廃止 & wf0-nexttask 新設

## 概要

ワークフローのタスク管理を簡素化：
- `wf0-schedule`: タスクの依存関係を分析し、実行順番を決定（現状維持）
- `wf0-batch`: 廃止（daemon+worker並列実行アーキテクチャを削除）
- `wf0-nexttask`: 新設（スケジュールから次のタスクを取得・実行）

## wf0-nexttask の仕様

### 基本動作

```
/wf0-nexttask [options]
```

1. `schedule.json`から依存解決済みの次のタスクを取得
2. タスク情報を表示
3. 実行範囲を提案し、ユーザーに選択させる
4. 選択した範囲まで自動実行

### オプション

| オプション | 説明 |
|-----------|------|
| `--dry-run` | タスク情報を表示するのみ、実行しない |
| `--until <phase>` | 指定フェーズまで自動実行（選択をスキップ） |
| `--all` | 全タスク完了まで自動実行（選択をスキップ） |

### 実行範囲の提案

タスク選択後、以下のブレークポイントを提案：

```
📋 Next Task: FEAT-123-auth
═══════════════════════════════════════

Source:       github #123
Title:        Add user authentication
Dependencies: FEAT-100-database (completed)

═══════════════════════════════════════

Where would you like to stop?

  1. wf1-kickoff only (Start work)
  2. Until wf3-plan (Design complete)
  3. Until wf4-review (Review complete)
  4. Until wf6-verify (Task complete)
  5. Complete all remaining tasks (3 tasks)

Select [1-5]:
```

### 未完了タスクの通知

タスク完了後、残りのタスクがある場合は通知：

```
═══════════════════════════════════════
✅ FEAT-123-auth completed!

Remaining tasks: 2
  - FEAT-124-export (ready)
  - FEAT-125-api (blocked by FEAT-124-export)

Run '/wf0-nexttask' for the next task
═══════════════════════════════════════
```

## 削除するファイル

| ファイル | 理由 |
|----------|------|
| `commands/wf0-batch.md` | 廃止 |
| `scripts/batch/batch-daemon.sh` | 並列実行廃止 |
| `scripts/batch/batch-worker.sh` | 並列実行廃止 |
| `scripts/batch/batch-utils.sh` | 一部関数はwf0-nexttaskに移植 |
| `skills/wf0-batch/SKILL.md` | 廃止 |
| `docs/readme/commands.wf0-batch.md` | ドキュメント削除 |

## 更新するファイル

| ファイル | 変更内容 |
|----------|----------|
| `commands/wf0-schedule.md` | `/wf0-batch start` → `/wf0-nexttask` への参照更新 |
| `skills/README.md` | wf0-batch削除、wf0-nexttask追加 |
| `examples/config.json` | `batch.default_parallel`, `batch.max_parallel` 削除 |

## 作成するファイル

| ファイル | 内容 |
|----------|------|
| `commands/wf0-nexttask.md` | コマンド仕様 |
| `skills/wf0-nexttask/SKILL.md` | スキル定義 |
| `docs/readme/commands.wf0-nexttask.md` | 日本語ドキュメント |

## schedule.json への影響

### 削除するフィールド

```json
{
  "execution": {
    "max_parallel": 3,      // 削除
    "sessions": { ... }      // 削除
  }
}
```

### 追加するフィールド

```json
{
  "works": {
    "FEAT-123-auth": {
      "started_at": "2026-01-27T10:00:00Z",   // 追加
      "completed_at": "2026-01-27T12:00:00Z"  // 追加
    }
  }
}
```

## 実装ステップ

### Step 1: wf0-nexttask.md 作成
- コマンド仕様の定義
- 処理フロー（タスク取得、範囲提案、実行）
- ヘルパー関数（batch-utils.shから移植）

### Step 2: skills/wf0-nexttask/SKILL.md 作成
- スキル定義
- references設定

### Step 3: wf0-schedule.md 更新
- wf0-batch への参照を wf0-nexttask に変更
- schedule.json スキーマから execution.sessions を削除

### Step 4: wf0-batch 関連ファイル削除
- commands/wf0-batch.md
- scripts/batch/*.sh
- skills/wf0-batch/

### Step 5: config.json 更新
- batch.default_parallel, batch.max_parallel 削除

### Step 6: ドキュメント更新
- skills/README.md
- docs/readme/ 内の関連ファイル

## 検証方法

1. `/wf0-schedule create github="label:test"` でスケジュール作成
2. `/wf0-nexttask --dry-run` でタスク情報表示を確認
3. `/wf0-nexttask` で範囲選択UIが表示されることを確認
4. 選択した範囲まで正しく実行されることを確認
5. 完了後、残りタスクの通知が表示されることを確認

## 重要な設計判断

### wf0-nextstep との役割分担

| コマンド | 役割 | スコープ |
|----------|------|----------|
| `wf0-nextstep` | フェーズ遷移 | 1つのwork内 (wf1→wf2→...→wf6) |
| `wf0-nexttask` | タスク選択・実行 | schedule.json内の複数work |

### 内部処理フロー

```
wf0-nexttask
  ├─ schedule.json から次のタスクを取得
  ├─ 実行範囲を提案・選択
  └─ 選択に応じて処理
       ├─ wf1-kickoff only → /wf1-kickoff 実行して終了
       └─ wfN まで → /wf1-kickoff 実行 → /wf0-nextstep 繰り返し
```

## 関連ファイル

- `/Users/si/dot/dotclaude/dotclaude/commands/wf0-nextstep.md` - 参考: フェーズ遷移コマンド
- `/Users/si/dot/dotclaude/dotclaude/commands/wf0-schedule.md` - 更新対象
- `/Users/si/dot/dotclaude/dotclaude/commands/wf0-batch.md` - 削除対象
- `/Users/si/dot/dotclaude/dotclaude/scripts/batch/*.sh` - 削除対象
