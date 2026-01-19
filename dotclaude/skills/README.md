# スキル体系

プロジェクト固有の知識・ベストプラクティスを Claude に提供するスキル定義。

## 概要

スキルは特定のドメインや技術スタックに関する専門知識を定義します。
references/ からナレッジを参照し、プロジェクトに最適化されたガイダンスを提供します。

## スキル一覧

| スキル | 用途 |
|-------|------|
| `android-architecture` | Android アプリのアーキテクチャ設計 |
| `ios-architecture` | iOS アプリのアーキテクチャ設計 |
| `kmp-architecture` | Kotlin Multiplatform のアーキテクチャ設計 |
| `aws-sam` | AWS SAM テンプレート・Lambda 実装 |

## 使用方法

スキルはプロンプトに含めることで Claude がそのコンテキストを理解します。

```
このプロジェクトでは android-architecture スキルに従って実装してください。
```

## スキル定義形式

各スキルは以下の形式で定義されています。

```markdown
---
name: スキル名
description: 説明（英語）
references:
  - path: ../references/...
---

# スキル名

## 目的
{このスキルが提供するガイダンス}

## 適用場面
{どのような場面で使用するか}

## 主要な原則
{守るべき原則}

## 実装パターン
{推奨される実装パターン}
```

## ディレクトリ構成

```
skills/
├── README.md                 # このファイル
├── android-architecture/
│   └── SKILL.md
├── ios-architecture/
│   └── SKILL.md
├── kmp-architecture/
│   └── SKILL.md
└── aws-sam/
    └── SKILL.md
```

## references/ との関係

スキルは references/ のナレッジを参照します。

```
skills/android-architecture/SKILL.md
  → references: ../references/platforms/android/...

skills/aws-sam/SKILL.md
  → references: ../references/services/aws/...
```

## 新規スキル追加時の手順

1. `skills/{skill-name}/` ディレクトリを作成
2. `SKILL.md` を作成（上記形式に従う）
3. 必要な references/ へのパスを設定
4. この README.md のスキル一覧を更新
