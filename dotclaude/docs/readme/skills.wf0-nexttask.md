# /wf0-nexttask

スケジュールから次のタスクを選択して実行するコマンド。
依存関係が解決されたタスクを取得し、ワークフローフェーズを実行する。

## 使用方法

```
/wf0-nexttask [オプション]
```

## オプション

| オプション | 説明 |
|----------|------|
| `--dry-run` | タスク情報を表示のみ、実行しない |
| `--until <phase>` | 指定フェーズまで自動実行（選択をスキップ） |
| `--all` | 全タスク完了まで自動実行（選択をスキップ） |

## 実行範囲の選択

オプションなしで実行すると、以下の選択肢が表示される：

| 選択肢 | 説明 |
|--------|------|
| wf1-kickoff only | 作業開始のみ、レビュー用に一時停止 |
| Until wf3-plan | 設計フェーズまで完了 |
| Until wf4-review | レビューフェーズまで完了 |
| Until wf6-verify | タスク全体を完了 |
| Complete all tasks | スケジュール内の全タスクを実行 |

## wf0-nextstep との違い

| コマンド | スコープ | 役割 |
|---------|----------|------|
| `/wf0-nextstep` | フェーズ | 1つのwork内でのフェーズ遷移（wf1→wf2→...→wf6） |
| `/wf0-nexttask` | タスク | schedule.json内の複数workから次を選択・実行 |

## 出力例

### タスク表示

```

Next Task: FEAT-123-auth

Source:       github #123
Title:        Add user authentication
Dependencies: FEAT-100-database (completed)

Where would you like to stop?

  1. wf1-kickoff only (Start work)
  2. Until wf3-plan (Design complete)
  3. Until wf4-review (Review complete)
  4. Until wf6-verify (Task complete)
  5. Complete all remaining tasks

Select [1-5]:
```

### 完了通知

```

Task FEAT-123-auth completed!

Remaining tasks: 2
  Ready:
    - FEAT-124-export
  Blocked:
    - FEAT-125-api (blocked by: FEAT-124-export)

Run '/wf0-nexttask' for the next task
```

### ドライラン

```

Next Task: FEAT-123-auth

Source:       github #123
Title:        Add user authentication
Dependencies: FEAT-100-database (completed)

Schedule Progress:
  Completed: 1/5
  Pending:   4

(Dry run mode - no execution)
```

## 使用例

### 基本的な使用

```bash
# 次のタスクを実行
/wf0-nexttask

# 実行せずにプレビュー
/wf0-nexttask --dry-run

# 計画フェーズまで実行
/wf0-nexttask --until wf3-plan

# 全タスク実行
/wf0-nexttask --all
```

### バッチ処理のワークフロー

```bash
# GitHub Issueからスケジュール作成
/wf0-schedule create github="label:scheduled"

# タスクを1つずつ実行
/wf0-nexttask  # 最初のタスク
/wf0-nexttask  # 2番目のタスク
# ... 繰り返し

# または一括実行
/wf0-nexttask --all
```

## 内部フロー

```
wf0-nexttask
  |-- schedule.json から次のタスクを取得
  |-- 実行範囲を提案・選択
  +-- 選択に応じて実行
       |-- wf1-kickoff only -> /wf1-kickoff のみ実行
       +-- wfN まで -> /wf1-kickoff -> /wf0-nextstep (繰り返し)
```

## 注意事項

- スケジュールは事前に `/wf0-schedule create` で作成が必要
- タスクは依存関係を考慮して優先度順に実行される
- `--dry-run` で実行せずにプレビュー可能
- `--until <phase>` で選択プロンプトをスキップ
- `--all` で残り全タスクを自動実行
- `--all` 実行時は最大50タスクの制限あり（安全のため）
