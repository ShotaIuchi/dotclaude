# skills/

スキル定義ディレクトリ。

## 概要

Claudeにプロジェクト固有の知識とベストプラクティスを提供するスキルを定義。
スラッシュコマンドとして呼び出し可能。

## 構造

```
skills/
├── README.md               # 詳細ドキュメント
├── android-architecture/   # Androidアーキテクチャ
│   └── SKILL.md
├── ios-architecture/       # iOSアーキテクチャ
│   └── SKILL.md
├── kmp-architecture/       # KMPアーキテクチャ
│   └── SKILL.md
└── aws-sam/                # AWS SAM
    └── SKILL.md
```

## スキル一覧

| スキル | 目的 |
|--------|------|
| `android-architecture` | AndroidアプリMVVM/UDF設計 |
| `ios-architecture` | iOSアプリSwiftUI/MVVM設計 |
| `kmp-architecture` | Kotlin Multiplatform設計 |
| `aws-sam` | AWS SAMテンプレート・Lambda実装 |

## 使用方法

```bash
# スラッシュコマンドとして
/android-architecture
/kmp-architecture

# プロンプト内で参照
このプロジェクトのkmp-architectureスキルに従って実装してください。
```

## スキル定義形式

```markdown
---
name: スキル名
description: 説明
references:
  - path: ../references/...
---

# スキル名

## Purpose
## Use Cases
## Key Principles
## Implementation Patterns
```

## 関連

- 詳細: [`skills/README.md`](skills/README.md)
- 参照先: [`references/`](references/)
