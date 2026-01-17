# /wf5-implement

Plan の1ステップを実装するコマンド。

## 使用方法

```
/wf5-implement [step_number]
```

## 引数

- `step_number`: 実装するステップ番号（オプション）
  - 省略時: 次の未完了ステップを自動選択

## 重要な制約

⚠️ **PLAN外の変更禁止**: このコマンドは Plan に記載されたステップのみを実装します。
⚠️ **1回 = 1ステップ**: 1回の実行で1ステップのみ実装します。

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. 前提条件の確認

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
plan_path="$docs_dir/02_PLAN.md"
log_path="$docs_dir/04_IMPLEMENT_LOG.md"

# Plan が存在するか確認
if [ ! -f "$plan_path" ]; then
  echo "Plan ドキュメントがありません"
  echo "/wf3-plan を先に実行してください"
  exit 1
fi
```

### 2. 実装対象ステップの決定

```bash
step_number="$ARGUMENTS"

if [ -z "$step_number" ]; then
  # state.json から次のステップを取得
  current_step=$(jq -r ".works[\"$work_id\"].plan.current_step // 0" .wf/state.json)
  step_number=$((current_step + 1))
fi
```

### 3. Plan からステップ情報を抽出

Plan の該当ステップから以下を取得：
- **タイトル**
- **目的**
- **対象ファイル**
- **作業内容**
- **完了条件**
- **依存ステップ**

### 4. 依存ステップの確認

```bash
# 依存ステップが完了しているか確認
for dep in $dependencies; do
  dep_status=$(jq -r ".works[\"$work_id\"].plan.steps[\"$dep\"].status // \"pending\"" .wf/state.json)
  if [ "$dep_status" != "completed" ]; then
    echo "ERROR: 依存ステップ $dep が完了していません"
    exit 1
  fi
done
```

### 5. 実装の開始

```
📋 Step <n>: <title>
═══════════════════════════════════════

目的: <goal>

対象ファイル:
- <file1>
- <file2>

作業内容:
1. <task1>
2. <task2>

完了条件:
- [ ] <condition1>
- [ ] <condition2>

─────────────────────────────────────────
実装を開始します...
```

### 6. 実装作業

Plan に記載された作業内容に従って実装：

1. **対象ファイルの確認**
   - 既存ファイルを読み込み
   - 変更箇所を特定

2. **コード変更の実施**
   - Plan の作業内容に従う
   - **Plan外の変更は行わない**

3. **テストの実行**
   - 関連するテストを実行
   - テストが失敗した場合は修正

### 7. 実装ログの記録

`04_IMPLEMENT_LOG.md` に追記：

**テンプレート参照:** `~/.claude/templates/04_IMPLEMENT_LOG.md` を読み込んで使用してください。

テンプレートのステップセクション構造に従い、実装内容を記録します。

### 8. state.json の更新

```bash
timestamp=$(date +"%Y-%m-%dT%H:%M:%S%z")

# ステップ状態を更新
jq ".works[\"$work_id\"].plan.steps[\"$step_number\"] = {\"status\": \"completed\", \"completed_at\": \"$timestamp\"}" .wf/state.json > tmp && mv tmp .wf/state.json

# current_step を更新
jq ".works[\"$work_id\"].plan.current_step = $step_number" .wf/state.json > tmp && mv tmp .wf/state.json

# current/next を更新
jq ".works[\"$work_id\"].current = \"wf5-implement\"" .wf/state.json > tmp && mv tmp .wf/state.json

# 全ステップ完了したか確認
total_steps=$(jq -r ".works[\"$work_id\"].plan.total_steps" .wf/state.json)
if [ "$step_number" -eq "$total_steps" ]; then
  jq ".works[\"$work_id\"].next = \"wf6-verify\"" .wf/state.json > tmp && mv tmp .wf/state.json
fi
```

### 9. 完了条件の確認

各完了条件を確認し、すべて満たされていることを確認：

```
完了条件の確認:
- [✓] <condition1>
- [✓] <condition2>
```

### 10. コミット

```bash
git add <changed_files>
git commit -m "feat(<scope>): <description>

Step <n>/<total>: <step_title>
Work: <work_id>
"
```

### 11. 完了メッセージ

```
✅ Step <n> が完了しました

変更ファイル:
- <file1> (+10, -5)
- <file2> (+3, -0)

完了条件:
- [✓] <condition1>
- [✓] <condition2>

Progress: <n>/<total> steps completed

次のステップ:
- 残りステップがある場合: /wf5-implement
- 全ステップ完了: /wf6-verify
```

## Plan外の変更について

Plan に記載されていない変更が必要な場合：

1. **軽微な修正**（タイポ、インポート追加など）
   → 実装ログの Notes に記録して続行

2. **重要な変更**（設計変更、追加機能など）
   → 実装を中断し、Plan の更新を提案
   ```
   ⚠️ Plan外の変更が必要です

   発見した問題:
   - <問題の説明>

   提案:
   - /wf3-plan update で Plan を更新してください
   ```

## 注意事項

- **1回の実行で1ステップのみ**
- **Plan外の変更は原則禁止**
- 依存ステップが未完了の場合はエラー
- テスト失敗時は修正してから完了
- コミットメッセージは Conventional Commits 形式
