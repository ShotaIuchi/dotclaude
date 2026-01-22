# Clean Architecture Guide

Cross-platform architecture principles and patterns.

---

## Core Principles

### 1. Separation of Concerns

Each layer has a single responsibility and does not know implementation details of other layers.

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │  ← UI / User Interaction
├─────────────────────────────────────────┤
│             Domain Layer                 │  ← Business Logic
├─────────────────────────────────────────┤
│              Data Layer                  │  ← Data Retrieval / Persistence
└─────────────────────────────────────────┘
```

### 2. Dependency Direction

Outer layers depend on inner layers. The reverse is not permitted.

```
Presentation → Domain ← Data
              (Dependency Inversion)
```

### 3. Single Source of Truth (SSOT)

Normalized data state is managed in one place (typically the Repository).

### 4. Unidirectional Data Flow (UDF)

Events flow upstream, state flows downstream.

```
UI ──(Event)──→ ViewModel ──(State)──→ UI
         │
         ▼
      UseCase
         │
         ▼
    Repository
```

---

## Layer Details

### Presentation Layer

**Responsibility**: Display user interface and handle user interactions

| Component | Role |
|-----------|------|
| View | Render UI (only reflects state) |
| ViewModel | Hold UI state / UI logic |
| UI State | Data class representing UI state |

**Principles**:
- View has no logic (only renders state)
- ViewModel does not depend on platform-specific APIs (as much as possible)
- UI State is an immutable data class

### Domain Layer

**Responsibility**: Implement business logic

| Component | Role |
|-----------|------|
| UseCase | Single business operation |
| Domain Model | Business entities |
| Repository Interface | Abstraction for data retrieval |

**Principles**:
- UseCase executes a single operation
- Domain Model does not depend on frameworks
- Repository is defined as an interface

### Data Layer

**Responsibility**: Data retrieval and persistence

| Component | Role |
|-----------|------|
| Repository Impl | Implementation of Repository interface |
| DataSource | Access to data sources |
| DTO/Entity | Data Transfer Objects |

**Principles**:
- Repository coordinates multiple DataSources
- DataSource is separated into local/remote
- DTO maps to Domain Model

---

## UI State Pattern

### Basic Structure

```kotlin
// Kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}
```

```swift
// Swift
enum UiState<T> {
    case loading
    case success(T)
    case error(String)
}
```

### Composite State

```kotlin
// Kotlin
data class ScreenUiState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val isRefreshing: Boolean = false
)
```

```swift
// Swift
struct ScreenUiState {
    var items: [Item] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isRefreshing: Bool = false
}
```

### State Management Integration

**Android (Kotlin):**

```kotlin
// Using StateFlow in ViewModel
class UserListViewModel(
    private val getUsersUseCase: GetUsersUseCase
) : ViewModel() {
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    fun loadUsers() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            getUsersUseCase().fold(
                onSuccess = { users ->
                    _uiState.update { it.copy(items = users, isLoading = false) }
                },
                onFailure = { error ->
                    _uiState.update { it.copy(errorMessage = error.message, isLoading = false) }
                }
            )
        }
    }
}
```

**iOS (Swift):**

```swift
// Using Combine / @Published in ViewModel
@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var uiState = UserListUiState()
    private let getUsersUseCase: GetUsersUseCase

    init(getUsersUseCase: GetUsersUseCase) {
        self.getUsersUseCase = getUsersUseCase
    }

    func loadUsers() {
        Task {
            uiState.isLoading = true
            do {
                let users = try await getUsersUseCase.execute()
                uiState = UserListUiState(items: users, isLoading: false)
            } catch {
                uiState = UserListUiState(errorMessage: error.localizedDescription, isLoading: false)
            }
        }
    }
}
```

---

## UseCase Pattern

### Single Operation UseCase

```kotlin
// Kotlin
class GetUserUseCase(
    private val userRepository: UserRepository
) {
    suspend operator fun invoke(userId: String): Result<User> {
        return userRepository.getUser(userId)
    }
}
```

```swift
// Swift
final class GetUserUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute(userId: String) async throws -> User {
        return try await userRepository.getUser(userId)
    }
}
```

### Composite Operation UseCase

```kotlin
// Kotlin
class RefreshDataUseCase(
    private val userRepository: UserRepository,
    private val cacheRepository: CacheRepository
) {
    suspend operator fun invoke(): Result<Unit> {
        return runCatching {
            cacheRepository.clear()
            userRepository.refresh()
        }
    }
}
```

```swift
// Swift
final class RefreshDataUseCase {
    private let userRepository: UserRepository
    private let cacheRepository: CacheRepository

