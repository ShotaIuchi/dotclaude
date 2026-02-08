# スキルシステム

Claudeにプロジェクト固有の知識とベストプラクティスを提供するスキル定義。

## 概要

スキルは特定のドメインや技術スタックに関する専門知識を定義します。
references/からの知識を参照し、プロジェクトに最適化されたガイダンスを提供します。

## スキル一覧

### ワークフロー管理

| スキル | 目的 |
|--------|------|
| `wf0-config` | WF設定の対話的編集 (`show`, `init`, カテゴリ指定) |
| `wf0-nextstep` | 次のワークフローステップを実行 |
| `wf0-promote` | ローカルワークフローをGitHub/Jiraに昇格 |
| `wf0-remote` | GitHub Issueコメント経由でリモート操作 (`start`, `stop`, `status`) |
| `wf0-restore` | 既存ワークスペースの復元 |
| `wf0-status` | 現在のワークフロー状態を表示 |
| `sh1-create` | スケジュール管理 (`create`, `show`, `edit`, `validate`, `clear`) |
| `sh2-run` | スケジュールから次タスクを実行 (`--dry-run`, `--until`, `--all`) |
| `wf1-kickoff` | 新規ワークスペースとKickoffドキュメント作成 |
| `wf2-spec` | 仕様書ドキュメント作成 |
| `wf3-plan` | 実装計画ドキュメント作成 |
| `wf4-review` | PlanまたはコードのレビューRecord作成 |
| `wf5-implement` | Planの1ステップを実装 |
| `wf6-verify` | 実装検証とPR作成 |

### アーキテクチャ

| スキル | 目的 |
|--------|------|
| `android-architecture` | Androidアプリアーキテクチャ設計 |
| `ios-architecture` | iOSアプリアーキテクチャ設計 |
| `kmp-architecture` | Kotlin Multiplatformアーキテクチャ設計 |
| `aws-sam` | AWS SAMテンプレートとLambda実装 |

### Agent Teams

並列サブエージェントで専門分析を行うチームスキル。親チーム（`/team-name`）がトピックを分析し、適切な専門家を選択・起動します。

#### review-team — コードレビュー

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `review-security` | セキュリティレビュアー | 深刻度: Critical / High / Medium / Low / Info |
| `review-architecture` | アーキテクチャレビュアー | 分類: Violation / Concern / Suggestion / Positive |
| `review-performance` | パフォーマンスレビュアー | 影響度: Critical / High / Medium / Low |
| `review-concurrency` | 並行処理レビュアー | — |
| `review-error-handling` | エラーハンドリングレビュアー | — |
| `review-api-design` | API設計レビュアー | — |
| `review-test-coverage` | テストカバレッジレビュアー | — |
| `review-dependency` | 依存関係レビュアー | — |
| `review-accessibility` | アクセシビリティレビュアー | — |
| `review-observability` | オブザーバビリティレビュアー | — |

#### debug-team — バグ原因の並列仮説検証

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `debug-stacktrace` | スタックトレース分析官 | 確信度: High / Medium / Low / Inconclusive |
| `debug-state` | 状態検査官 | 確信度: High / Medium / Low / Inconclusive |
| `debug-concurrency` | 並行処理調査官 | 確信度: High / Medium / Low / Inconclusive |
| `debug-dataflow` | データフロー追跡官 | 確信度: High / Medium / Low / Inconclusive |
| `debug-environment` | 環境チェッカー | 確信度: High / Medium / Low / Inconclusive |
| `debug-dependency` | 依存関係監査官 | 確信度: High / Medium / Low / Inconclusive |
| `debug-reproduction` | 再現スペシャリスト | 確信度: High / Medium / Low / Inconclusive |

#### design-team — 設計検討・複数視点議論

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `design-pragmatist` | 実用主義者 | 強度: Strong / Moderate / Weak / Neutral |
| `design-futurist` | 未来志向者 | 強度: Strong / Moderate / Weak / Neutral |
| `design-skeptic` | 懐疑論者 | 強度: Strong / Moderate / Weak / Neutral |
| `design-domain` | ドメインエキスパート | 強度: Strong / Moderate / Weak / Neutral |
| `design-user-advocate` | ユーザー代弁者 | 強度: Strong / Moderate / Weak / Neutral |
| `design-cost` | コスト分析官 | 強度: Strong / Moderate / Weak / Neutral |
| `design-standards` | 標準規格管理者 | 強度: Strong / Moderate / Weak / Neutral |

#### feature-team — 新機能の並列実装

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `feature-api` | API設計者 | 状態: Complete / Partial / Blocked / Skipped |
| `feature-ui` | UI実装者 | 状態: Complete / Partial / Blocked / Skipped |
| `feature-data` | データモデラー | 状態: Complete / Partial / Blocked / Skipped |
| `feature-logic` | ビジネスロジック実装者 | 状態: Complete / Partial / Blocked / Skipped |
| `feature-test` | テスト作成者 | 状態: Complete / Partial / Blocked / Skipped |
| `feature-doc` | ドキュメント作成者 | 状態: Complete / Partial / Blocked / Skipped |
| `feature-security` | セキュリティ分析官 | 状態: Complete / Partial / Blocked / Skipped |

