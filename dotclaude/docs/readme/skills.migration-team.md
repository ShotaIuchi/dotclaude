# /migration-team

Agent Teamsで技術移行の並列実行チームを自動構成・起動する。

## 目的

- 複数の専門家による技術移行の並列実行
- 移行種別に応じたスペシャリストの自動選定

## 使用方法

```
/migration-team [--pr N | --diff | migration target]
```

## 使用例

```bash
# 移行対象を指定
/migration-team "React 17から18への移行"

# PRの移行内容をレビュー
/migration-team --pr 456

# 差分から移行を分析
/migration-team --diff
```

## 動作の流れ

1. リード（メインコンテキスト）が移行スコープを分析し、移行種別を判定
2. 選定マトリクスに基づきスペシャリストを選定（最大7種）
3. **Task tool** で各スペシャリストをサブエージェントとして並列起動
4. 各サブエージェントの結果をリードが統合し、フェーズ別移行レポートを作成

## スペシャリスト一覧

| スペシャリスト | 観点 |
|-------------|------|
| Breaking Change Analyst | 非互換変更、削除API、動作差異 |
| Compatibility Bridge Builder | 互換レイヤー、アダプター、段階的移行 |
| Code Transformer | コード変換、codemod、パターン置換 |
| Data Migrator | スキーマ移行、データ形式変換 |
| Test Migrator | テストコード更新、モック適応 |
| Rollback Planner | ロールバック手順、フィーチャーフラグ |
| Dependency Resolver | 依存関係競合、バージョン互換性 |

## 注意事項

- 各スペシャリストは別コンテキスト（サブエージェント）で動作する
- 全サブエージェントが並列実行されるため、トークン消費が増加する