    init(userRepository: UserRepository, cacheRepository: CacheRepository) {
        self.userRepository = userRepository
        self.cacheRepository = cacheRepository
    }

    func execute() async throws {
        try await cacheRepository.clear()
        try await userRepository.refresh()
    }
}
```

---

## Repository Pattern

### Interface Definition (Domain Layer)

```kotlin
// Kotlin
interface UserRepository {
    suspend fun getUser(id: String): Result<User>
    suspend fun getUsers(): Flow<List<User>>
    suspend fun saveUser(user: User): Result<Unit>
}
```

```swift
// Swift
protocol UserRepository {
    func getUser(id: String) async throws -> User
    func getUsers() -> AsyncStream<[User]>
    func saveUser(_ user: User) async throws
}
```

### Implementation (Data Layer)

```kotlin
// Kotlin
class UserRepositoryImpl(
    private val remoteDataSource: UserRemoteDataSource,
    private val localDataSource: UserLocalDataSource
) : UserRepository {

    override suspend fun getUser(id: String): Result<User> {
        return runCatching {
            // Check local cache first
            localDataSource.getUser(id)
                ?: remoteDataSource.getUser(id).also { user ->
                    localDataSource.saveUser(user)
                }
        }
    }

    override fun getUsers(): Flow<List<User>> {
        return localDataSource.observeUsers()
            .onStart {
                // Refresh in background
                refreshUsersFromRemote()
            }
    }
}
```

```swift
// Swift
final class UserRepositoryImpl: UserRepository {
    private let remoteDataSource: UserRemoteDataSource
    private let localDataSource: UserLocalDataSource

    init(remoteDataSource: UserRemoteDataSource, localDataSource: UserLocalDataSource) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }

    func getUser(id: String) async throws -> User {
        // Check local cache first
        if let cachedUser = try await localDataSource.getUser(id: id) {
            return cachedUser
        }
        let user = try await remoteDataSource.getUser(id: id)
        try await localDataSource.saveUser(user)
        return user
    }

    func getUsers() -> AsyncStream<[User]> {
        AsyncStream { continuation in
            Task {
                // Refresh in background
                try? await refreshUsersFromRemote()
                for await users in localDataSource.observeUsers() {
                    continuation.yield(users)
                }
                continuation.finish()
            }
        }
    }
}
```

---

## Error Handling

### Result Type Pattern

```kotlin
// Kotlin
sealed class AppResult<out T> {
    data class Success<T>(val data: T) : AppResult<T>()
    data class Error(val exception: AppException) : AppResult<Nothing>()
}

sealed class AppException : Exception() {
    data class Network(override val message: String) : AppException()
    data class NotFound(val id: String) : AppException()
    data class Unauthorized : AppException()
    data class Unknown(override val cause: Throwable?) : AppException()
}
```

```swift
// Swift
enum AppError: Error {
    case network(String)
    case notFound(id: String)
    case unauthorized
    case unknown(Error?)
}
```

### Error Mapping

```kotlin
// Kotlin - Map errors in Repository
override suspend fun getUser(id: String): AppResult<User> {
    return try {
        val user = remoteDataSource.getUser(id)
        AppResult.Success(user)
    } catch (e: HttpException) {
        when (e.code) {
            404 -> AppResult.Error(AppException.NotFound(id))
            401 -> AppResult.Error(AppException.Unauthorized)
            else -> AppResult.Error(AppException.Network(e.message ?: "Unknown error"))
        }
    } catch (e: Exception) {
        AppResult.Error(AppException.Unknown(e))
    }
}
```

```swift
// Swift - Map errors in Repository
func getUser(id: String) async -> Result<User, AppError> {
    do {
        let user = try await remoteDataSource.getUser(id: id)
        return .success(user)
    } catch let error as URLError {
        return .failure(.network(error.localizedDescription))
    } catch let error as HTTPError {
        switch error.statusCode {
        case 404:
            return .failure(.notFound(id: id))
        case 401:
            return .failure(.unauthorized)
        default:
            return .failure(.network(error.localizedDescription))
        }
    } catch {
        return .failure(.unknown(error))
    }
}
```

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| UI State | `{Feature}UiState` | `UserListUiState` |
| UseCase | `{Action}{Entity}UseCase` | `GetUsersUseCase` |
| Repository Interface | `{Entity}Repository` | `UserRepository` |
| Repository Impl | `{Entity}RepositoryImpl` | `UserRepositoryImpl` |
| Remote DataSource | `{Entity}RemoteDataSource` | `UserRemoteDataSource` |
| Local DataSource | `{Entity}LocalDataSource` | `UserLocalDataSource` |
| DTO | `{Entity}Dto` / `{Entity}Response` | `UserDto`, `UserResponse` |
| Domain Model | `{Entity}` | `User` |

---

## Best Practices

### DO (Recommended)

- ViewModel exposes UI State, View observes state
- UseCase focuses on a single operation
- Repository abstracts data sources
- Errors are properly typed and handled
- Testable design (dependency injection)

### DON'T (Not Recommended)

- Execute business logic in View
- Call API directly from ViewModel
- Use framework-specific types in Domain Layer
- Swallow errors
- God class (too many responsibilities in one class)

---

## Dependency Injection

Dependency Injection (DI) enables testable, maintainable code by decoupling components from their dependencies.

### Android (Kotlin)

**Hilt** (recommended for Android):

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {
    @Provides
    @Singleton
    fun provideUserRepository(
        remoteDataSource: UserRemoteDataSource,
        localDataSource: UserLocalDataSource
    ): UserRepository = UserRepositoryImpl(remoteDataSource, localDataSource)
}

@HiltViewModel
class UserListViewModel @Inject constructor(
    private val getUsersUseCase: GetUsersUseCase
) : ViewModel()
```

