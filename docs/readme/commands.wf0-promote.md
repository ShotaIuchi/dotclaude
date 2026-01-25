# wf0-promote - ローカルワークフローの昇格

ローカルで作成したワークフローをGitHub IssueやJiraチケットに昇格するコマンド。

## 構文

```
/wf0-promote <target> [work-id]
```

## 引数

| 引数 | 説明 |
|------|------|
| `github` | GitHub Issueを作成してリンク |
| `jira` | Jiraチケットを作成してリンク |
| `work-id` | (省略可) 対象work-id。省略時はactive_workを使用 |

## 使用例

```bash
# アクティブなワークフローをGitHub Issueに昇格
/wf0-promote github

# 特定のワークフローをJiraに昇格
/wf0-promote jira FEAT-myid-add-feature
```

## 処理の流れ

1. **検証**: source.typeが`local`であることを確認
2. **Kickoff読込**: `00_KICKOFF.md`からGoal、Success Criteriaを取得
3. **Issue/チケット作成**: 外部システムにIssue/チケットを作成
4. **state.json更新**: source情報を更新（昇格履歴を記録）
5. **Kickoff更新**: Issue参照を更新
6. **コミット**: 変更をコミット

## state.json更新例

```json
{
  "source": {
    "type": "github",
    "id": "123",
    "title": "機能追加",
    "url": "https://github.com/owner/repo/issues/123",
    "promoted_from": "local",
    "promoted_at": "2026-01-25T10:00:00Z"
  }
}
```

## GitHub Issue作成

- タイトル: state.jsonのsource.titleから取得
- 本文: 00_KICKOFF.mdのGoal + Success Criteriaを含む
- ラベル: work typeから自動判定（FEAT→enhancement, FIX→bug）

## Jiraチケット作成

- プロジェクトキー: `.wf/config.json`の`jira.project`または対話で入力
- Jira CLIまたは手動作成をサポート

## オプション: work-id更新

昇格後、Issue番号を含むwork-idへの更新を提案:

```
Work-ID を更新しますか？

現在: FEAT-myid-add-feature
提案: FEAT-123-add-feature (GitHub Issue #123)

1. はい、更新する
2. いいえ、現在のままにする
```

## 前提条件

- `source.type: "local"`のワークフローのみ対象
- GitHub: `gh` CLIの認証が必要
- Jira: Jira CLIまたはAPIトークンの設定（任意）

## 関連コマンド

- `/wf1-kickoff local=<id>` - ローカルワークフロー作成（作成時にも昇格オプションあり）
- `/wf0-status` - ワークフロー状態確認
