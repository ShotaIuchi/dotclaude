# 共通コンテキスト

すべてのサブエージェントが共有する基本コンテキスト。

## WF運用システム概要

このシステムは AI（Claude Code）と人間が同じ状態・同じ成果物を見て作業するためのワークフロー管理システムです。

### 基本原則

1. **状態の共有**: AI と人間が同じ作業状態を把握
2. **成果物の一元管理**: ドキュメントとコードを紐付けて管理
3. **作業の再現性**: 別PCや別セッションでも作業を継続可能
4. **Plan外変更の防止**: 計画された作業のみを実装

## ファイル構成

### 設定ファイル

```
.wf/
├── config.json      # 共有設定（コミット対象）
├── state.json       # 共有状態（コミット対象）
└── local.json       # ローカル設定（gitignore）
```

### ドキュメント

```
docs/wf/<work-id>/
├── 00_KICKOFF.md        # 目標・成功条件定義
├── 01_SPEC.md           # 変更仕様
├── 02_PLAN.md           # 実装計画
├── 03_REVIEW.md         # レビュー記録
├── 04_IMPLEMENT_LOG.md  # 実装ログ
└── 05_REVISIONS.md      # 変更履歴
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

### 読み取り方法

```bash
# アクティブな作業 ID を取得
work_id=$(jq -r '.active_work // empty' .wf/state.json)

# 作業の詳細を取得
jq ".works[\"$work_id\"]" .wf/state.json

# ドキュメントパス
docs_dir="docs/wf/$work_id"
```

## Issue 情報の取得

```bash
# work-id から Issue 番号を抽出
issue_number=$(echo "$work_id" | sed 's/^[^-]*-\([0-9]*\)-.*/\1/')

# GitHub CLI で Issue 情報を取得
gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone
```

## ワークフロー順序

```
wf0-workspace → wf1-kickoff → wf2-spec → wf3-plan → wf4-review → wf5-implement → wf6-verify
```

各フェーズで生成されるドキュメント:

| フェーズ | ドキュメント |
|---------|-------------|
| wf1-kickoff | 00_KICKOFF.md |
| wf2-spec | 01_SPEC.md |
| wf3-plan | 02_PLAN.md |
| wf4-review | 03_REVIEW.md |
| wf5-implement | 04_IMPLEMENT_LOG.md |
| wf1-kickoff (update) | 05_REVISIONS.md |
