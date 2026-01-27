# iOS Architecture Patterns

SwiftUI + MVVM / State management patterns based on Apple's official guidelines.

## Core Principles

1. **Separation of Concerns** - Clearly separate UI logic from business logic
2. **Data-Driven UI** - UI only reflects state
3. **Single Source of Truth (SSOT)** - Repository is the SSOT for data
4. **Unidirectional Data Flow (UDF)** - Events flow upstream, state flows downstream

```
User Action -> View -> ViewModel -> UseCase -> Repository -> DataSource
                         |
                   State Update
                         |
              View re-renders with new state
```

**UDF Example:**
```swift
// 1. User taps button in View
Button("Load Users") { viewModel.loadUsers() }

// 2. ViewModel receives event and calls UseCase
func loadUsers() {
    state = .loading
    Task {
        let result = await getUsersUseCase.execute()
        state = result.isSuccess ? .success(result.data) : .error(result.error)
    }
}

// 3. View automatically updates based on state
switch viewModel.state {
case .loading: ProgressView()
case .success(let users): UserListView(users: users)
case .error(let error): ErrorView(error: error)
}
```

## Layer Structure

| Layer | Responsibility | Key Components |
|-------|----------------|----------------|
| Presentation | Display and user interaction | View (SwiftUI), ViewModel |
| Domain | Business logic | UseCase, Domain Model |
| Data | Data retrieval and persistence | Repository, DataSource, API |

### Domain Layer Details

The Domain layer contains pure business logic independent of frameworks:

**UseCase:**
- Encapsulates a single business operation (e.g., `GetUsersUseCase`, `UpdateProfileUseCase`)
- Coordinates between multiple repositories if needed
- Contains validation and business rules
- Returns `Result<T, Error>` or throws for error handling

**Domain Model:**
- Pure Swift structs/classes without framework dependencies
- Represents core business entities (e.g., `User`, `Order`, `Product`)
- Contains computed properties for derived business values
- Immutable by default; use `mutating` methods only when necessary

```swift
// UseCase Example
protocol GetUsersUseCase {
    func execute() async throws -> [User]
}

final class GetUsersUseCaseImpl: GetUsersUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute() async throws -> [User] {
        try await userRepository.getUsers()
    }
}
```

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
