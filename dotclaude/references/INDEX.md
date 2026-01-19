# References 索引

skills/ から参照される共有リファレンスの索引。

---

## ディレクトリ構造

```
references/
├── INDEX.md                    # この索引 + 設計原則リンク
├── common/                     # 全カテゴリ共通（ルートに残す）
│   ├── clean-architecture.md
│   └── testing-strategy.md
├── platforms/                  # プラットフォーム
│   ├── android/
│   │   ├── index.md
│   │   └── architecture.md
│   └── ios/
│       ├── index.md
│       └── architecture.md
├── languages/                  # 言語
│   └── kotlin/
│       ├── index.md
│       ├── coroutines.md
│       └── kmp-architecture.md
└── services/                   # クラウドサービス
    └── aws/
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

### platforms/android/ - Android 固有

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](platforms/android/index.md) | 構成・優先順位・外部リンク | android |
| [architecture.md](platforms/android/architecture.md) | Android MVVM/UDF アーキテクチャ詳細 | android |

### platforms/ios/ - iOS 固有

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](platforms/ios/index.md) | 構成・優先順位・外部リンク | ios |
| [architecture.md](platforms/ios/architecture.md) | iOS SwiftUI/MVVM アーキテクチャ詳細 | ios |

### languages/kotlin/ - Kotlin 関連

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](languages/kotlin/index.md) | 構成・優先順位・外部リンク | android, kmp |
| [coroutines.md](languages/kotlin/coroutines.md) | Kotlin Coroutines ベストプラクティス | android, kmp |
| [kmp-architecture.md](languages/kotlin/kmp-architecture.md) | Kotlin Multiplatform アーキテクチャ | kmp |

### services/aws/ - AWS 関連

| ファイル | 説明 | 関連スキル |
|---------|------|-----------|
| [index.md](services/aws/index.md) | 構成・優先順位・外部リンク | aws-sam |
| [sam-template.md](services/aws/sam-template.md) | AWS SAM テンプレートと実装パターン | aws-sam |

---

## スキル別参照マップ

### android-architecture

```yaml
references:
  - path: ../references/platforms/android/index.md   # まず index.md を参照
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/coroutines.md
  - path: ../references/platforms/android/architecture.md
```

### ios-architecture

```yaml
references:
  - path: ../references/platforms/ios/index.md       # まず index.md を参照
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/ios/architecture.md
```

### kmp-architecture

```yaml
references:
  - path: ../references/languages/kotlin/index.md    # まず index.md を参照
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/coroutines.md
  - path: ../references/languages/kotlin/kmp-architecture.md
```

### aws-sam

```yaml
references:
  - path: ../references/services/aws/index.md        # まず index.md を参照
  - path: ../references/services/aws/sam-template.md
```

---

## 使用方法

### SKILL.md でのリファレンス指定

```yaml
---
name: Skill Name
description: ...
references:
  - path: ../references/{group}/{category}/index.md  # まず index.md を参照
  - path: ../references/{group}/{category}/{file}.md # 詳細ファイル
---
```

### 相対パスの規則

- SKILL.md からの相対パス: `../references/{group}/{category}/{file}.md`
- 全てのパスは SKILL.md を起点とする
- 各カテゴリの index.md で外部リンクと優先順位を確認可能

### グループ分類

| グループ | 説明 | 例 |
|---------|------|-----|
| common/ | 全カテゴリ共通 | clean-architecture, testing-strategy |
| platforms/ | プラットフォーム固有 | android, ios |
| languages/ | プログラミング言語固有 | kotlin |
| services/ | クラウドサービス固有 | aws |
