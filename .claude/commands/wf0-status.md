# /wf0-status

現在のワークフロー状態を表示するコマンド。

## 使用方法

```
/wf0-status [work-id]
```

## 引数

- `work-id`: 表示する作業のID（オプション）
  - 省略時: `state.json` の `active_work` を使用
  - `all` を指定: すべての作業を表示

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. state.json の読み込み

```bash
if [ ! -f .wf/state.json ]; then
  echo "WF システムが初期化されていません"
  echo "scripts/wf-init.sh を実行してください"
  exit 1
fi
```

### 2. 表示対象の決定

```bash
arg="$ARGUMENTS"

if [ "$arg" = "all" ]; then
  # すべての作業を表示
  show_all=true
elif [ -n "$arg" ]; then
  # 指定された work-id を表示
  work_id="$arg"
else
  # active_work を表示
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi
```

### 3. 状態表示

#### 単一の作業を表示する場合

```
📋 WF Status: <work-id>
═══════════════════════════════════════

Branch:   <branch>
Base:     <base>
Current:  <current_phase>
Next:     <next_phase>
Created:  <created_at>

📁 Documents:
   docs/wf/<work-id>/
   ├── 00_KICKOFF.md    [exists/missing]
   ├── 01_SPEC.md       [exists/missing]
   ├── 02_PLAN.md       [exists/missing]
   ├── 03_REVIEW.md     [exists/missing]
   ├── 04_IMPLEMENT_LOG.md [exists/missing]
   └── 05_REVISIONS.md  [exists/missing]

🔄 Phase Progress:
   [✓] wf0-workspace
   [→] wf1-kickoff     ← current
   [ ] wf2-spec
   [ ] wf3-plan
   [ ] wf4-review
   [ ] wf5-implement
   [ ] wf6-verify

💡 Next: /<next_phase>
```

#### すべての作業を表示する場合

```
📋 WF Status: All Works
═══════════════════════════════════════

Active: <active_work>

| Work ID | Branch | Current | Next |
|---------|--------|---------|------|
| FEAT-123-export-csv | feat/123-export-csv | wf2-spec | wf3-plan |
| FIX-456-login-error | fix/456-login-error | wf5-implement | wf6-verify |

Total: 2 works
```

### 4. Git 状態の追加表示（オプション）

現在のブランチ情報も表示：

```bash
echo ""
echo "🔀 Git Status:"
echo "   Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "   Uncommitted changes: $(git status --porcelain | wc -l | tr -d ' ')"
```

### 5. worktree 情報（有効な場合）

```bash
if [ "$(jq -r '.worktree.enabled' .wf/config.json)" = "true" ]; then
  worktree_path=$(jq -r ".works[\"$work_id\"].worktree_path // empty" .wf/local.json)
  if [ -n "$worktree_path" ]; then
    echo ""
    echo "🌳 Worktree: $worktree_path"
  fi
fi
```

## 出力形式

- 情報は見やすく整形して表示
- 重要な情報（current, next）は強調
- ドキュメントの存在状況を確認して表示
- フェーズの進捗を視覚的に表示

## 注意事項

- state.json が存在しない場合は初期化を促す
- active_work が設定されていない場合はその旨を表示
- 指定された work-id が存在しない場合はエラー
