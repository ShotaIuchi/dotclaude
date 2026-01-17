# /wf3-plan

実装計画（Plan）を作成するコマンド。

## 使用方法

```
/wf3-plan [サブコマンド]
```

## サブコマンド

- `(なし)`: 新規作成
- `update`: 既存の Plan を更新
- `step <n>`: 特定ステップの詳細を表示

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. 前提条件の確認

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
spec_path="$docs_dir/01_SPEC.md"
plan_path="$docs_dir/02_PLAN.md"

# Spec が存在するか確認
if [ ! -f "$spec_path" ]; then
  echo "Spec ドキュメントがありません"
  echo "/wf2-spec を先に実行してください"
  exit 1
fi
```

### 2. Spec の読み込みと分析

```bash
cat "$spec_path"
```

Spec から以下を抽出：
- Affected Components
- Detailed Changes
- Test Strategy

### 3. コードベースの詳細調査

実装に必要な情報を収集：

1. **対象ファイルの特定**
   - 変更が必要なファイル
   - 新規作成が必要なファイル
   - テストファイル

2. **依存関係の分析**
   - ファイル間の依存関係
   - 変更の順序の決定

3. **リスク評価**
   - 複雑な変更箇所
   - 副作用の可能性

### 4. ステップ分割の原則

以下の原則に従ってステップを分割：

1. **1ステップ = 1回の /wf5-implement**
   - 1回の実装で完了できる範囲
   - コミット単位として適切なサイズ

2. **依存順序を考慮**
   - 基盤となる変更を先に
   - テストは実装と同時または直後

3. **リスク分散**
   - 複雑な変更は分割
   - ロールバックしやすい単位

### 5. Plan の作成

```markdown
# Plan: <work-id>

> Spec: [01_SPEC.md](./01_SPEC.md)
> Created: <timestamp>
> Last Updated: <timestamp>

## Implementation Steps

### Step 1: <タイトル>

**目的:** <このステップで達成すること>

**対象ファイル:**
- `<file1>`
- `<file2>`

**作業内容:**
1. <タスク1>
2. <タスク2>

**完了条件:**
- [ ] <条件1>
- [ ] <条件2>

**見積もり:** <small/medium/large>

---

### Step 2: <タイトル>

**目的:** <このステップで達成すること>

**対象ファイル:**
- `<file3>`

**作業内容:**
1. <タスク1>

**完了条件:**
- [ ] <条件1>

**依存:** Step 1

**見積もり:** <small/medium/large>

---

## Summary

| Step | Title | Status | Notes |
|------|-------|--------|-------|
| 1 | <title1> | pending | |
| 2 | <title2> | pending | |

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| <risk1> | <high/medium/low> | <high/medium/low> | <対策> |

## Notes

<実装時の注意点>
```

### 6. ユーザーとの確認

Plan を作成後、以下を確認：

1. **ステップ数の妥当性**
   - 多すぎないか（目安: 5-10ステップ）
   - 粒度は適切か

2. **依存関係**
   - 順序は正しいか
   - 並行実行可能なステップはあるか

3. **リスク評価**
   - 見落としているリスクはないか

### 7. state.json の更新

```bash
jq ".works[\"$work_id\"].current = \"wf3-plan\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].next = \"wf4-review\"" .wf/state.json > tmp && mv tmp .wf/state.json

# ステップ情報を追加
jq ".works[\"$work_id\"].plan = {\"total_steps\": <n>, \"current_step\": 0, \"steps\": {}}" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 8. 完了メッセージ

```
✅ Plan ドキュメントを作成しました

ファイル: docs/wf/<work-id>/02_PLAN.md

Implementation Steps:
1. <step1_title> (small)
2. <step2_title> (medium)
3. <step3_title> (small)

Total: 3 steps

次のステップ:
- レビューが必要な場合: /wf4-review
- 実装を開始する場合: /wf5-implement
```

## step サブコマンド

特定ステップの詳細を表示：

```
/wf3-plan step 1
```

出力：
```
📋 Step 1: <title>
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

見積もり: medium
依存: なし
```

## 注意事項

- Spec の内容を超える変更を Plan に含めない
- 実装順序は依存関係を厳密に考慮
- 各ステップは単独でテスト可能な単位に
