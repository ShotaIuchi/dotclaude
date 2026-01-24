# リファレンス索引

skills/ から参照される共有リファレンスの索引。

---

## ディレクトリ構造

```
references/
├── INDEX.md                    # この索引 + 設計原則リンク
├── common/                     # 全カテゴリ共通（ルートに配置）
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
│       ├── kmp-architecture.md
│       ├── kmp-auth.md
│       ├── kmp-camera.md
│       ├── kmp-compose-ui.md
│       ├── kmp-data-sqldelight.md
│       ├── kmp-di-koin.md
│       ├── kmp-error-handling.md
│       ├── kmp-expect-actual.md
│       ├── kmp-network-ktor.md
│       ├── kmp-state-udf.md
│       └── kmp-testing.md
├── services/                   # クラウドサービス
│   └── aws/
│       ├── index.md
│       └── sam-template.md
└── tools/                      # 開発ツール
    └── claude-code/
        ├── index.md
        ├── skills-guide.md
        ├── commands-guide.md
        ├── command-frontmatter.md
        └── best-practices.md
```

---

## 設計原則（外部リンク）

全てのスキルが参照すべき設計原則の権威あるソース。

| 原則 | 説明 | リンク | 優先度 |
|------|------|--------|--------|
| Clean Architecture | 依存関係が内向きに向かう同心円レイヤーによる関心の分離 | [The Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) | ★★★ オリジナル |
| SOLID原則 | 5つのオブジェクト指向設計原則（単一責任、開放閉鎖、リスコフ置換、インターフェース分離、依存性逆転） | [SOLID (Wikipedia)](https://en.wikipedia.org/wiki/SOLID) | ★★ 基盤 |
| 依存性注入 | オブジェクトが依存関係を自ら作成するのではなく、外部ソースから受け取る設計パターン | [Dependency Injection (Wikipedia)](https://en.wikipedia.org/wiki/Dependency_injection) | ★★ 基盤 |

---

## カテゴリ索引

### common/ - 共通リファレンス

| ファイル | 説明 | 関連スキル |
|----------|------|------------|
| [clean-architecture.md](common/clean-architecture.md) | Clean Architecture の原則とパターン | android, ios, kmp |
| [testing-strategy.md](common/testing-strategy.md) | テスト戦略とベストプラクティス | android, ios, kmp |

### platforms/android/ - Android固有

| ファイル | 説明 | 関連スキル |
|----------|------|------------|
| [index.md](platforms/android/index.md) | 構造、優先度、外部リンク | android |
| [architecture.md](platforms/android/architecture.md) | Android MVVM/UDF アーキテクチャ詳細 | android |

### platforms/ios/ - iOS固有

| ファイル | 説明 | 関連スキル |
|----------|------|------------|
| [index.md](platforms/ios/index.md) | 構造、優先度、外部リンク | ios |
| [architecture.md](platforms/ios/architecture.md) | iOS SwiftUI/MVVM アーキテクチャ詳細 | ios |

### languages/kotlin/ - Kotlin関連

| ファイル | 説明 | 関連スキル |
|----------|------|------------|
| [index.md](languages/kotlin/index.md) | 構造、優先度、外部リンク | android, kmp |
| [coroutines.md](languages/kotlin/coroutines.md) | Kotlin Coroutines ベストプラクティス | android, kmp |
| [kmp-architecture.md](languages/kotlin/kmp-architecture.md) | Kotlin Multiplatform アーキテクチャ | kmp |
| [kmp-auth.md](languages/kotlin/kmp-auth.md) | KMP 認証パターン | kmp |
| [kmp-camera.md](languages/kotlin/kmp-camera.md) | KMP カメラ統合 | kmp |
| [kmp-compose-ui.md](languages/kotlin/kmp-compose-ui.md) | Compose Multiplatform UI パターン | kmp |
| [kmp-data-sqldelight.md](languages/kotlin/kmp-data-sqldelight.md) | SQLDelight データ永続化 | kmp |
| [kmp-di-koin.md](languages/kotlin/kmp-di-koin.md) | Koin 依存性注入 | kmp |
| [kmp-error-handling.md](languages/kotlin/kmp-error-handling.md) | KMP エラーハンドリングパターン | kmp |
| [kmp-expect-actual.md](languages/kotlin/kmp-expect-actual.md) | expect/actual 宣言 | kmp |
| [kmp-network-ktor.md](languages/kotlin/kmp-network-ktor.md) | Ktor ネットワーキング | kmp |
| [kmp-state-udf.md](languages/kotlin/kmp-state-udf.md) | 単方向データフロー状態管理 | kmp |
| [kmp-testing.md](languages/kotlin/kmp-testing.md) | KMP テスト戦略 | kmp |

### services/aws/ - AWS関連

| ファイル | 説明 | 関連スキル |
|----------|------|------------|
| [index.md](services/aws/index.md) | 構造、優先度、外部リンク | aws-sam |
| [sam-template.md](services/aws/sam-template.md) | AWS SAM テンプレートと実装パターン | aws-sam |

### tools/claude-code/ - Claude Code

| ファイル | 説明 | 関連スキル |
|----------|------|------------|
| [index.md](tools/claude-code/index.md) | Claude Code リファレンス索引 | - |
| [skills-guide.md](tools/claude-code/skills-guide.md) | スキルの書き方ガイド | - |
| [commands-guide.md](tools/claude-code/commands-guide.md) | コマンドの書き方ガイド | - |
| [command-frontmatter.md](tools/claude-code/command-frontmatter.md) | フロントマター仕様リファレンス | - |
| [best-practices.md](tools/claude-code/best-practices.md) | ベストプラクティス | - |

---

## スキル別リファレンスマップ

> **注記**: 以下のパスは全て `skills/` ディレクトリからの相対パスです。例えば `../references/` はプロジェクトルートの `references/` ディレクトリに解決されます。

### android-architecture

```yaml
references:
  - path: ../references/platforms/android/index.md   # まず index.md を確認
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/coroutines.md
  - path: ../references/platforms/android/architecture.md
```

### ios-architecture

```yaml
references:
  - path: ../references/platforms/ios/index.md       # まず index.md を確認
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/ios/architecture.md
```

### kmp-architecture

```yaml
references:
  - path: ../references/languages/kotlin/index.md    # まず index.md を確認
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/coroutines.md
  - path: ../references/languages/kotlin/kmp-architecture.md
  - path: ../references/languages/kotlin/kmp-auth.md
  - path: ../references/languages/kotlin/kmp-camera.md
  - path: ../references/languages/kotlin/kmp-compose-ui.md
  - path: ../references/languages/kotlin/kmp-data-sqldelight.md
  - path: ../references/languages/kotlin/kmp-di-koin.md
  - path: ../references/languages/kotlin/kmp-error-handling.md
  - path: ../references/languages/kotlin/kmp-expect-actual.md
  - path: ../references/languages/kotlin/kmp-network-ktor.md
  - path: ../references/languages/kotlin/kmp-state-udf.md
  - path: ../references/languages/kotlin/kmp-testing.md
```

### aws-sam

```yaml
references:
  - path: ../references/services/aws/index.md        # まず index.md を確認
  - path: ../references/services/aws/sam-template.md
```

---

## 使い方

### SKILL.md でのリファレンス指定

```yaml
---
name: スキル名
description: ...
references:
  - path: ../references/{group}/{category}/index.md  # まず index.md を確認
  - path: ../references/{group}/{category}/{file}.md # 詳細ファイル
---
```

### 相対パス規則

- SKILL.md からの相対パス: `../references/{group}/{category}/{file}.md`
- すべてのパスは SKILL.md からの相対パス
- 各カテゴリの index.md で外部リンクと優先度を確認可能

### グループ分類

| グループ | 説明 | 例 |
|----------|------|-----|
| common/ | 全カテゴリ共通 | clean-architecture, testing-strategy |
| platforms/ | プラットフォーム固有 | android, ios |
| languages/ | プログラミング言語固有 | kotlin |
| services/ | クラウドサービス固有 | aws |
| tools/ | 開発ツール | claude-code |
