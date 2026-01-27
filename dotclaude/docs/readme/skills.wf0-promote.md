# /wf0-promote

ローカルワークフローをGitHub IssueまたはJiraチケットに昇格するコマンド。

## 概要

- ローカルで作成したワークフローを外部システム（GitHub/Jira）にリンク
- Kickoffドキュメントの内容を基にIssue/チケットを作成
- state.jsonを更新して新しいソース情報を記録
- 昇格履歴（promoted_from, promoted_at）を保持

## 使用方法

```
/wf0-promote github [work-id]    # GitHub Issueに昇格
/wf0-promote jira [work-id]      # Jiraチケットに昇格
```

## 引数

| 引数 | 説明 |
|------|------|
| `github` | GitHub Issueを作成 |
| `jira` | Jiraチケットを作成 |
| `work-id` | 対象のwork-id（省略時は active work） |

## 前提条件

### GitHub

- `gh` CLIがインストール・認証済み

### Jira

- jira-cli がインストール済み、または
- `.wf/config.json` でJira設定が構成済み

## 処理フロー

1. 現在のワークがlocal sourceであることを確認
2. 00_KICKOFF.md からGoal/Success Criteriaを抽出
3. GitHub Issue / Jiraチケットを作成
4. state.json のsource情報を更新
5. 00_KICKOFF.md のヘッダーを更新
6. （任意）work-idをIssue番号を含む形式に変更

## 出力例

```
Workflow promoted successfully

Work ID: FEAT-123-add-feature
Promoted to: GitHub Issue #123
URL: https://github.com/owner/repo/issues/123

The local workflow is now linked to the external issue.
All future updates will reference this issue.
```

## 注意事項

- `source.type: "local"` のワークフローのみ対象
- Kickoffの内容はすべて保持
- 昇格履歴はstate.jsonに記録
- 後から `/wf0-promote` で別のシステムに再昇格することはできない
