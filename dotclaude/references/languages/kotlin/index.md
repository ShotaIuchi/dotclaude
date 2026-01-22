# Kotlin References

## Overview

Reference for Kotlin language and KMP (Kotlin Multiplatform) development based on official Kotlin documentation.
Defines Coroutines, Flow, and multiplatform architecture patterns.

---

## File List and Priority

> **Priority Legend**: ★★★ = Must Read | ★★☆ = Recommended | ★☆☆ = Reference

### Coroutines

| File | Description | Priority |
|------|-------------|----------|
| [coroutines.md](coroutines.md) | Kotlin Coroutines best practices | ★★★ Foundation for async processing |

### KMP Foundation

| File | Description | Priority |
|------|-------------|----------|
| [kmp-architecture.md](kmp-architecture.md) | Kotlin Multiplatform architecture | ★★★ Foundation for KMP design |
| [kmp-expect-actual.md](kmp-expect-actual.md) | expect/actual pattern for platform abstraction | ★★★ Platform-specific implementation |
| [kmp-state-udf.md](kmp-state-udf.md) | Unidirectional Data Flow and MVI pattern | ★★★ State management |
| [kmp-error-handling.md](kmp-error-handling.md) | Common error types and UI error display | ★★☆ Error handling patterns |

### KMP Libraries

| File | Description | Priority |
|------|-------------|----------|
| [kmp-di-koin.md](kmp-di-koin.md) | Dependency injection using Koin | ★★★ DI patterns |
| [kmp-data-sqldelight.md](kmp-data-sqldelight.md) | Local database with SQLDelight | ★★☆ Data persistence |
| [kmp-network-ktor.md](kmp-network-ktor.md) | HTTP client using Ktor | ★★☆ Network layer |

### KMP Features

| File | Description | Priority |
|------|-------------|----------|
| [kmp-compose-ui.md](kmp-compose-ui.md) | Compose Multiplatform UI implementation | ★★★ Cross-platform UI |
| [kmp-auth.md](kmp-auth.md) | KMP authentication best practices | ★★★ Foundation for authentication |
| [kmp-camera.md](kmp-camera.md) | KMP camera implementation guide | ★★☆ Device functionality |
| [kmp-testing.md](kmp-testing.md) | Testing strategy and commonTest patterns | ★★☆ Testing patterns |

---

## External Links

### Official Documentation (Highest Priority)
- [Kotlin Coroutines (Official)](https://kotlinlang.org/docs/coroutines-overview.html) - ★★★ Async processing
- [Kotlin Flow (Official)](https://kotlinlang.org/docs/flow.html) - ★★★ Reactive streams
- [Kotlin Multiplatform (Official)](https://kotlinlang.org/docs/multiplatform.html) - ★★★ KMP basics

### Multiplatform
- [Compose Multiplatform (JetBrains)](https://www.jetbrains.com/lp/compose-multiplatform/) - ★★★ Cross-platform UI

---

## Related References

- [clean-architecture.md](../../common/clean-architecture.md) - Common architecture principles
- [testing-strategy.md](../../common/testing-strategy.md) - Testing strategy

---

## Related Skills

| Skill | Usage | Description |
|-------|-------|-------------|
| android-architecture | `/android-architecture` | Android MVVM patterns (includes Coroutines section) |
| kmp-architecture | `/kmp-architecture` | KMP architecture patterns and best practices |
