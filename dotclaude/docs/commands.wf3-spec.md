# /wf3-spec

仕様書（Spec）ドキュメントを作成するコマンド。

## 使用方法

```
/wf3-spec [subcommand]
```

## サブコマンド

- `(なし)`: 新規作成
- `update`: 既存Specの更新
- `validate`: Kickoffとの整合性チェック

## 処理内容

1. **前提条件チェック**
   - Kickoffドキュメントの存在確認

2. **Kickoffの読み込みと分析**
   - Goal、Success Criteria、Constraints、Dependenciesを抽出

3. **コードベースの調査**
   - GlobとGrepで関連ファイルを発見
   - Exploreエージェントで詳細調査
   - 影響を受けるファイル、既存パターン、関連テストを確認

4. **Specの作成**
   - テンプレートに調査結果とKickoff内容を反映

5. **整合性チェック**
   - Kickoffとの整合性
   - 既存仕様との整合性
   - テスト戦略の妥当性

## validateサブコマンド

既存SpecとKickoffの整合性をチェック:

```
📋 Spec Validation: FEAT-123-export-csv
═══════════════════════════════════════

Kickoff → Spec Consistency Check:

[✓] Goal is reflected in Overview
[✓] Success Criteria are covered in Test Strategy
[!] Constraint "performance requirements" not considered
[ ] Dependency "authentication API" impact not documented

Result: 2 warnings, 1 missing
```

## 出力例

```
✅ Spec document created

File: docs/wf/FEAT-123-export-csv/01_SPEC.md

Affected Components:
- AuthService (high)
- UserRepository (medium)

Next step: Run /wf4-plan to create the implementation plan
```

## 注意事項

- Kickoff内容を勝手に変更しない
- 既存仕様と矛盾がある場合は警告
- 技術的に実現不可能な場合はKickoff修正を提案
