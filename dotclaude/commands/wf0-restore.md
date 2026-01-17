# /wf0-restore

既存のワークスペースを復元するコマンド。別PCでの作業再開や、worktree の再作成に使用。

## 使用方法

```
/wf0-restore [work-id]
```

## 引数

- `work-id`: 復元する作業のID（オプション）
  - 省略時: `state.json` の `active_work` を使用
  - `active_work` もない場合: 候補を提示して選択

## 処理内容

$ARGUMENTS を解析して work-id を取得し、以下の処理を実行してください。

### 1. work-id の解決

```bash
# 引数があれば使用
work_id="$ARGUMENTS"

# なければ active_work を確認
if [ -z "$work_id" ]; then
  work_id=$(jq -r '.active_work // empty' .wf/state.json)
fi

# それでもなければ候補を提示
if [ -z "$work_id" ]; then
  echo "利用可能な work-id:"
  jq -r '.works | keys[]' .wf/state.json
  # ユーザーに選択を促す
fi
```

### 2. リモートの最新情報を取得

```bash
git fetch --all --prune
```

### 3. ブランチの復元

state.json から作業情報を取得：

```bash
branch=$(jq -r ".works[\"$work_id\"].git.branch" .wf/state.json)
base=$(jq -r ".works[\"$work_id\"].git.base" .wf/state.json)
```

ブランチの存在確認と復元：

```bash
# ローカルに存在するか
if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "ローカルブランチが存在します: $branch"
  git checkout "$branch"
# リモートに存在するか
elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  echo "リモートブランチから作成します: $branch"
  git checkout -b "$branch" "origin/$branch"
else
  echo "ERROR: ブランチが見つかりません: $branch"
  exit 1
fi
```

### 4. worktree の復元（オプション）

`config.worktree.enabled` が `true` の場合：

```bash
worktree_root=$(jq -r '.worktree.root_dir // ".worktrees"' .wf/config.json)
worktree_path="$worktree_root/${branch//\//-}"

if [ ! -d "$worktree_path" ]; then
  git worktree add "$worktree_path" "$branch"
  echo "worktree を作成しました: $worktree_path"
fi

# local.json を更新
jq ".works[\"$work_id\"].worktree_path = \"$worktree_path\"" .wf/local.json > .wf/local.json.tmp
mv .wf/local.json.tmp .wf/local.json
```

### 5. active_work の更新

```bash
jq ".active_work = \"$work_id\"" .wf/state.json > .wf/state.json.tmp
mv .wf/state.json.tmp .wf/state.json
```

### 6. 状態表示

```
✅ ワークスペースを復元しました

Work ID: <work-id>
Branch: <branch>
Base: <base>
Current: <current_phase>
Next: <next_phase>

ドキュメント:
- docs/wf/<work-id>/

次のステップ: /<next_phase> を実行してください
```

## 注意事項

- state.json が存在しない場合はエラー
- 指定された work-id が state.json に存在しない場合はエラー
- ブランチがローカルにもリモートにも存在しない場合はエラー
- worktree のルートディレクトリは自動作成
