# /debug-team

Agent Teamsでバグ原因の並列仮説検証チームを自動構成・起動する。

## 目的

- 複数の仮説を並列に検証してバグの根本原因を特定
- バグの種類に応じた調査員の自動選定

## 使用方法

```
/debug-team [--issue N | --pr N | --commit REF | --diff | path | text]
```

## 使用例

```bash
# Issueのバグを調査
/debug-team --issue 456

# エラーメッセージから調査
/debug-team "NullPointerException in AuthService.login"

# 特定ファイルを調査
/debug-team src/auth/login.kt
```

## 動作の流れ

1. リード（メインコンテキスト）がバグ症状を分析し、バグ種別を判定
2. 3-7個の独立した仮説を生成
3. 選定マトリクスに基づき調査員を選定（最大7種）
4. **Task tool** で各調査員をサブエージェントとして並列起動
5. 各サブエージェントの結果をリードが統合し、確信度付きの根本原因分析を作成

## 調査員一覧

| 調査員 | 観点 |
|--------|------|
| Stack Trace Analyzer | エラーメッセージ、例外チェーン、障害箇所特定 |
| State Inspector | 状態破損、データ不整合、予期しない副作用 |
| Concurrency Investigator | 競合状態、デッドロック、タイミング依存バグ |
| Data Flow Tracer | データ変換、型変換、null伝播 |
| Environment Checker | 環境変数、権限、プラットフォーム差異 |
| Dependency Auditor | バージョン競合、既知バグ、非互換性 |
| Reproduction Specialist | 最小再現手順の特定、トリガー条件の分離 |

## 注意事項

- 各調査員は別コンテキスト（サブエージェント）で動作する
- 全サブエージェントが並列実行されるため、トークン消費が増加する
