# Android Technology Decisions

## 採用技術

| 技術 | 用途 | 採用理由 | 代替候補 |
|------|------|---------|---------|
| Jetpack Compose | UI | 宣言的UI、Google推奨 | XML Layout |
| Hilt | DI | Dagger比でボイラープレート削減、公式サポート | Koin, Manual DI |
| Room | Local DB | 型安全なクエリ、Flow対応 | SQLDelight, DataStore |
| DataStore | Key-Value保存 | SharedPreferences後継、Coroutine対応 | SharedPreferences |
| Navigation Compose | 画面遷移 | Type-safe args、Compose統合 | Fragment Navigation |
| Kotlin Coroutines | 非同期処理 | 構造化された並行処理 | RxJava |
| Coil | 画像読込 | Compose/Coroutine親和性 | Glide, Picasso |

## 不採用とした選択肢

| 技術 | 不採用理由 |
|------|-----------|
| XML Layout | Compose移行済み、新規画面はCompose必須 |
| Koin (Android単体) | Hiltのコンパイル時検証を優先 |
| RxJava | Coroutinesで十分、学習コスト削減 |
| WorkManager | 現時点でバックグラウンド処理の要件なし |
| Paging3 | データ量が限定的で不要 |

## 関連ドキュメント

- [conventions.md](conventions.md) — コーディング規約・命名規則
- [architecture-patterns.md](architecture-patterns.md) — MVVM/UDF実装パターン
