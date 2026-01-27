# Kotlin Multiplatform Technology Decisions

## Adopted Technologies

| Technology | Purpose | Adoption Reason | Alternatives |
|------------|---------|----------------|-------------|
| Kotlin Multiplatform | Code sharing | Share business logic, keep native UI | Flutter, React Native |
| Compose Multiplatform | Shared UI (partial) | Kotlin integration, incremental adoption | SwiftUI/Compose separately |
| Koin | DI | KMP compatible, simple DSL | Kodein, Manual DI |
| SQLDelight | Local DB | KMP compatible, type-safe SQL | Room (Android only) |
| Ktor | HTTP Client | KMP compatible, Coroutine integration | OkHttp (Android only) |
| Kotlin Coroutines | Async processing | KMP native support | - |
| Turbine | Flow testing | Flow-specialized, concise API | - |

## Rejected Options

| Technology | Rejection Reason |
|------------|-----------------|
| Flutter | Prefer native UI experience |
| React Native | Leverage Kotlin/Swift skill set |
| Kodein | Koin has better community and documentation |
| Realm (KMP) | Prefer SQLDelight's type safety |
| Apollo GraphQL | REST API is sufficient; no GraphQL requirement |

## Related Documents

- [conventions.md](conventions.md) — Naming rules and directory structure
- [library-patterns.md](library-patterns.md) — Library implementation patterns
- [feature-patterns.md](feature-patterns.md) — Feature implementation patterns
- [kmp-architecture-patterns.md](kmp-architecture-patterns.md) — KMP architecture
