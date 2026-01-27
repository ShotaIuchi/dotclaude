# Android Technology Decisions

## Adopted Technologies

| Technology | Purpose | Adoption Reason | Alternatives |
|------------|---------|----------------|-------------|
| Jetpack Compose | UI | Declarative UI, Google recommended | XML Layout |
| Hilt | DI | Less boilerplate than Dagger, official support | Koin, Manual DI |
| Room | Local DB | Type-safe queries, Flow support | SQLDelight, DataStore |
| DataStore | Key-Value storage | SharedPreferences successor, Coroutine support | SharedPreferences |
| Navigation Compose | Navigation | Type-safe args, Compose integration | Fragment Navigation |
| Kotlin Coroutines | Async processing | Structured concurrency | RxJava |
| Coil | Image loading | Compose/Coroutine affinity | Glide, Picasso |

## Rejected Options

| Technology | Rejection Reason |
|------------|-----------------|
| XML Layout | Migrated to Compose; all new screens require Compose |
| Koin (Android standalone) | Prefer Hilt's compile-time verification |
| RxJava | Coroutines are sufficient; reduces learning cost |
| WorkManager | No background processing requirement at this time |
| Paging3 | Limited data volume makes it unnecessary |

## Related Documents

- [conventions.md](conventions.md) — Coding conventions and naming rules
- [architecture-patterns.md](architecture-patterns.md) — MVVM/UDF implementation patterns
