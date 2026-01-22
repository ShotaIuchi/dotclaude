---
name: Android Architecture
description: This skill should be used when implementing Android features, creating ViewModels, setting up Repositories, using Hilt, implementing Jetpack Compose, or following MVVM/UDF patterns on Android.
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/common/testing-strategy.md
  - path: ../../references/languages/kotlin/coroutines.md
  - path: ../../references/platforms/android/architecture.md
external:
  - id: android-arch-guide
  - id: jetpack-compose-docs
  - id: hilt-docs
---

# Android Architecture

MVVM / UDF / Repository patterns based on Google's official Android Architecture Guide.

## Core Principles

1. **Separation of Concerns** - Clearly separate UI logic from business logic
2. **Data-Driven UI** - UI only reflects state
3. **Single Source of Truth (SSOT)** - Repository is the SSOT for data
4. **Unidirectional Data Flow (UDF)** - Events flow upstream, state flows downstream

```
UI Layer → Domain Layer → Data Layer
```

## Layer Structure

| Layer | Responsibility | Key Components |
|-------|----------------|----------------|
| UI | Display and user interaction | Activity, Fragment, Compose, ViewModel |
| Domain | Business logic | UseCase |
| Data | Data retrieval and persistence | Repository, DataSource, DAO, API |

## Directory Structure

```
app/src/main/java/com/example/app/
├── ui/                 # UI Layer
│   └── feature/
│       ├── FeatureScreen.kt
│       ├── FeatureViewModel.kt
│       └── FeatureUiState.kt
├── domain/             # Domain Layer
│   ├── model/
│   └── usecase/
├── data/               # Data Layer
│   ├── repository/
│   ├── local/
│   └── remote/
└── di/                 # DI modules
```

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository | `{Entity}Repository` | `UserRepository` |

## Detailed References

- [Clean Architecture Guide](../../references/common/clean-architecture.md)
- [Testing Strategy Guide](../../references/common/testing-strategy.md)
- [Kotlin Coroutines Guide](../../references/languages/kotlin/coroutines.md)
- [Android Architecture Details](../../references/platforms/android/architecture.md)
