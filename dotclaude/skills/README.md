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
