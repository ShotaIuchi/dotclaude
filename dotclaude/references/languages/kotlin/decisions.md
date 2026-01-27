# Kotlin Multiplatform Technology Decisions

## 採用技術

| 技術 | 用途 | 採用理由 | 代替候補 |
|------|------|---------|---------|
| Kotlin Multiplatform | コード共有 | ビジネスロジック共有、ネイティブUI維持 | Flutter, React Native |
| Compose Multiplatform | 共有UI（一部） | Kotlin統合、段階的導入可能 | SwiftUI/Compose個別 |
| Koin | DI | KMP対応、シンプルなDSL | Kodein, Manual DI |
| SQLDelight | Local DB | KMP対応、型安全SQL | Room (Android only) |
| Ktor | HTTP Client | KMP対応、Coroutine統合 | OkHttp (Android only) |
| Kotlin Coroutines | 非同期処理 | KMPネイティブ対応 | - |
| Turbine | Flow テスト | Flow特化、簡潔なAPI | - |

## 不採用とした選択肢

| 技術 | 不採用理由 |
|------|-----------|
| Flutter | ネイティブUI体験を優先 |
| React Native | Kotlin/Swiftスキルセットを活用 |
| Kodein | Koinのコミュニティ・ドキュメントが優位 |
| Realm (KMP) | SQLDelightの型安全性を優先 |
| Apollo GraphQL | REST APIで十分、GraphQLの要件なし |

## 関連ドキュメント

- [conventions.md](conventions.md) — 命名規則・ディレクトリ構造
- [library-patterns.md](library-patterns.md) — ライブラリ実装パターン
- [feature-patterns.md](feature-patterns.md) — 機能実装パターン
- [kmp-architecture-patterns.md](kmp-architecture-patterns.md) — KMPアーキテクチャ
