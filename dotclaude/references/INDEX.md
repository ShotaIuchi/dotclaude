# References 索引

skills/ から参照される共有リファレンスの索引。

---

## ディレクトリ構造

```
references/
├── INDEX.md             # この索引
├── common/              # 全 skill 共通
│   ├── clean-architecture.md
│   └── testing-strategy.md
├── kotlin/              # Kotlin/Android/KMP 共通
│   ├── coroutines.md
│   └── kmp-architecture.md
├── android/             # Android 固有
│   └── architecture.md
├── ios/                 # iOS 固有
│   └── architecture.md
├── aws/                 # AWS 関連
│   └── sam-template.md
└── external/            # 外部URL管理
    └── links.yaml
```

---

## カテゴリ別索引

### common/ - 共通リファレンス

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [clean-architecture.md](common/clean-architecture.md) | クリーンアーキテクチャの原則とパターン | android, ios, kmp |
| [testing-strategy.md](common/testing-strategy.md) | テスト戦略とベストプラクティス | android, ios, kmp |

### kotlin/ - Kotlin 関連

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [coroutines.md](kotlin/coroutines.md) | Kotlin Coroutines ベストプラクティス | android, kmp |
| [kmp-architecture.md](kotlin/kmp-architecture.md) | Kotlin Multiplatform アーキテクチャ | kmp |

### android/ - Android 固有

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [architecture.md](android/architecture.md) | Android MVVM/UDF アーキテクチャ詳細 | android |

### ios/ - iOS 固有

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [architecture.md](ios/architecture.md) | iOS SwiftUI/MVVM アーキテクチャ詳細 | ios |

### aws/ - AWS 関連

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [sam-template.md](aws/sam-template.md) | AWS SAM テンプレートと実装パターン | aws-sam |

### external/ - 外部リンク

| ファイル | 説明 |
|---------|------|
| [links.yaml](external/links.yaml) | 外部URL一元管理 |

---

## スキル別参照マップ

### android-architecture

```yaml
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/kotlin/coroutines.md
  - path: ../references/android/architecture.md
external:
  - id: android-arch-guide
  - id: jetpack-compose-docs
```

### ios-architecture

```yaml
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/ios/architecture.md
external:
  - id: swift-concurrency
  - id: swiftui-docs
```

### kmp-architecture

```yaml
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/kotlin/coroutines.md
  - path: ../references/kotlin/kmp-architecture.md
external:
  - id: kmp-docs
  - id: compose-multiplatform
```

### aws-sam

```yaml
references:
  - path: ../references/aws/sam-template.md
external:
  - id: aws-sam-docs
  - id: aws-lambda-docs
```

---

## 使用方法

### SKILL.md でのリファレンス指定

```yaml
---
name: Skill Name
description: ...
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/kotlin/coroutines.md
  external:
    - id: android-arch-guide
---
```

### 相対パスの規則

- SKILL.md からの相対パス: `../references/{category}/{file}.md`
- 全てのパスは SKILL.md を起点とする
