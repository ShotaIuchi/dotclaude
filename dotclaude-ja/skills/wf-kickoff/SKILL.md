---
name: wf-kickoff
description: >
  キックオフドキュメントを作成してワークフローを開始する。作業ディレクトリの作成、
  state.jsonの初期化、テンプレートからのキックオフドキュメント生成を行う。
  ユーザーが新しいタスクを始めたい、ワークフローを開始したい、作業に着手したい場合や、
  「新しいタスク」「始めよう」「キックオフ」「Xの作業開始」などと言った場合に使用する。
  wf-*ワークフローシリーズの最初のステップ。
argument-hint: "<work-id> [goal]"
---

# /wf-kickoff

新しいワークフローのワークスペースを初期化する。全wf-*ワークフローのエントリーポイント。

## このスキルの動作

1. `docs/wf/<work-id>/` に作業ディレクトリを作成
2. ワークフローの進捗を追跡する `state.json` を初期化
3. テンプレートから `01_KICKOFF.md` を生成
4. ユーザーにインタビューしてキックオフドキュメントを記入

## ワークフロー

### ステップ 1: Work IDの決定

ユーザーが引数としてwork-idを指定した場合はそれを使用する。指定がない場合は、
短く説明的な識別子を尋ねる（例: `add-csv-export`, `fix-login-bug`）。
work-idはkebab-caseとする。

### ステップ 2: 既存の作業を確認

`docs/wf/<work-id>/` が既に存在するか確認する。存在する場合は、ユーザーに警告し、
再開するか新しいwork-idを作成するか尋ねる。

### ステップ 3: ディレクトリとファイルの作成

1. `docs/wf/<work-id>/` を作成
2. このスキルに同梱されている `templates/01_KICKOFF.md` を `docs/wf/<work-id>/01_KICKOFF.md` にコピー
3. 初期状態で `state.json` を作成:

全タイムスタンプはUTCで `YYYY-MM-DDTHH:MM:SSZ` 形式を使用する（例: `2026-03-01T12:00:00Z`）。

```json
{
  "work_id": "<work-id>",
  "phase": "kickoff",
  "created_at": "YYYY-MM-DDTHH:MM:SSZ",
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ",
  "phases": {
    "kickoff": { "status": "in_progress", "completed_at": null },
    "spec": { "status": "pending", "completed_at": null },
    "plan": { "status": "pending", "completed_at": null },
    "impl": { "status": "pending", "completed_at": null, "current_step": null, "total_steps": null },
    "review": { "status": "pending", "completed_at": null, "target": null, "verdict": null }
  }
}
```

### ステップ 4: キックオフドキュメントの記入

ユーザーにインタビューして以下の項目を記入する:
- **ゴール**: 何を達成したいか？（1-2文）
- **完了基準**: どうなったら完了か？
- **制約**: 制限事項や要件はあるか？
- **スコープ外**: やらないことは何か？
- **依存関係**: この作業が依存するものはあるか？
- **未解決の質問**: 人間の判断が必要な項目

テンプレートのプレースホルダーをユーザーの回答で置き換える。
使用しないプレースホルダーセクションは空のまま残さず削除する。

### ステップ 5: 完了処理

1. `state.json` を更新: `phases.kickoff.status` を `"completed"` に、
   `phases.kickoff.completed_at` を現在のタイムスタンプに設定
2. `phase` を `"spec"`（次のフェーズ）に更新
3. ユーザーに通知: キックオフ完了、`/wf-spec <work-id>` で次に進めることを伝える

## 重要な注意事項

- テンプレートはこのスキルの `skills/wf-kickoff/templates/01_KICKOFF.md` に同梱されている。
- 作業ディレクトリの構造: `docs/wf/<work-id>/`（プロジェクトルートからの相対パス）
- 完了前に必ずユーザーに完成したキックオフドキュメントを確認してもらうこと
- キックオフドキュメントは日本語で作成する（テンプレートの言語に従う）
