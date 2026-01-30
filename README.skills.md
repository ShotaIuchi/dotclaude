# skills/

スキル定義ディレクトリ。

## 概要

Claude Codeのスラッシュコマンドとして実行可能なスキルを定義。
ワークフローコマンド、ユーティリティコマンドを含む。

## ワークフロー全体像

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ワークフロー進行図                            │
└─────────────────────────────────────────────────────────────────────┘

[GitHub Issue / Jira / Local]
        │
        ▼
┌───────────────┐     ┌───────────────┐
│  wf1-kickoff  │────▶│   wf2-spec    │
│  ワークスペース │     │   仕様書作成   │
│  作成・調査    │     │               │
│               │     │  02_SPEC.md   │
│ 01_KICKOFF.md │     └───────┬───────┘
└───────────────┘             │
                              ▼
                      ┌───────────────┐
                      │   wf3-plan    │
                      │  実装計画作成  │
                      │               │
                      │  03_PLAN.md   │
                      └───────┬───────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     │
┌───────────────┐     ┌───────────────┐            │
│  wf4-review   │◀───▶│ wf5-implement │────────────┘
│  レビュー記録  │     │  ステップ実装  │   (繰り返し)
│               │     │               │
│ 04_REVIEW.md  │     │05_IMPLEMENT   │
└───────────────┘     │    _LOG.md    │
                      └───────┬───────┘
                              │ (全ステップ完了)
                              ▼
                      ┌───────────────┐
                      │  wf6-verify   │
                      │  検証・PR作成  │
                      │               │
                      │ 06_REVISIONS  │
                      │    .md        │
                      └───────┬───────┘
                              │
                              ▼
                        [Pull Request]
```

## スキル一覧

### 環境系 (wf0-*)

| スキル | 目的 |
|--------|------|
| `wf0-status` | 現在のワークフロー状態を表示 |
| `wf0-nextstep` | 次のステップを実行 |
| `wf0-restore` | 既存ワークスペースを復元 |
| `wf0-remote` | GitHub Issue経由のリモート操作 |
| `wf0-config` | config.jsonの対話式設定 |
| `wf0-promote` | ローカルworkをGitHub/Jiraに昇格 |

### スケジュール系 (sh*)

| スキル | 目的 |
|--------|------|
| `sh1-create` | バッチワークフローのスケジュール管理 |
| `sh2-run` | スケジュールから次のタスクを実行 |

### ドキュメント系 (wf1-4)

| スキル | 目的 | 成果物 |
|--------|------|--------|
| `wf1-kickoff` | ワークスペース作成・調査 | `01_KICKOFF.md` |
| `wf2-spec` | 仕様書作成 | `02_SPEC.md` |
| `wf3-plan` | 実装計画作成 | `03_PLAN.md` |
| `wf4-review` | レビュー記録作成 | `04_REVIEW.md` |

### 実装系 (wf5-6)

| スキル | 目的 | 成果物 |
|--------|------|--------|
| `wf5-implement` | 計画の1ステップを実装 | `05_IMPLEMENT_LOG.md` |
| `wf6-verify` | 実装検証・PR作成 | `06_REVISIONS.md` |

### ユーティリティ

| スキル | 目的 |
|--------|------|
| `commit` | コミット作成 |
| `subask` | サブエージェントへの質問 |
| `doc-review` | ドキュメントレビュー |
| `doc-fix` | レビュー指摘事項を修正 |

## 構造

```
skills/
├── README.md
├── wf0-config/SKILL.md
├── wf0-nextstep/SKILL.md
├── wf0-promote/SKILL.md
├── wf0-remote/SKILL.md
├── wf0-restore/SKILL.md
├── wf0-status/SKILL.md
├── sh1-create/SKILL.md
├── sh2-run/SKILL.md
├── wf1-kickoff/SKILL.md
├── wf2-spec/SKILL.md
├── wf3-plan/SKILL.md
├── wf4-review/SKILL.md
├── wf5-implement/SKILL.md
├── wf6-verify/SKILL.md
├── commit/SKILL.md
├── subask/SKILL.md
├── doc-review/SKILL.md
└── doc-fix/SKILL.md
```

## 使用方法

```bash
# ワークフロー開始
/wf1-kickoff github=123

# 状態確認
/wf0-status

# 次のステップを自動実行
/wf0-nextstep

# ユーティリティ
/commit
/subask "認証フローの実装箇所は？"
```

## 関連

- テンプレート: [`templates/`](dotclaude/templates/)
- 状態管理: `.wf/state.json`
