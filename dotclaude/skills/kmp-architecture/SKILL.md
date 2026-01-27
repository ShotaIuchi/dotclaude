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

**Always respond in Japanese.**

# Kotlin Multiplatform Architecture

Multiplatform development patterns based on Kotlin official documentation and Google's KMP recommendations.

## Core Principles

1. **Share Business Logic** - Place Domain/Data Layer in shared module
2. **Minimize Platform-Specific Code** - Abstract with expect/actual
3. **Single Source of Truth (SSOT)** - Repository in shared module is the SSOT for data
4. **Unidirectional Data Flow (UDF)** - Events flow upstream, state flows downstream
5. **Dependency Direction** - Shared module does not depend on platform

```
Platform UI → Shared (Presentation → Domain → Data)
```

## Layer Structure

| Layer | Responsibility | Key Components |
|-------|----------------|----------------|
| Presentation | UI state and logic (shared) | SharedViewModel, UiState |
| Domain | Business logic | UseCase, Domain Model |
| Data | Data retrieval and persistence | Repository, DataSource, API |

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
actual class PlatformContext(val nsObject: platform.darwin.NSObject? = null)
```

### Platform-Specific Implementation Example

```kotlin
// commonMain
expect fun getPlatformName(): String

// androidMain
actual fun getPlatformName(): String = "Android ${android.os.Build.VERSION.SDK_INT}"

// iosMain
actual fun getPlatformName(): String = platform.UIKit.UIDevice.currentDevice.systemName()
```

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| SharedViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |
| Platform Class | `Platform{Component}` | `PlatformContext`, `PlatformLogger` |
| expect/actual | `{Platform}{Feature}` | `AndroidDatabase`, `IosDatabase` |

## Compose Multiplatform

```kotlin
// commonMain - Shared UI
@Composable
fun UserListScreen(viewModel: UserListViewModel) {
    val state by viewModel.uiState.collectAsState()
    // Shared composable implementation
}
```

- Use `@Composable` functions in commonMain for shared UI
- Platform-specific styling via expect/actual for resources
- Navigation handled per-platform or via shared navigation library

## DI with Koin

```kotlin
// commonMain
val commonModule = module {
    single { UserRepository(get()) }
    factory { GetUsersUseCase(get()) }
}

// androidMain
val androidModule = module {
    single<DatabaseDriver> { AndroidSqliteDriver(Database.Schema, get(), "app.db") }
}

// iosMain
val iosModule = module {
    single<DatabaseDriver> { NativeSqliteDriver(Database.Schema, "app.db") }
}
```

## Testing Strategy

| Test Type | Location | Purpose |
|-----------|----------|---------|
| Unit Tests | commonTest | Shared business logic |
| Platform Tests | androidTest/iosTest | Platform-specific implementations |
| Integration Tests | commonTest | Repository and DataSource interactions |

## Detailed References

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [Kotlin Coroutines Guide](../../references/languages/kotlin/coroutines.md)
- [KMP Architecture Details](../../references/languages/kotlin/kmp-architecture.md)
