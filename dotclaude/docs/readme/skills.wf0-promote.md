# /wf0-promote

ローカルワークフローをGitHub IssueまたはJiraチケットに昇格するコマンド。

## 使用方法

```
/wf0-promote github [work-id]
/wf0-promote jira [work-id]
```

## 処理

1. ワーク検証（source.type が "local" であること）
2. Kickoffから情報抽出（タイトル、Goal、成功条件）
3. 外部Issue作成（GitHub: gh cli / Jira: jira-cli or 手動）
4. state.json更新（source変更、昇格履歴記録）
5. 01_KICKOFF.mdのIssue参照を更新
6. オプション: Work-IDをIssue番号付きに変更
7. コミット

## 注意事項

- `source.type: "local"` のワークのみ対象
- 昇格履歴は `promoted_from`, `promoted_at` で記録
- GitHubラベルはwork typeから自動割当（FEAT→enhancement等）
