# references/

技術リファレンスディレクトリ。

## 概要

コンテキストルールから参照される技術ドキュメントを格納。
プラットフォーム、言語、サービス、ツールごとに分類。

## 構造

```
references/
├── INDEX.md                        # インデックス（詳細）
├── common/                         # 共通リファレンス
│   ├── clean-architecture.md       # クリーンアーキテクチャ
│   └── testing-strategy.md         # テスト戦略
├── platforms/                      # プラットフォーム固有
│   ├── android/
│   │   ├── architecture-patterns.md
│   │   ├── conventions.md
│   │   └── decisions.md
│   └── ios/
│       ├── architecture-patterns.md
│       ├── conventions.md
│       └── decisions.md
├── languages/                      # 言語固有
│   └── kotlin/
│       ├── conventions.md
│       ├── feature-patterns.md
│       ├── library-patterns.md
│       ├── kmp-architecture-patterns.md
│       └── decisions.md
├── services/                       # クラウドサービス
│   └── aws/
│       ├── sam-architecture-patterns.md
│       ├── conventions.md
│       └── decisions.md
└── tools/                          # 開発ツール
    └── claude-code/
        ├── best-practices.md
        └── decisions.md
```

## グループ分類

| グループ | 説明 | 例 |
|----------|------|-----|
| common/ | 全カテゴリ共通 | Clean Architecture, Testing |
| platforms/ | プラットフォーム固有 | Android, iOS |
| languages/ | プログラミング言語 | Kotlin |
| services/ | クラウドサービス | AWS |
| tools/ | 開発ツール | Claude Code |

## ファイル構成規則

各カテゴリは以下のファイルを持つ:

| ファイル | 目的 |
|----------|------|
| `conventions.md` | 命名規則、コーディング規約 |
| `*-patterns.md` | アーキテクチャパターン |
| `decisions.md` | 技術採用/不採用の決定記録 |

## コンテキストルールとの関係

```markdown
# rules/context-android.md
Read and apply patterns from:
- references/common/clean-architecture.md
- references/platforms/android/conventions.md
- references/platforms/android/architecture-patterns.md
```

## 関連

- 詳細インデックス: [`references/INDEX.md`](dotclaude/references/INDEX.md)
- コンテキストルール: [`rules/context-*.md`](dotclaude/rules/)
- 決定記録ルール: [`rules/reference-decisions.md`](dotclaude/rules/reference-decisions.md)
