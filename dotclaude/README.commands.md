# commands/

ワークフローコマンド定義ディレクトリ。

## 概要

Claude Codeのスラッシュコマンドとして実行可能なワークフローコマンドを定義。
GitHub Issue → 仕様 → 計画 → 実装 → PR作成 までを構造化されたドキュメントと共に進行する。

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
│ 04_REVIEW.md  │     │04_IMPLEMENT   │
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

## コマンド一覧

### 環境系 (wf0-*)

| コマンド | 目的 | 詳細 |
|----------|------|------|
| `wf0-status` | 現在のワークフロー状態を表示 | 進捗、現在フェーズ、次のアクションを表示 |
| `wf0-nextstep` | 次のステップを実行 | 確認なしで即座に次のワークフローコマンドを実行 |
| `wf0-restore` | 既存ワークスペースを復元 | 別セッションで中断した作業を再開 |
| `wf0-remote` | リモートワークフロー操作 | GitHub Issueコメント経由での承認・実行 |

### ドキュメント系 (wf1-4)

| コマンド | 目的 | 成果物 | 主な内容 |
|----------|------|--------|---------|
| `wf1-kickoff` | ワークスペース作成・調査 | `01_KICKOFF.md` | Goal、Success Criteria、Constraints、Dependencies |
| `wf2-spec` | 仕様書作成 | `02_SPEC.md` | 影響コンポーネント、詳細変更内容、テスト戦略 |
| `wf3-plan` | 実装計画作成 | `03_PLAN.md` | ステップ分割（5-10個）、依存関係、リスク評価 |
| `wf4-review` | レビュー記録作成 | `04_REVIEW.md` | Plan/コードレビュー、チェックリスト、指摘事項 |

### 実装系 (wf5-6)

| コマンド | 目的 | 成果物 | 制約 |
|----------|------|--------|------|
| `wf5-implement` | 計画の1ステップを実装 | `05_IMPLEMENT_LOG.md` | **1回=1ステップ**、計画外変更禁止 |
| `wf6-verify` | 実装検証・PR作成 | `06_REVISIONS.md` | テスト・ビルド・Lint確認後にPR作成 |

### ユーティリティ

| コマンド | 目的 | 使用例 |
|----------|------|--------|
| `agent` | サブエージェント直接呼び出し | `/agent reviewer files="src/*.ts"` |
| `subask` | サブエージェントへの質問 | `/subask "認証フローの実装箇所は？"` |
| `commit` | コミット作成 | `/commit` |
| `doc-review` | ドキュメントレビュー | `/doc-review docs/wf/FEAT-123/` |
| `doc-fix` | レビュー修正適用 | `/doc-fix` |

## ワークフローの使い方

### 基本的な流れ

```bash
# 1. GitHub Issueからワークスペース作成
/wf1-kickoff github=123

# 2. 仕様書作成
/wf2-spec

# 3. 実装計画作成
/wf3-plan

# 4. (オプション) Planレビュー
/wf4-review plan

# 5. 実装（ステップごとに繰り返し）
/wf5-implement      # Step 1
/wf5-implement      # Step 2
/wf5-implement      # Step 3
...

# 6. 検証・PR作成
/wf6-verify pr
```

### 自動進行

```bash
# 次のステップを自動判定して実行
/wf0-nextstep

# 現在の状態確認
/wf0-status
```

### ソース指定

```bash
# GitHub Issue
/wf1-kickoff github=123

# Jira チケット
/wf1-kickoff jira=ABC-123 title="ログイン機能追加"

# ローカル（Issue不要）
/wf1-kickoff local=my-feature title="新機能" type=FEAT
```

## リモートワークフロー操作 (wf0-remote)

外出先やモバイルからGitHub Issueコメント経由でワークフローを進行できる。

### 仕組み

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   携帯/PC   │────▶│GitHub Issue │────▶│  PCデーモン  │
│  コメント投稿 │     │  コメント    │     │   (tmux)    │
│  /approve   │     │             │     │ /wf0-nextstep│
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               ▼
                                        [次のステップ実行]
                                               │
                                               ▼
                                        [Issue に結果投稿]
```

### 使用方法

```bash
# 単一work監視開始
/wf0-remote start FEAT-123-auth

