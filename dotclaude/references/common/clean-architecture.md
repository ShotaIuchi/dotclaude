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
