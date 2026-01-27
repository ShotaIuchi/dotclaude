# iOS Technology Decisions

## 採用技術

| 技術 | 用途 | 採用理由 | 代替候補 |
|------|------|---------|---------|
| SwiftUI | UI | 宣言的UI、Apple推奨 | UIKit |
| Observation (@Observable) | 状態管理 | iOS 17+、ObservableObject比でボイラープレート削減 | Combine, ObservableObject |
| Swift Concurrency | 非同期処理 | async/await、構造化並行処理 | Combine, GCD |
| SwiftData | 永続化 | SwiftUI統合、CoreData後継 | CoreData, Realm |
| Swift Testing | テスト | モダンAPI、マクロベース | XCTest |

## 不採用とした選択肢

| 技術 | 不採用理由 |
|------|-----------|
| UIKit | SwiftUI移行済み、新規画面はSwiftUI必須 |
| Combine | async/awaitで十分、ReactiveXの複雑さ不要 |
| ObservableObject | @Observable（iOS 17+）に移行 |
| CoreData | SwiftDataに移行 |
| Realm | Apple純正エコシステムを優先 |

## 関連ドキュメント

- [conventions.md](conventions.md) — コーディング規約・命名規則
- [architecture-patterns.md](architecture-patterns.md) — SwiftUI+MVVMパターン
