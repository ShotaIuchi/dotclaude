# wf0-batch 自動進行機能の改善計画

## 問題

wf0-batchで実行した場合、各wfコマンド完了後にClaudeが「次のステップを実行しますか？」と確認を求めて停止する。

## 解決策

**1回のClaude呼び出しで全ワークフロー（wf1→wf6）を自動実行する方式**

プロンプトに明確な自動実行指示を含めることで、確認なしで全ステップを完了まで実行する。

## 修正対象ファイル

### 1. `dotclaude/scripts/batch/batch-worker.sh`

**変更箇所: 180-216行目**

現在の `claude --print` 方式から、1回のセッションで全ワークフローを実行する方式に変更。

```bash
# 変更前: 各フェーズを個別に実行
if [ "$current_phase" = "wf1-kickoff" ]; then
    claude --print "/wf1-kickoff github=#$source_id" > "$output_file" 2>&1
else
    claude --print "/wf0-nextstep $work_id" > "$output_file" 2>&1
fi

# 変更後: 1回の呼び出しで全ワークフローを自動実行
BATCH_PROMPT="以下のワークを確認なしで自動的にwf1-kickoff→wf6-verifyまで完了してください。
- ユーザー確認は一切不要です
- 各ステップ完了後、自動的に次のステップに進んでください
- エラーが発生した場合のみ停止してください
- /wf0-nextstep を使用して次のステップを実行してください

Work ID: $work_id
Source: $source_type #$source_id"

claude --dangerously-skip-permissions -p "$BATCH_PROMPT" > "$output_file" 2>&1
```

**変更箇所: 174-280行目（ループ構造の簡素化）**

1回の呼び出しで完了するため、フェーズループを削除し、完了待ちのみに変更。

### 2. `dotclaude/commands/wf0-batch.md`

**変更箇所: start サブコマンド（196-208行目）**

tmuxセッション起動時のコマンドを変更。

```bash
# 変更後
BATCH_PROMPT="Work $work_id のワークフローを確認なしで自動実行してください。
wf1-kickoff から wf6-verify まで、ユーザー確認なしで全ステップを完了してください。"

tmux new-session -d -s "$worker_session" -c "$PROJECT_ROOT" \
  "claude --dangerously-skip-permissions -p '$BATCH_PROMPT' 2>&1 | tee -a $PROJECT_ROOT/.wf/batch.log"
```

**変更箇所: resume サブコマンド（555-572行目）**

同様にプロンプトを改善。

```bash
RESUME_PROMPT="$work_id のワークフローを再開し、確認なしで自動的に完了まで実行してください。
/wf0-status で現在の状態を確認し、残りのステップを全て実行してください。
ユーザー確認は不要です。"
```

## 実装手順

1. **batch-worker.sh の修正**
   - プロンプト定義を追加
   - フェーズループを1回の呼び出しに変更
   - 完了検出ロジックを簡素化

2. **wf0-batch.md の修正**
   - start サブコマンドのtmuxコマンド変更
   - resume サブコマンドのtmuxコマンド変更
   - プロンプトテンプレートの追加

## 検証方法

```bash
# 1. 現在実行中のバッチを停止
/wf0-batch stop

# 2. 修正後、再開
/wf0-batch resume

# 3. ログ監視で自動進行を確認
tail -f ~/work/takusuru/takusuru/.wf/batch.log

# 4. 確認項目
# - 「次のステップを実行しますか？」で停止しないこと
# - wf1→wf2→wf3→wf5→wf6が自動的に進行すること
```

## 複数Workの連続実行

batch-worker.sh は外側のループで複数のworkを連続実行する:

```
Worker起動
  ↓
while true:
  ├─ daemon から work 割り当てを待機
  ├─ [E01] Claude CLI実行 → wf1→wf6完了
  ├─ 完了報告 → schedule.json更新
  ├─ daemon が依存関係を確認し E02 を割り当て
  ├─ [E02] Claude CLI実行 → wf1→wf6完了
  └─ ...繰り返し（全work完了まで）
```

**ポイント:**
- 1つのworkが完了すると、daemon が依存関係を確認
- 依存関係が満たされた次のwork を worker に割り当て
- schedule.json の `status: "completed"` になるまで継続

## 備考

- `--dangerously-skip-permissions` で権限確認をスキップ
- プロンプトに「確認なし」「自動実行」を明示することが重要
- ログは `.wf/batch.log` に tee で出力
- daemon (batch-daemon.sh) が work の割り当てと依存関係解決を担当
