# wf0-batch 修正計画

## 問題の根本原因

**tmux の起動コマンドが間違っている**

```bash
# 現在（間違い）- 単一引数として渡している
tmux new-session -d -s "$worker_session" \
    "$HOME/.claude/scripts/batch/batch-worker.sh $i"
```

tmux は単一引数を受け取ると `sh -c` 経由で実行するが、引用符で囲んだパスだけでは正しく実行されず、シェルプロンプトが開くだけになる。

## 修正内容

### 修正箇所: `commands/wf0-batch.md`

3箇所の tmux 起動コマンドを修正:

| 行番号 | 対象 |
|--------|------|
| 196-197 | scheduler daemon 起動 |
| 218-219 | worker 起動（start） |
| 556-557 | worker 起動（resume） |

### 修正方法

**引数を分割して渡す**（tmux が直接実行する）:

```bash
# 修正後
tmux new-session -d -s "$scheduler_session" \
    "$HOME/.claude/scripts/batch/batch-daemon.sh"

tmux new-session -d -s "$worker_session" \
    "$HOME/.claude/scripts/batch/batch-worker.sh" "$i"
```

引数が複数の場合、tmux はシェルを介さず直接コマンドを実行する。

## 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| `dotclaude/commands/wf0-batch.md` | tmux 起動コマンド 3箇所を修正 |

## 検証方法

1. `/wf0-batch stop` で既存セッションを停止
2. `/wf0-batch start --parallel 1` で起動
3. `tmux attach -t wf-batch-worker-1` でワーカーの状態を確認
   - シェルプロンプトではなく、batch-worker.sh の出力が表示されるはず
4. schedule.json の `execution.sessions` で work が割り当てられているか確認
