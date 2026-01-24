# /subcommit

メインセッションをブロックせずに、サブエージェントを通じて非同期でコミットを実行するコマンド。

## 目的

- コミット処理中も作業を継続可能
- コミットメッセージの自動生成
- commit.schema.mdに従ったコミット作成

## 使用方法

```
/subcommit [message]
```

## 使用例

```bash
# コミットメッセージを自動生成
/subcommit

# メッセージを指定
/subcommit feat: Add user authentication

# クオート付きメッセージ
/subcommit "Add login feature"
```

## 処理内容

1. **事前チェック**
   - ステージ済みまたは未ステージの変更があるか確認
   - 変更がない場合は "Nothing to commit" で終了

2. **プロンプト構築**
   - コミットスキーマの場所を確認（project → global）

3. **サブエージェント起動（バックグラウンド）**
   - `run_in_background: true`で非同期実行
   - 変更内容からコミットメッセージを生成（または指定メッセージを使用）

4. **ユーザー通知**
   - "Committing in background..."
   - "Use /tasks to check status"

## オプション

| オプション | 説明 | デフォルト |
|-----------|------|----------|
| `--dry-run` | 実際にコミットせず、コミット内容を表示 | off |
| `--amend` | 前回のコミットを修正 | off |

### オプション処理

- `--dry-run`: コミットせず、`git diff --cached`と`git status`の結果を報告
- `--amend`: 前回のコミットを表示し確認後に`git commit --amend`を使用
  - **警告**: 既にプッシュ済みのコミットには使用しない

## 結果確認

バックグラウンドタスクの結果を確認:

```bash
# タスクリストを確認
/tasks

# 結果を確認（Readツールでoutput_fileを読む）
```

## 注意事項

- バックグラウンド実行のため、結果は後で確認が必要
- pre-commitフックが存在する場合は実行される
- コンフリクトがある場合はエラーで終了
- `--amend`は前回のコミットが自分のものであることを確認してから使用
