# /wf0-workspace

ワークスペースを新規作成するコマンド。

## 使用方法

```
/wf0-workspace issue=<number>
```

## 引数

- `issue`: GitHub Issue 番号（必須）

## 処理内容

$ARGUMENTS を解析して issue 番号を取得し、以下の処理を実行してください。

### 1. 前提条件の確認

```bash
# jq, gh が利用可能か確認
command -v jq >/dev/null || echo "ERROR: jq が必要です"
command -v gh >/dev/null || echo "ERROR: gh が必要です"
gh auth status || echo "ERROR: gh auth login を実行してください"
```

### 2. GitHub Issue 情報の取得

```bash
gh issue view <issue_number> --json number,title,labels,body
```

取得した情報から以下を決定：
- **TYPE**: ラベルから判定（feature/enhancement→FEAT, bug→FIX, refactor→REFACTOR, chore→CHORE, rfc→RFC）
- **slug**: タイトルから生成（小文字、英数字とハイフンのみ、最大40文字）
- **work-id**: `<TYPE>-<issue>-<slug>` 形式

### 3. ベースブランチの選択

`.wf/config.json` の `default_base_branch` をデフォルトとして使用。
存在しない場合は `main` を使用。

ユーザーに確認：
> ベースブランチ: `<branch>` でよいですか？

### 4. 作業ブランチの作成

```bash
# ブランチ名: <prefix>/<issue>-<slug>
git checkout -b <branch_name> <base_branch>
```

### 5. WF ディレクトリの初期化

`.wf/` ディレクトリがなければ作成：

```bash
source scripts/wf-init.sh
wf_init_project
```

### 6. ドキュメントディレクトリの作成

```bash
mkdir -p docs/wf/<work-id>/
```

### 7. state.json の更新

```json
{
  "active_work": "<work-id>",
  "works": {
    "<work-id>": {
      "current": "wf0-workspace",
      "next": "wf1-kickoff",
      "git": {
        "base": "<base_branch>",
        "branch": "<feature_branch>"
      },
      "kickoff": {
        "revision": 0,
        "last_updated": null
      },
      "created_at": "<timestamp>"
    }
  }
}
```

### 8. worktree 作成（オプション）

`config.worktree.enabled` が `true` の場合：

```bash
git worktree add .worktrees/<branch-name> <branch>
```

`local.json` に worktree パスを記録。

### 9. 完了メッセージ

```
✅ ワークスペースを作成しました

Work ID: <work-id>
Branch: <branch_name>
Base: <base_branch>
Docs: docs/wf/<work-id>/

次のステップ: /wf1-kickoff を実行して Kickoff ドキュメントを作成してください
```

## 注意事項

- 既存の作業がある場合は警告を表示
- ブランチ名が既に存在する場合はエラー
- Issue が見つからない場合はエラー
