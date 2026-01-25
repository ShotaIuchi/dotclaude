# references/

技術リファレンスディレクトリ。

## 概要

スキルから参照される技術ドキュメントを格納。
プラットフォーム、言語、サービス、ツールごとに分類。

## 構造

```
references/
├── INDEX.md            # インデックス（詳細）
├── common/             # 共通リファレンス
│   ├── clean-architecture.md
│   └── testing-strategy.md
├── platforms/          # プラットフォーム固有
│   ├── android/
│   └── ios/
├── languages/          # 言語固有
│   └── kotlin/         # KMP関連多数
├── services/           # クラウドサービス
│   └── aws/
└── tools/              # 開発ツール
    └── claude-code/
```

## グループ分類

| グループ | 説明 | 例 |
|----------|------|-----|
| common/ | 全カテゴリ共通 | Clean Architecture, Testing |
| platforms/ | プラットフォーム固有 | Android, iOS |
| languages/ | プログラミング言語 | Kotlin |
| services/ | クラウドサービス | AWS |
| tools/ | 開発ツール | Claude Code |

## スキルとの関係

```yaml
# skills/android-architecture/SKILL.md
references:
  - path: ../references/platforms/android/index.md
  - path: ../references/common/clean-architecture.md
```

## 関連

- 詳細インデックス: [`references/INDEX.md`](references/INDEX.md)
- スキル定義: [`skills/`](skills/)
