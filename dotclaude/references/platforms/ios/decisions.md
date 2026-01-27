# iOS Technology Decisions

## Adopted Technologies

| Technology | Purpose | Adoption Reason | Alternatives |
|------------|---------|----------------|-------------|
| SwiftUI | UI | Declarative UI, Apple recommended | UIKit |
| Observation (@Observable) | State management | iOS 17+, less boilerplate than ObservableObject | Combine, ObservableObject |
| Swift Concurrency | Async processing | async/await, structured concurrency | Combine, GCD |
| SwiftData | Persistence | SwiftUI integration, CoreData successor | CoreData, Realm |
| Swift Testing | Testing | Modern API, macro-based | XCTest |

## Rejected Options

| Technology | Rejection Reason |
|------------|-----------------|
| UIKit | Migrated to SwiftUI; all new screens require SwiftUI |
| Combine | async/await is sufficient; avoids ReactiveX complexity |
| ObservableObject | Migrated to @Observable (iOS 17+) |
| CoreData | Migrated to SwiftData |
| Realm | Prefer Apple-native ecosystem |

## Related Documents

- [conventions.md](conventions.md) — Coding conventions and naming rules
- [architecture-patterns.md](architecture-patterns.md) — SwiftUI+MVVM patterns
