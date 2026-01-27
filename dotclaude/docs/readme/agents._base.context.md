# 共通コンテキスト

全てのサブエージェントが共有する基本コンテキスト。

## 目的・概要

このドキュメントは、WF（ワークフロー）管理システムの概要と、サブエージェントが参照すべき共通情報を提供します。ファイル構造、state.json の読み方、ワークフローの順序、コンテキスト共有の方法などを定義しています。

## WF管理システム概要

このシステムは、AI（Claude Code）と人間が同じ状態とアーティファクトを見ながら作業するためのワークフロー管理システムです。

### 基本原則

1. **状態の共有**: AIと人間が同じ作業状態を把握
2. **統一されたアーティファクト管理**: ドキュメントとコードを連携して管理
3. **作業の再現性**: 異なるPCやセッションで作業を継続可能
4. **計画外変更の防止**: 計画された作業のみを実装
   - `state.json` での `03_PLAN.md` ステップ追跡により強制
   - 各実装ステップは計画された項目と一致する必要がある
   - 実装制約については `commands/wf5-implement.md` を参照

## ファイル構造

### 設定ファイル

```
.wf/
├── config.json      # 共有設定（コミット対象）
├── state.json       # 共有状態（コミット対象）
└── local.json       # ローカル設定（gitignore対象）
```

#### local.json

環境固有の設定用にgitignoreされるローカル設定ファイル:

```json
{
  "editor": "code",           // 優先エディタコマンド
  "terminal": "iterm2",       // ターミナルアプリケーション
  "browser": "chrome",        // プレビュー用デフォルトブラウザ
  "notifications": true,      // デスクトップ通知を有効化
  "auto_commit": false,       // ワークフロー完了時に自動コミット
  "debug": false              // デバッグ出力を有効化
}
```

このファイルにより、個々の開発者が共有設定に影響を与えずにローカルワークフロー体験をカスタマイズできます。

### ドキュメント

```
docs/wf/<work-id>/
├── 01_KICKOFF.md        # 目標と成功基準の定義
├── 02_SPEC.md           # 変更仕様
├── 03_PLAN.md           # 実装計画
├── 04_REVIEW.md         # レビュー記録
├── 05_IMPLEMENT_LOG.md  # 実装ログ
└── 06_REVISIONS.md      # 変更履歴
```

## 状態の読み取り

### state.json

```json
{
  "active_work": "<work-id>",
  "works": {
    "<work-id>": {
      "current": "wf5-implement",
      "next": "wf6-verify",
      "git": {
        "base": "develop",
        "branch": "feat/123-export-csv"
      },
      "kickoff": {
        "revision": 2,
        "last_updated": "2026-01-17T14:30:00+09:00"
      },
      "plan": {
        "total_steps": 5,
        "current_step": 3
      },
      "agents": {
        "last_used": "research",
        "sessions": {}
      }
    }
  }
}
```

#### agents.sessions

`sessions` オブジェクトは、現在の作業におけるサブエージェントの実行履歴とコンテキストを追跡します:

```json
"sessions": {
  "research": {
    "started_at": "2026-01-17T10:00:00+09:00",
    "completed_at": "2026-01-17T10:15:00+09:00",
    "status": "completed",
    "output_ref": "docs/wf/<work-id>/research_output.md"
  },
  "planner": {
    "started_at": "2026-01-17T10:20:00+09:00",
    "status": "in_progress"
  }
}
```

これにより以下が可能になります:
- 中断されたエージェントセッションの再開
- 呼び出されたエージェントの追跡
- 以前のエージェント実行からの出力の参照

### 読み取り方法

```bash
# アクティブな作業IDを取得
work_id=$(jq -r '.active_work // empty' .wf/state.json)

# 作業詳細を取得
jq ".works[\"$work_id\"]" .wf/state.json

# ドキュメントパス
docs_dir="docs/wf/$work_id"
```

## Issue情報の取得

