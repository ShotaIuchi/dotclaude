# /wf1-kickoff

ワークスペースとKickoffドキュメントを作成するコマンド。

## 使用方法

```
/wf1-kickoff github=<number> [--no-branch]
/wf1-kickoff jira=<jira-id> [title="title"] [--no-branch]
/wf1-kickoff local=<id> title="title" [type=<TYPE>] [--no-branch]
/wf1-kickoff [update | revise "<instruction>" | chat]
```

## 引数

### ソース（排他、新規ワークスペース用）

- `github`: GitHub Issue番号
- `jira`: Jira チケットID（例: `ABC-123`）
- `local`: ローカルID（任意の文字列）
- `title`: タイトル（jira/localでは必須）
- `type`: FEAT/FIX/REFACTOR/CHORE/RFC（localのみ、デフォルト: FEAT）
- `--no-branch`: ブランチ作成をスキップし、現在のブランチを作業ブランチとして使用

### サブコマンド（既存ワークスペース用）

- `update`: 対話を通じてKickoffを更新
- `revise "<instruction>"`: 指示に基づいて自動修正
- `chat`: ブレインストーミング対話モード

## 処理フロー

### フェーズ1: ワークスペースセットアップ

1. 前提条件チェック（jq必須、github時はgh必須）
2. work-id生成（ソース種別に応じたフォーマット）
3. ベースブランチ選択・確認
4. 作業ブランチ作成 — **main/masterでの作業は厳禁、ABORT対象**（`--no-branch`指定時はブランチ作成をスキップし現在のブランチを使用。ただしmain/masterの場合はABORT）
5. `.wf/`ディレクトリ初期化
6. ブランチ情報の早期記録（Phase 3を待たずstate.jsonに即時書込）
7. `docs/wf/<work-id>/`作成

### フェーズ2: Kickoff作成

8. ソース情報取得
9. localの場合: Plan Modeで要件探索
10. ブレストダイアログ（Goal、成功条件、制約等）
11. `01_KICKOFF.md`作成（テンプレート使用）

### フェーズ3: 完了処理

12. state.json更新（current: wf1-kickoff, next: wf2-spec）
13. コミット
14. 完了メッセージ（次ステップ: `/wf2-spec`）

