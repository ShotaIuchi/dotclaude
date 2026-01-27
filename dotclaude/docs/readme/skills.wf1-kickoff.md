# /wf1-kickoff

ワークスペースとKickoffドキュメントを一度に作成するコマンド。

## 使用方法

```
/wf1-kickoff github=<number>
/wf1-kickoff jira=<jira-id> [title="title"]
/wf1-kickoff local=<id> title="title" [type=<TYPE>]
/wf1-kickoff [update | revise "<instruction>" | chat]
```

## 引数

### ソース引数（新規ワークスペース用）

以下のいずれかを指定（排他）：

- `github`: GitHub Issue番号
- `jira`: Jira チケットID（例: `ABC-123`）
- `local`: ローカルID（任意の文字列）

オプション引数：

- `title`: タイトル（jira/localでは必須、githubでは無視）
- `type`: 作業タイプ（localのみ。FEAT/FIX/REFACTOR/CHORE/RFC。デフォルト: FEAT）

### サブコマンド（既存ワークスペース用）

- `(なし)`: 新規ワークスペースとKickoffを作成
- `update`: 既存Kickoffを更新
- `revise "<instruction>"`: 指示に基づいて修正
- `chat`: ブレインストーミング対話モード

## 処理フロー

### フェーズ1: ワークスペースセットアップ

1. 前提条件チェック（jq, gh）
2. ID情報取得とwork-id生成
3. ベースブランチ選択・確認（デフォルト: カレントブランチ）
4. 作業ブランチ作成 — **CRITICAL: スキップ厳禁**。作成後にmain/masterでないことを検証。失敗時はABORT
5. `.wf/`ディレクトリ初期化
5a. ブランチ情報の早期記録 — Step 10を待たず`state.json`に`git.branch`を即時書き込み
6. `docs/wf/<work-id>/`作成

### フェーズ2: Kickoff作成

7. ソース情報取得（GitHub/Jira/local）
8. ブレストダイアログ
9. `00_KICKOFF.md`作成

### フェーズ3: 完了処理

10. `state.json`更新（current: wf1-kickoff, next: wf2-spec）— 書き込み前に`git.branch`がnull/main/masterでないことを検証
11. コミット

## 完了メッセージ

```
✅ Workspace and Kickoff created

Work ID: <work-id>
Branch: <branch_name>
Base: <base_branch>
Docs: docs/wf/<work-id>/

File: docs/wf/<work-id>/00_KICKOFF.md
Revision: 1

Next step: Run /wf2-spec to create the specification
```

## 注意事項

- 既存作業がある場合は警告を表示
- ブランチ名が既に存在する場合はエラー
- github/jira/localは排他（複数指定でエラー）
- Step 5以降でmain/masterブランチにいる場合は即座にABORT

---

## エージェント参照

このスキルは [research エージェント](../../agents/workflow/research.md) に委譲する。
詳細な機能と制約はそのファイルを参照。