```bash
# work-idからIssue番号を抽出
# work-id形式: <type>-<issue_number>-<description>
# 例: feat-123-export-csv → 123を抽出
issue_number=$(echo "$work_id" | sed 's/^[^-]*-\([0-9]*\)-.*/\1/')

# cutを使用した代替方法（形式が一貫している場合はよりシンプル）:
# issue_number=$(echo "$work_id" | cut -d'-' -f2)

# GitHub CLIでIssue情報を取得
gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone
```

## ワークフロー順序

```
wf1-kickoff → wf1-kickoff → wf2-spec → wf3-plan → wf4-review → wf5-implement → wf6-verify
```

各フェーズで生成されるドキュメント:

| フェーズ | ドキュメント |
|----------|-------------|
| wf1-kickoff | 01_KICKOFF.md |
| wf2-spec | 02_SPEC.md |
| wf3-plan | 03_PLAN.md |
| wf4-review | 04_REVIEW.md |
| wf5-implement | 05_IMPLEMENT_LOG.md |
| wf1-kickoff（更新） | 06_REVISIONS.md |

### 06_REVISIONS.md の管理

`06_REVISIONS.md` ファイルはキックオフドキュメントへの変更を追跡します:

- **作成時**: 既存の作業に `--update` フラグ付きで `wf1-kickoff` を実行した場合
- **更新時**: 後続のキックオフリビジョンごとに新しいエントリを追加
- **目的**: 開発中のスコープ/目標変更の監査証跡を維持
- **形式**: リビジョン番号、タイムスタンプ、変更概要、更新理由を含む

## 設定リファレンス

### config.json

リポジトリにコミットされる共有設定ファイル:

```json
{
  "version": "1.0",
  "project": {
    "name": "project-name",
    "default_branch": "main"
  },
  "workflow": {
    "require_review": true,       // 実装前にwf4-reviewを必須とする
    "auto_create_branch": true,   // キックオフ時にgitブランチを自動作成
    "docs_path": "docs/wf"        // ワークフロードキュメントのパス
  },
  "agents": {
    "enabled": ["research", "planner", "implementer"],
    "timeout": 300                // エージェント実行タイムアウト（秒）
  }
}
```

## エラーハンドリング

### state.jsonが存在しない場合

`state.json` が存在しないか無効な場合:

```bash
# stateファイルの存在確認
if [ ! -f .wf/state.json ]; then
  echo "Error: .wf/state.json not found. Run 'wf1-kickoff' to initialize."
  exit 1
fi

# JSON形式の検証
if ! jq empty .wf/state.json 2>/dev/null; then
  echo "Error: .wf/state.json is not valid JSON"
  exit 1
fi

# アクティブな作業の確認
work_id=$(jq -r '.active_work // empty' .wf/state.json)
if [ -z "$work_id" ]; then
  echo "No active work. Run 'wf1-kickoff' to start a new work item."
  exit 1
fi
```

### 一般的なエラーシナリオ

| シナリオ | 対処 |
|----------|------|
| `.wf/` ディレクトリがない | `wf1-kickoff` を実行して初期化 |
| state.json のJSONが無効 | 構文エラーを確認、必要に応じてgitから復元 |
| active_work が未設定 | `wf1-kickoff` または `wf0-restore` を実行 |
| ワークフロードキュメントがない | `docs/wf/<work-id>/` パスを確認、復元が必要な場合あり |

## サブエージェントのコンテキスト共有

### コンテキストの継承

サブエージェントは階層構造を通じてコンテキストを継承します:

1. **ベースコンテキスト**（このドキュメント）: 全サブエージェントで共有
2. **カテゴリコンテキスト**: エージェントカテゴリ内で共有（analysis, task, workflow）
3. **エージェント固有コンテキスト**: 各エージェントに固有

### エージェント間のコンテキスト受け渡し

あるエージェントが別のエージェントを呼び出す場合:

```json
{
  "parent_agent": "research",
  "context": {
    "work_id": "<work-id>",
    "findings": ["..."],
    "recommendations": ["..."]
  },
  "handoff_reason": "Analysis complete, ready for planning"
}
```

受け取り側のエージェントは `state.json` 経由で親コンテキストにアクセスできます:

```bash
# 親エージェントの出力参照を取得
parent_output=$(jq -r ".works[\"$work_id\"].agents.sessions.research.output_ref" .wf/state.json)
```