#### migration-team — 技術移行の並列実行

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `migration-breaking` | 破壊的変更分析官 | リスク: Critical / High / Medium / Low |
| `migration-compatibility` | 互換性ブリッジ構築者 | リスク: Critical / High / Medium / Low |
| `migration-transform` | コード変換者 | リスク: Critical / High / Medium / Low |
| `migration-data` | データ移行者 | リスク: Critical / High / Medium / Low |
| `migration-test` | テスト移行者 | リスク: Critical / High / Medium / Low |
| `migration-rollback` | ロールバック計画者 | リスク: Critical / High / Medium / Low |
| `migration-resolver` | 依存関係解決者 | リスク: Critical / High / Medium / Low |

#### refactor-team — 大規模リファクタリング

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `refactor-dependency` | 依存関係マッパー | 影響度: Breaking / High / Medium / Low |
| `refactor-archeology` | コード考古学者 | 影響度: Breaking / High / Medium / Low |
| `refactor-pattern` | パターン分析官 | 影響度: Breaking / High / Medium / Low |
| `refactor-migration` | 移行計画者 | 影響度: Breaking / High / Medium / Low |
| `refactor-test` | テスト守護者 | 影響度: Breaking / High / Medium / Low |
| `refactor-impact` | 影響評価者 | 影響度: Breaking / High / Medium / Low |
| `refactor-compat` | 互換性チェッカー | 影響度: Breaking / High / Medium / Low |

#### test-team — テスト一括作成

| スキル | 専門家 | 評価指標 |
|--------|--------|---------|
| `test-unit` | ユニットテスト作成者 | 優先度: Must / Should / Could / Won't |
| `test-integration` | 統合テスト作成者 | 優先度: Must / Should / Could / Won't |
| `test-edge` | エッジケーススペシャリスト | 優先度: Must / Should / Could / Won't |
| `test-mock` | モック/フィクスチャ設計者 | 優先度: Must / Should / Could / Won't |
| `test-performance` | パフォーマンステスト作成者 | 優先度: Must / Should / Could / Won't |
| `test-security` | セキュリティテスト作成者 | 優先度: Must / Should / Could / Won't |
| `test-snapshot` | スナップショットテスト作成者 | 優先度: Must / Should / Could / Won't |

## 使用方法

スキルは2つの方法で呼び出せます：

### スラッシュコマンド

スキル名をスラッシュコマンドとして使用：

```
# ワークフロー
/wf0-status
/wf1-kickoff github=123
/wf2-spec
/wf3-plan
/wf4-review
/wf5-implement
/wf6-verify pr

# バッチ処理
/sh1-create create github="label:batch"
/sh2-run --dry-run

# アーキテクチャ
/android-architecture
/ios-architecture
/kmp-architecture
/aws-sam
```

### コンテキスト参照

プロンプト内でスキルを参照：

```
このプロジェクトのandroid-architectureスキルに従って実装してください。
```

## スキル定義フォーマット

各スキルは以下の形式で定義されます。

```markdown
---
name: スキル名
description: 説明（英語）
references:
  - path: ../references/...
external:
  - id: external-doc-id
---

# スキル名

## Purpose
{このスキルが提供するガイダンス}

## Use Cases
{このスキルを使用すべき状況}

## Key Principles
{従うべき原則}

## Implementation Patterns
{推奨される実装パターン}
```

## ディレクトリ構造

```
skills/
├── README.md                    # このファイル
├── wf0-config/
│   └── SKILL.md
├── wf0-nextstep/
│   └── SKILL.md
├── wf0-promote/
│   └── SKILL.md
├── wf0-remote/
│   └── SKILL.md
├── wf0-restore/
│   └── SKILL.md
├── wf0-status/
│   └── SKILL.md
├── sh1-create/
│   └── SKILL.md
├── sh2-run/
│   └── SKILL.md
├── wf1-kickoff/
│   └── SKILL.md
├── wf2-spec/
│   └── SKILL.md
├── wf3-plan/
│   └── SKILL.md
├── wf4-review/
│   └── SKILL.md
├── wf5-implement/
│   └── SKILL.md
├── wf6-verify/
│   └── SKILL.md
├── android-architecture/
│   └── SKILL.md
├── ios-architecture/
│   └── SKILL.md
├── kmp-architecture/
│   └── SKILL.md
└── aws-sam/
    └── SKILL.md
```

## references/との関係

スキルはreferences/からの知識を参照します。

```
skills/android-architecture/SKILL.md
  → references: ../references/platforms/android/...

skills/aws-sam/SKILL.md
  → references: ../references/services/aws/...
```

## 新しいスキルの追加手順

1. `skills/{skill-name}/`ディレクトリを作成
2. `SKILL.md`を作成（上記フォーマットに従う）
3. 必要なreferences/へのパスを設定
4. このREADME.mdのスキル一覧を更新

### 検証手順

新しいスキルを追加した後、正しく動作することを確認：

1. **構文チェック**: SKILL.mdのフロントマターが有効なYAMLであることを確認
2. **参照検証**: 参照されているすべてのファイルが存在することを確認
3. **呼び出しテスト**: Claudeで`/{skill-name}`を使ってスキルを呼び出してみる
4. **コンテキストテスト**: スキル呼び出し時にClaudeが正しくスキルコンテキストを読み込むことを確認
