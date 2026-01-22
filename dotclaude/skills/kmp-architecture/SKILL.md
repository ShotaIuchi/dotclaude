---
name: Kotlin Multiplatform Architecture
description: This skill should be used when implementing KMP features, creating shared modules, using expect/actual, setting up Koin/SQLDelight/Ktor, or implementing Compose Multiplatform.
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/common/testing-strategy.md
  - path: ../../references/languages/kotlin/coroutines.md
  - path: ../../references/languages/kotlin/kmp-architecture.md
external:
  - id: kmp-docs
  - id: compose-multiplatform
  - id: kotlin-coroutines
---

# Kotlin Multiplatform Architecture

Multiplatform development patterns based on Kotlin official documentation and Google's KMP recommendations.

## Core Principles

1. **Share Business Logic** - Place Domain/Data Layer in shared module
2. **Minimize Platform-Specific Code** - Abstract with expect/actual
3. **Unidirectional Data Flow (UDF)** - Events flow upstream, state flows downstream
4. **Dependency Direction** - Shared module does not depend on platform

```
Platform UI → Shared (Presentation → Domain → Data)
```

## Module Structure

| Module | Responsibility | Tech Stack |
|--------|----------------|------------|
| shared | All business logic | Koin, Ktor, SQLDelight |
| androidApp | Android UI | Jetpack Compose |
| iosApp | iOS UI | SwiftUI / Compose MP |
| desktopApp | Desktop UI | Compose MP |

## Directory Structure

```
shared/
├── commonMain/kotlin/      # Common to all platforms
│   ├── presentation/
│   ├── domain/
│   └── data/
├── androidMain/kotlin/     # Android-specific (expect/actual)
├── iosMain/kotlin/         # iOS-specific (expect/actual)
└── commonTest/kotlin/      # Common tests
```

## expect/actual Pattern

```kotlin
// commonMain
expect class PlatformContext

// androidMain
actual typealias PlatformContext = android.content.Context

// iosMain
actual class PlatformContext
```

## Detailed References

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [Kotlin Coroutines Guide](../../references/languages/kotlin/coroutines.md)
- [KMP Architecture Details](../../references/languages/kotlin/kmp-architecture.md)