# 複数work指定（可変引数）
/wf0-remote start FEAT-123-auth FIX-456-login FEAT-789-export

# 全GitHub-sourceのwork一括監視
/wf0-remote start --all

# ワイルドカードパターンで監視
/wf0-remote start FEAT-*      # FEAT-で始まるwork
/wf0-remote start *-auth      # -authで終わるwork

# GitHub Issueにコメントで操作（携帯等から）
/approve    # 次のステップを実行
/next       # 同上
/pause      # 一時停止
/stop       # 完全停止

# 監視状態確認
/wf0-remote status

# 監視停止
/wf0-remote stop FEAT-123-auth  # 単一
/wf0-remote stop FEAT-123 FEAT-456  # 複数
/wf0-remote stop --all          # 全て
/wf0-remote stop FEAT-*         # パターン
```

### ターゲット指定

| 形式 | 説明 | 例 |
|------|------|-----|
| `work-id` | 単一のwork指定 | `FEAT-123-auth` |
| `work-id...` | 複数work指定（可変引数） | `FEAT-123 FIX-456 FEAT-789` |
| `--all` | 全GitHub-source work | start時: github sourceのみ対象<br>stop時: remote.enabled=trueのwork |
| `PATTERN` | ワイルドカード | `FEAT-*`, `*-auth`, `FIX-???-*` |

### セキュリティ

| ルール | 内容 |
|--------|------|
| 権限チェック | `admin`, `write`, `maintain`権限を持つコラボレーターのみ |
| 実行制限 | 最大10ステップ（無限ループ防止） |
| コマンド制限 | `/approve`, `/next`, `/pause`, `/stop`のみ |
| 実行内容 | `/wf0-nextstep`のみ（任意コマンド禁止） |

### Issueへの投稿例

```markdown
## 🤖 wf3-plan 完了

**ステータス**: 待機中（承認待ち）
**次のステップ**: wf4-review

### 成果物
- `docs/wf/FEAT-123/03_PLAN.md` 作成

---
💡 `/approve` で次のステップを実行
```

## 状態管理 (state.json)

ワークフローの状態は`.wf/state.json`で管理される。

```json
{
  "active_work": "FEAT-123-add-auth",
  "works": {
    "FEAT-123-add-auth": {
      "current": "wf5-implement",
      "next": "wf5-implement",
      "source": {
        "type": "github",
        "id": "123",
        "title": "認証機能追加",
        "url": "https://github.com/owner/repo/issues/123"
      },
      "git": {
        "base": "main",
        "branch": "feat/123-add-auth"
      },
      "plan": {
        "total_steps": 5,
        "current_step": 2,
        "steps": {
          "1": { "status": "completed", "completed_at": "..." },
          "2": { "status": "completed", "completed_at": "..." },
          "3": { "status": "pending" }
        }
      },
      "remote": {
        "enabled": true,
        "source_issue": 123,
        "status": "waiting_approval"
      }
    }
  }
}
```

## ドキュメント構造

各ワークに対して以下のドキュメントが生成される:

```
docs/wf/<work-id>/
├── 01_KICKOFF.md        # 背景・Goal・成功基準
├── 02_SPEC.md           # 詳細仕様・影響範囲
├── 03_PLAN.md           # 実装ステップ・依存関係
├── 04_REVIEW.md         # レビュー結果・指摘事項
├── 05_IMPLEMENT_LOG.md  # 実装ログ・各ステップ記録
└── 06_REVISIONS.md      # 修正履歴
```

## 重要な制約

### wf5-implement

- **1回の実行 = 1ステップのみ**
- **計画外の変更は禁止**（必要な場合は`/wf3-plan update`で計画を更新）
- 依存ステップが未完了の場合はエラー

### wf6-verify

- テスト失敗時はPR作成不可
- ビルド失敗時はPR作成不可
- Success Criteria未達成時は警告表示

## 関連

- 状態管理: `.wf/state.json`
- テンプレート: [`templates/`](templates/)
- リモートルール: [`rules/remote-operation.md`](rules/remote-operation.md)
- Claude Code 公式: https://docs.anthropic.com/en/docs/claude-code/skills
- プロジェクト規約: [`references/tools/claude-code/best-practices.md`](references/tools/claude-code/best-practices.md)
