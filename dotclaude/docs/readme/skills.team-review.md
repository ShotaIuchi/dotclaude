# /team-review

Agent Teamsでターゲットに最適なコードレビューチームを自動構成・起動する。

## 目的

- 複数の専門視点からの並列コードレビュー
- ターゲットの種類に応じたレビュアーの自動選定

## 使用方法

```
/team-review [--pr N | --issue N | --commit REF | --diff | --staged | --branch NAME | path | text]
```

## 使用例

```bash
# PRをレビュー
/team-review --pr 123

# ステージ済み変更をレビュー
/team-review --staged

# 特定ディレクトリをレビュー
/team-review src/auth/
```

## 動作の流れ

1. リード（メインコンテキスト）がターゲットを分析し、プロジェクト種別を判定
2. 選定マトリクスに基づきレビュアーを選定（最大10種）
3. **Task tool** で各レビュアーをサブエージェントとして並列起動
4. 各サブエージェントの結果をリードが統合し、重要度順のレポートを作成

## レビュアー一覧

| レビュアー | 観点 |
|-----------|------|
| Security | 脆弱性、認証、OWASP Top 10 |
| Performance | N+1クエリ、メモリリーク、アルゴリズム効率 |
| Architecture | 設計パターン、SOLID原則、凝集度 |
| Test Coverage | テスト不足、エッジケース |
| Error Handling | 例外処理、リトライ、フォールバック |
| Concurrency | スレッド安全性、デッドロック |
| API Design | REST/GraphQL規約、後方互換性 |
| Accessibility | スクリーンリーダー、WCAG準拠 |
| Dependency | CVE、ライセンス、サプライチェーン |
| Observability | ログ品質、メトリクス、トレーシング |

## 注意事項

- 各レビュアーは別コンテキスト（サブエージェント）で動作する
- 全サブエージェントが並列実行されるため、トークン消費が増加する
