# /team-test

Agent Teamsでテスト一括作成チームを自動構成・起動する。

## 目的

- 複数の専門テストライターによる包括的テストスイート作成
- コード種別に応じたテストライターの自動選定

## 使用方法

```
/team-test [--pr N | --commit REF | --diff | --staged | path | module]
```

## 使用例

```bash
# 特定ディレクトリのテストを作成
/team-test src/auth/

# PRの変更に対するテストを作成
/team-test --pr 123

# ステージ済み変更のテストを作成
/team-test --staged
```

## 動作の流れ

1. リード（メインコンテキスト）がターゲットコードを分析し、テスト対象の種別を判定
2. 選定マトリクスに基づきテストライターを選定（最大7種）
3. **Task tool** で各テストライターをサブエージェントとして並列起動
4. 各サブエージェントの結果をリードが統合し、カバレッジレポートを作成

## テストライター一覧

| テストライター | 観点 |
|--------------|------|
| Unit Test Writer | 関数・メソッド・クラスの単体テスト |
| Integration Test Writer | コンポーネント間連携、API契約、DB操作 |
| Edge Case Specialist | 境界条件、null入力、オーバーフロー |
| Mock/Fixture Designer | モック、スタブ、テストデータ設計 |
| Performance Test Writer | ベンチマーク、負荷テスト |
| Security Test Writer | 認証、入力検証、インジェクション防止 |
| Snapshot/Golden Test Writer | UIスナップショット、レスポンス形式 |

## 注意事項

- 各テストライターは別コンテキスト（サブエージェント）で動作する
- 全サブエージェントが並列実行されるため、トークン消費が増加する
