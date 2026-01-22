---
name: iOS Architecture
description: This skill should be used when implementing iOS features, creating SwiftUI views, setting up ViewModels, using async/await or Combine, or following MVVM patterns on iOS.
references:
  - path: ../../references/common/clean-architecture.md
  - path: ../../references/common/testing-strategy.md
  - path: ../../references/platforms/ios/architecture.md
external:
  - id: swift-concurrency
  - id: swiftui-docs
  - id: combine-docs
---

# iOS Architecture

SwiftUI + MVVM / State management patterns based on Apple's official guidelines.

## Core Principles

1. **Separation of Concerns** - Clearly separate UI logic from business logic
2. **Data-Driven UI** - UI only reflects state
3. **Single Source of Truth (SSOT)** - Repository is the SSOT for data
4. **Unidirectional Data Flow (UDF)** - Events flow upstream, state flows downstream

```
Presentation Layer → Domain Layer → Data Layer
```

## Layer Structure

| Layer | Responsibility | Key Components |
|-------|----------------|----------------|
| Presentation | Display and user interaction | View (SwiftUI), ViewModel |
| Domain | Business logic | UseCase, Domain Model |
| Data | Data retrieval and persistence | Repository, DataSource, API |

## Directory Structure

```
App/
├── Presentation/       # Presentation Layer
│   └── Feature/
│       ├── FeatureView.swift
│       ├── FeatureViewModel.swift
│       └── FeatureUiState.swift
├── Domain/             # Domain Layer
│   ├── Model/
│   └── UseCase/
├── Data/               # Data Layer
│   ├── Repository/
│   ├── Local/
│   └── Remote/
└── DI/                 # DI Container
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
- [iOS Architecture Details](../../references/platforms/ios/architecture.md)
