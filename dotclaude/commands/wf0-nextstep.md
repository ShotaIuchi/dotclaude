# /wf0-nextstep

次のワークフローコマンドを確認なしで即座に実行するコマンド。

## 使用方法

```
/wf0-nextstep [work-id]
```

## 引数

- `work-id`: 対象の作業ID（オプション）
  - 省略時: `state.json` の `active_work` を使用

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. state.json の読み込み

```bash
if [ ! -f .wf/state.json ]; then
  echo "WF システムが初期化されていません"
  echo "/wf0-workspace でワークスペースを作成してください"
  exit 1
fi
```

### 2. work-id の解決

```bash
work_id="$ARGUMENTS"

if [ -z "$work_id" ]; then
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi

if [ -z "$work_id" ]; then
  echo "ERROR: work-id を指定するか /wf0-workspace を実行してください"
  exit 1
fi
```

### 3. 作業情報の取得

```bash
# works に該当 work-id が存在するか確認
work=$(jq -r ".works[\"$work_id\"] // empty" .wf/state.json)
if [ -z "$work" ]; then
  echo "ERROR: work-id '$work_id' が見つかりません"
  exit 1
fi

# next フィールドを取得
next_phase=$(jq -r ".works[\"$work_id\"].next // empty" .wf/state.json)
current_phase=$(jq -r ".works[\"$work_id\"].current // empty" .wf/state.json)
```

### 4. next の判定と実行

#### 4.1 next が null または空の場合（完了済み）

```bash
if [ -z "$next_phase" ] || [ "$next_phase" = "null" ]; then
  # PR 作成済みか確認
  pr_url=$(jq -r ".works[\"$work_id\"].pr_url // empty" .wf/state.json)

  if [ -z "$pr_url" ]; then
    echo "このワークは実装が完了しています"
    echo "/wf6-verify で PR を作成してください"
  else
    echo "✅ このワークは完了しています"
    echo ""
    echo "PR: $pr_url"
  fi
  exit 0
fi
```

#### 4.2 next が wf5-implement の場合

wf5-implement の場合、未完了ステップがあれば step 引数付きで実行：

```bash
if [ "$next_phase" = "wf5-implement" ]; then
  current_step=$(jq -r ".works[\"$work_id\"].plan.current_step // 0" .wf/state.json)
  total_steps=$(jq -r ".works[\"$work_id\"].plan.total_steps // 0" .wf/state.json)

  if [ "$current_step" -lt "$total_steps" ]; then
    next_step=$((current_step + 1))
    echo "🚀 /wf5-implement $next_step を実行します..."
    echo ""
    # /wf5-implement $next_step を実行
  fi
fi
```

#### 4.3 通常の場合

```bash
echo "🚀 /$next_phase を実行します..."
echo ""
# /$next_phase を実行
```

### 5. 次のコマンドの実行

**重要:** 上記の判定結果に基づいて、該当するコマンドを **確認なしで即座に実行** してください。

実行すべきコマンド:
- 通常: `/$next_phase`
- wf5-implement + 未完了ステップあり: `/wf5-implement <next_step>`

## 出力形式

### 実行開始時

```
🚀 /<command> を実行します...

```

その後、該当コマンドの出力がそのまま表示されます。

### エラー時

```
ERROR: <エラーメッセージ>
```

## 注意事項

- **確認なしで即座に実行**: このコマンドはユーザー確認を求めずに次のコマンドを実行します
- state.json が存在しない場合は `/wf0-workspace` を促す
- work-id が解決できない場合は明確なエラーを表示
- 完了済みワークの場合は状態を表示して終了