**Koin** (lightweight alternative):

```kotlin
val appModule = module {
    single<UserRepository> { UserRepositoryImpl(get(), get()) }
    factory { GetUsersUseCase(get()) }
    viewModel { UserListViewModel(get()) }
}
```

### iOS (Swift)

**Manual DI (recommended for small projects):**

```swift
// Composition Root
final class AppDependencies {
    lazy var userRepository: UserRepository = UserRepositoryImpl(
        remoteDataSource: UserRemoteDataSource(),
        localDataSource: UserLocalDataSource()
    )

    func makeUserListViewModel() -> UserListViewModel {
        UserListViewModel(getUsersUseCase: GetUsersUseCase(userRepository: userRepository))
    }
}
```

**Swinject (for larger projects):**

```swift
let container = Container()
container.register(UserRepository.self) { _ in
    UserRepositoryImpl(
        remoteDataSource: UserRemoteDataSource(),
        localDataSource: UserLocalDataSource()
    )
}.inObjectScope(.container)

container.register(UserListViewModel.self) { r in
    UserListViewModel(getUsersUseCase: GetUsersUseCase(userRepository: r.resolve(UserRepository.self)!))
}
```

---

## Testing Strategy

### Layer-Specific Testing

| Layer | Test Type | Focus | Tools |
|-------|-----------|-------|-------|
| Presentation | Unit / UI Test | ViewModel state changes, UI behavior | JUnit, Espresso (Android) / XCTest (iOS) |
| Domain | Unit Test | UseCase business logic | JUnit / XCTest |
| Data | Unit / Integration Test | Repository, DataSource behavior | JUnit, MockK (Android) / XCTest (iOS) |

### Testing with Fakes and Mocks

**Kotlin (Android):**

```kotlin
// Fake Repository for testing
class FakeUserRepository : UserRepository {
    private val users = mutableListOf<User>()

    override suspend fun getUser(id: String): Result<User> {
        return users.find { it.id == id }
            ?.let { Result.success(it) }
            ?: Result.failure(Exception("User not found"))
    }

    fun addUser(user: User) { users.add(user) }
}

// ViewModel test
@Test
fun `loadUsers updates state with users`() = runTest {
    val fakeRepository = FakeUserRepository().apply {
        addUser(User("1", "John"))
    }
    val viewModel = UserListViewModel(GetUsersUseCase(fakeRepository))

    viewModel.loadUsers()

    assertEquals(1, viewModel.uiState.value.items.size)
}
```

**Swift (iOS):**

```swift
// Fake Repository for testing
final class FakeUserRepository: UserRepository {
    private var users: [User] = []

    func getUser(id: String) async throws -> User {
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.notFound(id: id)
        }
        return user
    }

    func addUser(_ user: User) { users.append(user) }
}

// ViewModel test
@Test
func loadUsers_updatesStateWithUsers() async {
    let fakeRepository = FakeUserRepository()
    fakeRepository.addUser(User(id: "1", name: "John"))
    let viewModel = await UserListViewModel(getUsersUseCase: GetUsersUseCase(userRepository: fakeRepository))

    await viewModel.loadUsers()

    #expect(viewModel.uiState.items.count == 1)
}
```

### Testing Best Practices

- **Prefer Fakes over Mocks**: Fakes provide more realistic behavior and are easier to maintain
- **Test behavior, not implementation**: Focus on inputs and outputs, not internal details
- **Use test fixtures**: Create reusable test data factories
- **Isolate each layer**: Test each layer independently with fakes for dependencies
