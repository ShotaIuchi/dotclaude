# スキルシステム

Claudeにプロジェクト固有の知識とベストプラクティスを提供するスキル定義。

## 概要

スキルは特定のドメインや技術スタックに関する専門知識を定義します。
references/からの知識を参照し、プロジェクトに最適化されたガイダンスを提供します。

## スキル一覧

| スキル | 目的 |
|--------|------|
| `android-architecture` | Androidアプリアーキテクチャ設計 |
| `ios-architecture` | iOSアプリアーキテクチャ設計 |
| `kmp-architecture` | Kotlin Multiplatformアーキテクチャ設計 |
| `aws-sam` | AWS SAMテンプレートとLambda実装 |
| `wf0-schedule` | スケジュール管理 (`create`, `show`, `edit`, `validate`, `clear`) |
| `wf0-nexttask` | 次タスク実行 (`--dry-run`, `--until`, `--all`) |

## 使用方法

スキルは2つの方法で呼び出せます：

### スラッシュコマンド

スキル名をスラッシュコマンドとして使用：

```
/android-architecture
/ios-architecture
/kmp-architecture
/aws-sam
/wf0-schedule
/wf0-nexttask
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
├── README.md                 # このファイル
├── android-architecture/
│   └── SKILL.md
├── ios-architecture/
│   └── SKILL.md
├── kmp-architecture/
│   └── SKILL.md
├── aws-sam/
│   └── SKILL.md
├── wf0-schedule/
│   └── SKILL.md
└── wf0-nexttask/
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
