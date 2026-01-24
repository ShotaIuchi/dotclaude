# /wf1-workspace

新規ワークスペースを作成するコマンド。

## 使用方法

```
/wf1-workspace github=<number>
/wf1-workspace jira=<jira-id> [title="title"]
/wf1-workspace local=<id> title="title" [type=<TYPE>]
```

## 引数

以下のいずれかを指定（相互排他）:

- `github`: GitHub Issue番号
- `jira`: JiraチケットID（例: `ABC-123`）
- `local`: ローカルID（任意の文字列）

オプション引数:

- `title`: タイトル（jira/localでは必須、githubでは無視）
- `type`: 作業タイプ（localのみ。FEAT/FIX/REFACTOR/CHORE/RFC。デフォルト: FEAT）

## 処理内容

1. **前提条件チェック**
   - `jq`、（githubモードでは）`gh`コマンドの確認

2. **ID情報の取得とwork-id生成**
   - github: Issueからラベルでタイプ判定、タイトルからslug生成
   - jira: JiraIDプレフィックスとタイトルから生成
   - local: 指定されたタイプとタイトルから生成

3. **ベースブランチの選択**
   - config.jsonのdefault_base_branchをデフォルトとして確認

4. **作業ブランチの作成**

5. **WFディレクトリの初期化**

6. **ドキュメントディレクトリの作成**

7. **state.jsonの更新**

8. **worktreeの作成**（オプション）

9. **コミット**

## 出力例

```
✅ Workspace created

Work ID: FEAT-123-export-csv
Branch: feat/123-export-csv
Base: develop
Docs: docs/wf/FEAT-123-export-csv/

Next step: Run /wf2-kickoff to create the Kickoff document
```

## 注意事項

- 既存の作業がある場合は警告を表示
- ブランチ名が既に存在する場合はエラー
- githubモード: Issueが見つからない場合はエラー
- jira/localモード: titleが指定されていない場合はエラー
- github/jira/localは相互排他（複数指定でエラー）
