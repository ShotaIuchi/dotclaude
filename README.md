# WF運用システム

AI（Claude Code）と人間が同じ状態・同じ成果物を見て作業するためのワークフロー管理システム。

## 概要

このシステムは以下の課題を解決します：

- **状態の共有**: AI と人間が同じ作業状態を把握
- **成果物の一元管理**: ドキュメントとコードを紐付けて管理
- **作業の再現性**: 別PCや別セッションでも作業を継続可能
- **Plan外変更の防止**: 計画された作業のみを実装

## セットアップ

### 前提条件

以下のツールが必要です：

- `bash` - シェルスクリプト実行
- `jq` - JSON 処理
- `gh` - GitHub CLI
- `git` - バージョン管理

### インストール

```bash
# 1. このリポジトリをクローン
git clone https://github.com/your-org/dotclaude.git

# 2. dotclaude を ~/.claude にシンボリックリンク（グローバル設定）
ln -s /path/to/dotclaude/dotclaude ~/.claude

# または、プロジェクト単位で利用する場合
cd your-project
ln -s /path/to/dotclaude/dotclaude .claude
```

### 初期化

```bash
# プロジェクトで WF システムを初期化
./path/to/dotclaude/scripts/wf-init.sh
```

これにより以下が作成されます：

- `.wf/config.json` - 共有設定
- `.wf/state.json` - 共有状態
- `docs/wf/` - ワークフロードキュメント
- `.gitignore` に `.wf/local.json` を追加

## コマンド一覧

### 環境系（wf0-*）

| コマンド | 説明 |
|---------|------|
| `/wf0-workspace issue=<n>` | 新規ワークスペース作成 |
| `/wf0-restore [work-id]` | 既存ワークスペース復元 |
| `/wf0-status [work-id\|all]` | 状態表示 |

### ドキュメント系（wf1-4）

| コマンド | 説明 |
|---------|------|
| `/wf1-kickoff` | Kickoff 作成（目標・成功条件定義） |
| `/wf1-kickoff update` | Kickoff 更新 |
| `/wf1-kickoff revise "<指示>"` | Kickoff 修正 |
| `/wf1-kickoff chat` | 壁打ち対話 |
| `/wf2-spec` | 仕様書作成 |
| `/wf3-plan` | 実装計画作成 |
| `/wf4-review` | レビュー記録 |

### 実装系（wf5-6）

| コマンド | 説明 |
|---------|------|
| `/wf5-implement [step]` | Plan の1ステップ実装 |
| `/wf6-verify` | テスト・ビルド検証 |
| `/wf6-verify pr` | 検証後にPR作成 |

## ワークフロー

### 基本フロー

```
/wf0-workspace issue=123
    ↓
/wf1-kickoff（目標・成功条件を定義）
    ↓
/wf2-spec（変更仕様を策定）
    ↓
/wf3-plan（実装ステップを計画）
    ↓
/wf4-review（任意：計画レビュー）
    ↓
/wf5-implement（1ステップずつ実装）
    ↓ ↑ 繰り返し
/wf6-verify pr（検証してPR作成）
```

### 作業の復元

```bash
# 別PCで作業を継続
/wf0-restore FEAT-123-export-csv
```

### Kickoff の修正

```bash
# 指示付きで修正
/wf1-kickoff revise "スコープを縮小して、CSV エクスポートのみに絞る"
```

## リポジトリ構成

```
dotclaude/                 # リポジトリルート
├── dotclaude/             # ~/.claude にリンクする対象
│   ├── commands/          # スラッシュコマンド定義
│   ├── guides/            # アーキテクチャガイド
│   ├── examples/          # 設定ファイル例
│   ├── scripts/           # シェルスクリプト
│   └── templates/         # ドキュメントテンプレート
├── .gitignore
└── README.md
```

## ディレクトリ構成

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
└── .claude/             # dotclaude からのシンボリックリンク
    └── commands/        # スラッシュコマンド
        ├── wf0-workspace.md
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
      "git": {
        "base": "develop",
        "branch": "feat/123-export-csv"
      }
    }
  }
}
```

## 重要な制約

### 1. PLAN外の変更禁止

`/wf5-implement` は Plan に記載されたステップのみを実装します。
Plan外の変更が必要な場合は、先に Plan を更新してください。

### 2. 1回 = 1ステップ

`/wf5-implement` は1回の実行で1ステップのみ実装します。
これにより、作業の進捗が明確になります。

### 3. 元内容を消さない

Kickoff の更新時は、`05_REVISIONS.md` に履歴を残します。

### 4. Dependencies 必須

2個目以降のワークフローは、依存関係を明記してください。

## テンプレート

`dotclaude/templates/` ディレクトリに各ドキュメントのテンプレートがあります。
プロジェクトに合わせてカスタマイズしてください。

### テンプレート設計思想

テンプレートは「AIと人間の思考を揃えるためのインターフェース」として設計されています。

| 原則 | 説明 |
|------|------|
| **必須項目は空でも枠を作る** | 抜けを可視化し、記入漏れを防止 |
| **AIが勝手に決めてはいけない所は明示** | Open Questions セクションで人間の判断が必要な項目を列挙 |
| **レビューで見る場所を固定** | 構造を統一し、確認箇所を明確化 |

### テンプレート構成

| ファイル | 役割 | 主要セクション |
|----------|------|---------------|
| `00_KICKOFF.md` | 目標・成功条件定義 | Goal, Success Criteria, Dependencies（構造化）, Open Questions |
| `01_SPEC.md` | 変更仕様 | Scope（In/Out）, Users/Use-cases, Requirements（FR/NFR分離）, Acceptance Criteria（Given/When/Then） |
| `02_PLAN.md` | 実装計画 | Overview, Steps（シンプル構造）, Risks, Rollback |
| `03_REVIEW.md` | レビュー記録 | Review Result（Status）, Findings, Required Changes, Nice-to-have |
| `04_IMPLEMENT_LOG.md` | 実装ログ | 日付ベースのログ形式（Step, Summary, Files, Test Result） |
| `05_REVISIONS.md` | 変更履歴 | Revision番号ベース（Reason, Changed Sections） |

## トラブルシューティング

### state.json が壊れた場合

```bash
# examples/state.json を参考に手動で修正
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

### worktree が残っている場合

```bash
# worktree を一覧表示
git worktree list
# 削除
git worktree remove .worktrees/feat-123-slug
```

## ライセンス

MIT
