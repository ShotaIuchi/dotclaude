# /wf0-schedule

バッチワークフロー実行用のスケジュール管理コマンド。
複数のIssue/Jira/Localワークを読み込み、依存関係を分析してスケジュールを作成する。

## 使用方法

```
/wf0-schedule <サブコマンド> [引数...]
```

## サブコマンド

| サブコマンド | 説明 |
|-------------|------|
| `create [sources...]` | 指定ソースからスケジュールを作成 |
| `show` | 現在のスケジュールを表示 |
| `edit [work-id]` | 優先順位・依存関係を編集 |
| `validate` | スケジュールを検証（循環依存チェック） |
| `clear` | 現在のスケジュールを削除 |

## ソース指定

### GitHub Issue

```bash
# ラベルで指定
/wf0-schedule create github="label:scheduled"
/wf0-schedule create github="label:batch,milestone:v1.0"
```

### Jira Issue

```bash
# JQLクエリで指定
/wf0-schedule create jira="project=PROJ AND sprint=current"
```

### ローカルワーク

```bash
# カンマ区切りで指定
/wf0-schedule create local=FEAT-001,FIX-002
```

### 複合指定

```bash
# 複数ソース
/wf0-schedule create github="label:scheduled" jira="sprint=current"

# config.jsonのbatch.sourcesを使用
/wf0-schedule create --all
```

## 依存関係の自動検出

Issue本文から以下のパターンを検出：

| パターン | 例 |
|----------|-----|
| `depends on #N` | depends on #123 |
| `blocked by #N` | blocked by #456 |
| `requires PROJ-N` | requires PROJ-789 |
| `after: WORK-ID` | after: FEAT-001-auth |

カスタムパターンは`config.json`で設定可能：

```json
{
  "batch": {
    "dependency_patterns": [
      "depends on #(\\d+)",
      "blocked by #(\\d+)"
    ]
  }
}
```

## 出力例

### スケジュール作成

```
📅 Creating Schedule
═══════════════════════════════════════

Sources:
  - github: label:scheduled

Fetching from GitHub (label:scheduled)...
  - #123: Add user authentication
  - #124: Implement export feature
  - #125: Fix login bug

Analyzing dependencies...
  ✅ No circular dependencies

═══════════════════════════════════════
✅ Schedule created: 3 works
```

### スケジュール表示

```
📅 Current Schedule
═══════════════════════════════════════

Status:     pending
Created:    2026-01-26T10:00:00Z

Progress:   0/3 completed
            0 in progress
            3 pending

═══════════════════════════════════════
Works (by priority):

[1] FEAT-100-database
    Status: pending
    Source: github #100
    Deps: (none)

[2] FEAT-123-auth
    Status: pending
    Source: github #123
    Deps: FEAT-100-database
```

### 検証結果

```
🔍 Validating Schedule
═══════════════════════════════════════

Checking circular dependencies...
  ✅ No circular dependencies

Checking dependency references...
  ✅ All dependencies resolved

Checking priority conflicts...
  ✅ No priority conflicts

═══════════════════════════════════════
✅ Validation passed
```

## スケジュールファイル

スケジュールは`.wf/schedule.json`に保存される：

```json
{
  "version": "1.0",
  "status": "pending",
  "works": {
    "FEAT-123-auth": {
      "source": {"type": "github", "id": "123"},
      "priority": 1,
      "dependencies": ["FEAT-100-database"],
      "status": "pending"
    }
  }
}
```

## ワークフロー

1. スケジュール作成: `/wf0-schedule create github="label:batch"`
2. 内容確認: `/wf0-schedule show`
3. 検証: `/wf0-schedule validate`
4. 実行開始: `/wf0-batch start`

## 依存関係

- `gh` CLI（GitHub連携用）
- `jq`（JSON処理）
- Jira連携はAPIトークン設定が必要

## 注意事項

- 循環依存があるスケジュールは作成不可
- 優先順位は依存関係から自動計算
- 編集後は再度validateを推奨
