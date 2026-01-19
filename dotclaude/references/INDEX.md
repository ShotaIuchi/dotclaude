# References 索引

skills/ から参照される共有リファレンスの索引。

---

## ディレクトリ構造

```
references/
├── INDEX.md                    # この索引 + 設計原則リンク
├── common/                     # 全 skill 共通（index.md なし）
│   ├── clean-architecture.md
│   └── testing-strategy.md
├── kotlin/                     # Kotlin/Android/KMP 共通
│   ├── index.md
│   ├── coroutines.md
│   └── kmp-architecture.md
├── android/                    # Android 固有
│   ├── index.md
│   └── architecture.md
├── ios/                        # iOS 固有
│   ├── index.md
│   └── architecture.md
└── aws/                        # AWS 関連
    ├── index.md
    └── sam-template.md
```

---

## 設計原則（外部リンク）

全スキル共通で参照すべき設計原則の原典。

| 原則 | リンク | 優先度 |
|------|--------|--------|
| Clean Architecture | [The Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) | ★★★ 原典 |
| SOLID Principles | [SOLID (Wikipedia)](https://en.wikipedia.org/wiki/SOLID) | ★★ 基礎知識 |
| Dependency Injection | [Dependency Injection (Wikipedia)](https://en.wikipedia.org/wiki/Dependency_injection) | ★★ 基礎知識 |

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
| [index.md](kotlin/index.md) | 構成・優先順位・外部リンク | android, kmp |
| [coroutines.md](kotlin/coroutines.md) | Kotlin Coroutines ベストプラクティス | android, kmp |
| [kmp-architecture.md](kotlin/kmp-architecture.md) | Kotlin Multiplatform アーキテクチャ | kmp |

### android/ - Android 固有

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](android/index.md) | 構成・優先順位・外部リンク | android |
| [architecture.md](android/architecture.md) | Android MVVM/UDF アーキテクチャ詳細 | android |

### ios/ - iOS 固有

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](ios/index.md) | 構成・優先順位・外部リンク | ios |
| [architecture.md](ios/architecture.md) | iOS SwiftUI/MVVM アーキテクチャ詳細 | ios |

### aws/ - AWS 関連

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](aws/index.md) | 構成・優先順位・外部リンク | aws-sam |
| [sam-template.md](aws/sam-template.md) | AWS SAM テンプレートと実装パターン | aws-sam |

---

## スキル別参照マップ

### android-architecture

```yaml
references:
  - path: ../references/android/index.md          # まず index.md を参照
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/kotlin/coroutines.md
  - path: ../references/android/architecture.md
```

### ios-architecture

```yaml
references:
  - path: ../references/ios/index.md              # まず index.md を参照
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/ios/architecture.md
```

### kmp-architecture

```yaml
references:
  - path: ../references/kotlin/index.md           # まず index.md を参照
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/kotlin/coroutines.md
  - path: ../references/kotlin/kmp-architecture.md
```

### aws-sam

```yaml
references:
  - path: ../references/aws/index.md              # まず index.md を参照
  - path: ../references/aws/sam-template.md
```

---

## 使用方法

### SKILL.md でのリファレンス指定

```yaml
---
name: Skill Name
description: ...
references:
  - path: ../references/{category}/index.md       # まず index.md を参照
  - path: ../references/{category}/{file}.md      # 詳細ファイル
---
```

### 相対パスの規則

- SKILL.md からの相対パス: `../references/{category}/{file}.md`
- 全てのパスは SKILL.md を起点とする
- 各カテゴリの index.md で外部リンクと優先順位を確認可能
