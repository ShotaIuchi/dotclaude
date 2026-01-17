# /wf2-spec

仕様書（Spec）を作成するコマンド。

## 使用方法

```
/wf2-spec [サブコマンド]
```

## サブコマンド

- `(なし)`: 新規作成
- `update`: 既存の Spec を更新
- `validate`: Kickoff との整合性を確認

## 処理内容

$ARGUMENTS を解析して以下の処理を実行してください。

### 1. 前提条件の確認

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
spec_path="$docs_dir/01_SPEC.md"

# Kickoff が存在するか確認
if [ ! -f "$kickoff_path" ]; then
  echo "Kickoff ドキュメントがありません"
  echo "/wf1-kickoff を先に実行してください"
  exit 1
fi
```

### 2. Kickoff の読み込みと分析

```bash
cat "$kickoff_path"
```

Kickoff から以下を抽出：
- Goal
- Success Criteria
- Constraints
- Dependencies

### 3. コードベースの調査

Kickoff の内容に基づいて関連コードを調査：

- 影響を受けるファイルの特定
- 既存の実装パターンの確認
- 関連するテストの確認
- 既存の仕様書（`docs/spec/`）との整合性確認

### 4. Spec の作成

**テンプレート参照:** `~/.claude/templates/01_SPEC.md` を読み込んで使用してください。

テンプレートのプレースホルダを調査結果と Kickoff の内容で置換します。

### 5. 整合性の確認

以下の点を確認：

1. **Kickoff との整合性**
   - Goal が Spec に反映されているか
   - Success Criteria が達成可能な変更か
   - Constraints が考慮されているか

2. **既存仕様との整合性**
   - `docs/spec/` 内の仕様書と矛盾がないか
   - 既存の API 仕様と互換性があるか

3. **テスト戦略の妥当性**
   - Success Criteria を検証できるテストがあるか

### 6. state.json の更新

```bash
jq ".works[\"$work_id\"].current = \"wf2-spec\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].next = \"wf3-plan\"" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 7. 完了メッセージ

```
✅ Spec ドキュメントを作成しました

ファイル: docs/wf/<work-id>/01_SPEC.md

Affected Components:
- <component1> (high)
- <component2> (medium)

次のステップ: /wf3-plan を実行して実装計画を作成してください
```

## validate サブコマンド

既存の Spec と Kickoff の整合性を確認：

```
📋 Spec Validation: <work-id>
═══════════════════════════════════════

Kickoff → Spec 整合性チェック:

[✓] Goal が Overview に反映されている
[✓] Success Criteria が Test Strategy でカバーされている
[!] Constraint "パフォーマンス要件" が考慮されていない
[ ] Dependency "認証API" の影響が未記載

結果: 2 warnings, 1 missing
```

## 注意事項

- Kickoff の内容を勝手に変更しない
- 既存の仕様書との矛盾がある場合は警告
- 技術的に実現不可能な場合は Kickoff の修正を提案
