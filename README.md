# WF Management System

AI（Claude Code）と人間が同じ状態と成果物を見ながら作業するためのワークフロー管理システム。

## 概要

このシステムは以下の課題を解決します：

- **状態の共有**: AIと人間が同じ作業状態を把握
- **成果物の一元管理**: ドキュメントとコードを連携して管理
- **作業の再現性**: 異なるPCやセッションで作業を継続可能
- **計画外変更の防止**: 計画された作業のみを実装

## セットアップ

### 前提条件

以下のツールが必要です：

- `bash` - シェルスクリプト実行
- `jq` - JSON処理
- `gh` - GitHub CLI
- `git` - バージョン管理

### インストール

#### 方法1: amuを使用（推奨）

[amu](https://github.com/ShotaIuchi/amu)を使うと複数のdotclaude設定を簡単に管理できます。

```bash
# 1. このリポジトリをクローン
git clone https://github.com/your-org/dotclaude.git

# 2. ~/.claudeディレクトリでamu addを実行
cd ~/.claude
amu add /path/to/dotclaude/dotclaude
```

#### 方法2: シンボリックリンク

```bash
# 1. このリポジトリをクローン
git clone https://github.com/your-org/dotclaude.git

# 2. dotclaudeを~/.claudeにシンボリックリンク（グローバル設定）
ln -s /path/to/dotclaude/dotclaude ~/.claude

# または、プロジェクト単位で使用
cd your-project
ln -s /path/to/dotclaude/dotclaude .claude
```

### 初期化

```bash
# プロジェクトでWFシステムを初期化
./path/to/dotclaude/scripts/wf-init.sh
```

以下が作成されます：

- `.wf/config.json` - 共有設定
- `.wf/state.json` - 共有状態
- `docs/wf/` - ワークフロードキュメント
- `.gitignore`に`.wf/local.json`を追加

## コマンド一覧

### 環境コマンド (wf0-*)

| コマンド | 説明 |
|---------|------|
| `/wf0-restore [work-id]` | 既存ワークスペースの復元 |
| `/wf0-status [work-id\|all]` | ステータス表示 |
| `/wf0-nextstep [work-id]` | 次のワークフローステップを自動実行 |
| `/wf0-remote <start\|stop\|status> [target...]` | GitHub Issue経由のリモートワークフロー操作 |

### ワークフローコマンド (wf1-6)

| コマンド | 説明 |
|---------|------|
| `/wf1-kickoff github=<n>` | ワークスペース作成＋Kickoff（GitHub Issue） |
| `/wf1-kickoff jira=<id> title="..."` | ワークスペース作成＋Kickoff（Jira） |
| `/wf1-kickoff local=<id> title="..."` | ワークスペース作成＋Kickoff（ローカル） |
| `/wf1-kickoff update` | 既存Kickoffの更新 |
| `/wf1-kickoff revise "<指示>"` | Kickoff修正 |
| `/wf1-kickoff chat` | ブレインストーミング対話 |
| `/wf2-spec` | 仕様書（Spec）作成 |
| `/wf3-plan` | 実装計画（Plan）作成 |
| `/wf4-review [plan\|code\|pr]` | レビュー記録作成 |
| `/wf5-implement [step]` | Planの1ステップを実装 |
| `/wf6-verify` | テスト・ビルド検証 |
| `/wf6-verify pr` | 検証後にPR作成 |

### ユーティリティコマンド

| コマンド | 説明 |
|---------|------|
| `/agent <name> [params]` | サブエージェントを直接呼び出し |
| `/subask <質問>` | サブエージェントに質問（コンテキストを汚さない） |
| `/commit [message]` | コミットメッセージ自動生成＋コミット |
| `/doc-review <file_path>` | ドキュメントレビュー作成 |
| `/doc-fix [file_path...] [--all]` | レビュー指摘の修正適用 |

## ワークフロー

### 基本フロー

```
/wf1-kickoff github=123（ワークスペース＋目標と成功基準を定義）
    ↓
/wf2-spec（変更仕様を作成）
    ↓
/wf3-plan（実装ステップを計画）
    ↓
/wf4-review（任意: 計画レビュー）
    ↓
/wf5-implement（1ステップずつ実装）
    ↓ ↑ 繰り返し
/wf6-verify pr（検証してPR作成）
```

### 自動進行

```bash
# 次のステップを自動実行
/wf0-nextstep
```

### 作業の復元

```bash
# 別のPCで作業を継続
/wf0-restore FEAT-123-export-csv
```

### Kickoffの修正

```bash
# 指示を与えて修正
/wf1-kickoff revise "CSVエクスポートのみにスコープを絞る"
```

### リモート操作

```bash
# GitHub Issueコメントで承認待ちモード
/wf0-remote start FEAT-123-auth

# 複数ワークを同時監視
/wf0-remote start --all
```

## リポジトリ構造

```
dotclaude/                 # リポジトリルート
├── dotclaude/             # ~/.claudeにリンクする対象
│   ├── agents/            # サブエージェント定義
│   ├── commands/          # スラッシュコマンド定義
│   ├── skills/            # アーキテクチャスキル（iOS/Android/KMP/AWS SAM）
│   ├── rules/             # プロジェクトルール・スキーマ
│   ├── guides/            # アーキテクチャガイド
│   ├── examples/          # 設定ファイル例
│   ├── scripts/           # シェルスクリプト
│   └── templates/         # ドキュメントテンプレート
├── .gitignore
└── README.md
```

## ディレクトリ構造

```
your-project/
├── .wf/
│   ├── config.json      # 共有設定（コミット対象）
│   ├── state.json       # 共有状態（コミット対象）
│   └── local.json       # ローカル設定（gitignore）
├── docs/wf/
│   └── FEAT-123-slug/
│       ├── 00_KICKOFF.md
│       ├── 01_SPEC.md
│       ├── 02_PLAN.md
│       ├── 03_REVIEW.md
│       ├── 04_IMPLEMENT_LOG.md
│       └── 05_REVISIONS.md
└── .claude/             # dotclaudeからのシンボリックリンク
    └── commands/        # スラッシュコマンド
        ├── wf1-kickoff.md
        ├── wf0-restore.md
        └── ...
```

## 設定ファイル

### config.json

```json
{
  "default_base_branch": "develop",
  "base_branch_candidates": ["develop", "main", "master"],
  "branch_prefix": {
    "FEAT": "feat",
    "FIX": "fix",
    "REFACTOR": "refactor",
    "CHORE": "chore",
    "RFC": "rfc"
  },
  "worktree": {
    "enabled": false,
    "root_dir": ".worktrees"
  }
}
```

### state.json

```json
{
  "active_work": "FEAT-123-export-csv",
  "works": {
    "FEAT-123-export-csv": {
      "current": "wf5-implement",
      "next": "wf6-verify",
      "source": {
        "type": "github",
        "id": "123",
        "title": "Add CSV export feature"
      },
      "git": {
        "base": "develop",
        "branch": "feat/123-export-csv"
      },
      "plan": {
        "total_steps": 5,
        "current_step": 3
      }
    }
  }
}
```

## サブエージェント

Claude CodeのTaskツールを活用した専門エージェント群。
ワークフローコマンドと連携して動作し、`/agent`コマンドで直接呼び出すことも可能。

### ワークフロー支援型

| エージェント | 目的 | 呼び出し元 |
|-------------|------|-----------|
| `research` | Issue背景調査、関連コード特定 | wf1-kickoff |
| `spec-writer` | 仕様書ドラフト作成 | wf2-spec |
| `planner` | 実装計画立案 | wf3-plan |
| `implementer` | 単一ステップ実装支援 | wf5-implement |

### タスク特化型

| エージェント | 目的 |
|-------------|------|
| `reviewer` | コードレビュー |
| `test-writer` | テスト作成 |
| `refactor` | リファクタリング提案 |
| `doc-writer` | ドキュメント作成 |

### プロジェクト分析型

| エージェント | 目的 |
|-------------|------|
| `codebase` | コードベース調査 |
| `dependency` | 依存関係分析 |
| `impact` | 影響範囲特定 |

### エージェント使用例

```bash
# Issue背景調査
/agent research issue=123

# コードベース調査
/agent codebase query="認証フローの実装箇所"

# コードレビュー
/agent reviewer files="src/auth/*.ts"

# 影響範囲分析
/agent impact target="src/utils/format.ts"
```

詳細は `dotclaude/agents/README.md` を参照。

## 重要な制約

### 1. 計画外変更の禁止

`/wf5-implement`はPlanに記載されたステップのみを実装します。
Plan外の変更が必要な場合は、まずPlanを更新してください。

### 2. 1実行 = 1ステップ

`/wf5-implement`は1回の実行で1ステップのみを実装します。
これにより作業の進捗が明確になります。

### 3. 原本の保持

Kickoff更新時は履歴を`05_REVISIONS.md`に記録します。

### 4. 依存関係の明示

2回目以降のワークフローでは依存関係を明確に記載してください。

## テンプレート

ドキュメントテンプレートは`dotclaude/templates/`ディレクトリにあります。
プロジェクトに合わせてカスタマイズしてください。

### テンプレート設計思想

テンプレートは「AIと人間の思考を揃えるためのインターフェース」として設計されています。

| 原則 | 説明 |
|-----|------|
| **空でも必要項目の枠を作る** | 漏れを可視化し、抜け漏れを防止 |
| **AIが一人で決めてはいけない箇所を明示** | Open Questionsセクションに人間の判断が必要な項目を列挙 |
| **レビュー箇所を固定** | 構造を統一し、チェックポイントを明確化 |

### テンプレート構成

| ファイル | 役割 | 主要セクション |
|---------|------|--------------|
| `00_KICKOFF.md` | 目標と成功基準の定義 | Goal, Success Criteria, Dependencies（構造化）, Open Questions |
| `01_SPEC.md` | 変更仕様 | Scope（In/Out）, Users/Use-cases, Requirements（FR/NFR分離）, Acceptance Criteria（Given/When/Then） |
| `02_PLAN.md` | 実装計画 | Overview, Steps（シンプルな構造）, Risks, Rollback |
| `03_REVIEW.md` | レビュー記録 | Review Result（Status）, Findings, Required Changes, Nice-to-have |
| `04_IMPLEMENT_LOG.md` | 実装ログ | 日付ベースのログ形式（Step, Summary, Files, Test Result） |
| `05_REVISIONS.md` | 変更履歴 | リビジョン番号ベース（Reason, Changed Sections） |

## トラブルシューティング

### state.jsonが壊れた場合

```bash
# examples/state.jsonを参考に手動で修正
# または初期化
echo '{"active_work": null, "works": {}}' > .wf/state.json
```

### ブランチが見つからない場合

```bash
# リモートから最新を取得
git fetch --all --prune
# 再度復元
/wf0-restore
```

### worktreeが残っている場合

```bash
# worktree一覧を確認
git worktree list
# 削除
git worktree remove .worktrees/feat-123-slug
```

## ライセンス

MIT
