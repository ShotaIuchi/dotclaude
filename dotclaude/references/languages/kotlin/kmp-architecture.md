# Kotlin Multiplatform Architecture Guide

A collection of best practices for multiplatform development based on Kotlin official documentation and Google's KMP recommendations.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Shared Module](#shared-module-shared)
4. [Directory Structure](#directory-structure)
5. [Naming Conventions](#naming-conventions)
6. [Best Practices Checklist](#best-practices-checklist)

### Detailed Documentation

| Document | Content |
|----------|---------|
| [kmp-expect-actual.md](./kmp-expect-actual.md) | expect/actual pattern |
| [kmp-di-koin.md](./kmp-di-koin.md) | Dependency Injection (Koin) |
| [kmp-data-sqldelight.md](./kmp-data-sqldelight.md) | Data Persistence (SQLDelight) |
| [kmp-network-ktor.md](./kmp-network-ktor.md) | Networking (Ktor) |
| [kmp-state-udf.md](./kmp-state-udf.md) | State Management and UDF |
| [kmp-compose-ui.md](./kmp-compose-ui.md) | Compose Multiplatform |
| [kmp-error-handling.md](./kmp-error-handling.md) | Error Handling |
| [kmp-testing.md](./kmp-testing.md) | Testing Strategy |

---

## Architecture Overview

### Basic Principles

1. **Share Business Logic**
   - Place Domain Layer and Data Layer in shared module
   - Share UI logic (ViewModel) as much as possible

2. **Minimize Platform-Specific Code**
   - Abstract with expect/actual to limit platform dependencies
   - UI can be native per platform or Compose Multiplatform

3. **Unidirectional Data Flow (UDF)**
   - Events flow upstream (UI → ViewModel → Repository)
   - State flows downstream (Repository → ViewModel → UI)

4. **Dependency Direction**
   - shared module does not depend on platform modules
   - Platform modules depend on shared

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Platform UI Layer                                │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │   Android (Compose)  │        │   iOS (SwiftUI)      │          │
│  │   / Compose MP       │        │   / Compose MP       │          │
│  └──────────────────────┘        └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Shared Module                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                        │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   ViewModel (commonMain)                             │    │   │
│  │  │   - UI State Management                              │    │   │
│  │  │   - UseCase Invocation                               │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Domain Layer                             │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   UseCase / Model (commonMain)                       │    │   │
│  │  │   - Business Logic                                   │    │   │
│  │  │   - Domain Models                                    │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   Repository (commonMain)                            │    │   │
│  │  │   - Data Access Abstraction                          │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │           │                              │                   │   │
│  │           ▼                              ▼                   │   │
│  │  ┌─────────────────┐          ┌─────────────────┐           │   │
│  │  │ Local DataSource│          │Remote DataSource│           │   │
│  │  │  (SQLDelight)   │          │    (Ktor)       │           │   │
│  │  └─────────────────┘          └─────────────────┘           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

### Source Set Hierarchy

```
shared/
├── commonMain/              # Common to all platforms
│   └── kotlin/
│
├── commonTest/              # Common tests
│   └── kotlin/
│
├── androidMain/             # Android specific
│   └── kotlin/
│
├── androidUnitTest/         # Android tests
│   └── kotlin/
│
├── iosMain/                 # iOS common (ARM64 + X64)
│   └── kotlin/
│
├── iosArm64Main/            # iOS ARM64 (device)
├── iosX64Main/              # iOS X64 (simulator)
├── iosSimulatorArm64Main/   # iOS Simulator ARM64 (M1/M2 Mac)
│
└── desktopMain/             # Desktop (JVM) specific
    └── kotlin/
```

### build.gradle.kts Configuration

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.sqldelight)
    alias(libs.plugins.kotlinSerialization)
}

kotlin {
    // Android target
    androidTarget {
        compilations.all {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }

    // iOS targets
    listOf(
        iosX64(),
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "Shared"
            isStatic = true
        }
    }

    // Desktop target (optional)
    jvm("desktop")

    sourceSets {
        commonMain.dependencies {
            // Coroutines
            implementation(libs.kotlinx.coroutines.core)

            // Ktor (HTTP client)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)

            // SQLDelight
            implementation(libs.sqldelight.runtime)
            implementation(libs.sqldelight.coroutines.extensions)

            // Koin (DI)
            implementation(libs.koin.core)

            // DateTime
            implementation(libs.kotlinx.datetime)
        }

        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.kotlinx.coroutines.test)
        }

        androidMain.dependencies {
            // Android-specific Ktor engine
            implementation(libs.ktor.client.okhttp)

            // SQLDelight Android driver
            implementation(libs.sqldelight.android.driver)

            // Koin Android
            implementation(libs.koin.android)
        }

        iosMain.dependencies {
            // iOS-specific Ktor engine
            implementation(libs.ktor.client.darwin)

            // SQLDelight iOS driver
            implementation(libs.sqldelight.native.driver)
        }

        val desktopMain by getting {
            dependencies {
                implementation(libs.ktor.client.cio)
                implementation(libs.sqldelight.sqlite.driver)
            }
        }
    }
}
```

### Dependency Version Management

> **Note**: Refer to official sites for the latest stable version of each library:
> - [Kotlin Releases](https://kotlinlang.org/docs/releases.html)
> - [Ktor Releases](https://ktor.io/changelog/)
> - [SQLDelight Releases](https://github.com/cashapp/sqldelight/releases)
> - [Koin Releases](https://github.com/InsertKoinIO/koin/releases)
> - [kotlinx.coroutines Releases](https://github.com/Kotlin/kotlinx.coroutines/releases)
> - [kotlinx.datetime Releases](https://github.com/Kotlin/kotlinx-datetime/releases)
> - [kotlinx.serialization Releases](https://github.com/Kotlin/kotlinx.serialization/releases)

Basic structure of `libs.versions.toml`:

```toml
[versions]
kotlin = "..."               # Refer to latest stable
kotlinx-coroutines = "..."
kotlinx-datetime = "..."
kotlinx-serialization = "..."
ktor = "..."
sqldelight = "..."
koin = "..."

[libraries]
# Coroutines
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "kotlinx-coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "kotlinx-coroutines" }

# Ktor
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
ktor-client-okhttp = { module = "io.ktor:ktor-client-okhttp", version.ref = "ktor" }
ktor-client-darwin = { module = "io.ktor:ktor-client-darwin", version.ref = "ktor" }
ktor-client-cio = { module = "io.ktor:ktor-client-cio", version.ref = "ktor" }
ktor-client-content-negotiation = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }

# SQLDelight
sqldelight-runtime = { module = "app.cash.sqldelight:runtime", version.ref = "sqldelight" }
sqldelight-coroutines-extensions = { module = "app.cash.sqldelight:coroutines-extensions", version.ref = "sqldelight" }
sqldelight-android-driver = { module = "app.cash.sqldelight:android-driver", version.ref = "sqldelight" }
sqldelight-native-driver = { module = "app.cash.sqldelight:native-driver", version.ref = "sqldelight" }
sqldelight-sqlite-driver = { module = "app.cash.sqldelight:sqlite-driver", version.ref = "sqldelight" }

# Koin
koin-core = { module = "io.insert-koin:koin-core", version.ref = "koin" }
koin-android = { module = "io.insert-koin:koin-android", version.ref = "koin" }

# DateTime
kotlinx-datetime = { module = "org.jetbrains.kotlinx:kotlinx-datetime", version.ref = "kotlinx-datetime" }

[plugins]
kotlinMultiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
kotlinSerialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
sqldelight = { id = "app.cash.sqldelight", version.ref = "sqldelight" }
```

---

## Shared Module (shared)

### Domain Layer

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/User.kt

/**
 * Domain model (contains business logic)
 */
data class User(
    val id: String,
    val name: String,
    val email: String,
    val joinedAt: Instant,
    val status: UserStatus
) {
    // Domain logic
    val isActive: Boolean
        get() = status == UserStatus.ACTIVE

    fun canPost(): Boolean {
        return isActive && !isBanned()
    }

    private fun isBanned(): Boolean {
        return status == UserStatus.BANNED
    }
}

enum class UserStatus {
    ACTIVE, INACTIVE, BANNED
}
```

```kotlin
// commonMain/kotlin/com/example/shared/domain/repository/UserRepository.kt

/**
 * User repository interface
 *
 * Domain layer depends on this interface
 */
interface UserRepository {
    fun getUsers(): Flow<List<User>>
    fun getUser(userId: String): Flow<User>
    suspend fun createUser(user: User): Result<User>
    suspend fun updateUser(user: User): Result<Unit>
    suspend fun deleteUser(userId: String): Result<Unit>
}
```

```kotlin
// commonMain/kotlin/com/example/shared/domain/usecase/GetUsersUseCase.kt

/**
 * UseCase for getting user list
 *
 * Encapsulates a single business logic
 */
class GetUsersUseCase(
    private val userRepository: UserRepository,
    private val analyticsRepository: AnalyticsRepository
) {
    /**
     * Get user list
     *
     * @return Flow of user list
     */
    operator fun invoke(): Flow<List<User>> {
        return userRepository.getUsers()
            .onEach { users ->
                // Side effects (analytics, etc.)
                analyticsRepository.logUserListViewed(users.size)
            }
    }
}
```

### Data Layer

```kotlin
// commonMain/kotlin/com/example/shared/data/repository/UserRepositoryImpl.kt

/**
 * User repository implementation
 *
 * Adopts offline-first strategy
 */
class UserRepositoryImpl(
    private val localDataSource: UserLocalDataSource,
    private val remoteDataSource: UserRemoteDataSource,
    private val networkMonitor: NetworkMonitor
) : UserRepository {

    /**
     * Get user list
     *
     * Offline-first:
     * 1. Return local cache first
     * 2. Fetch from remote in background
     * 3. Update local with fetched data
     */
    override fun getUsers(): Flow<List<User>> {
        return localDataSource.getUsers()
            .onStart {
                // Sync from remote in background
                refreshUsersFromRemote()
            }
            .map { entities ->
                entities.map { it.toDomain() }
            }
    }

    override fun getUser(userId: String): Flow<User> {
        return localDataSource.getUser(userId)
            .onStart {
                refreshUserFromRemote(userId)
            }
            .map { it.toDomain() }
    }

    override suspend fun createUser(user: User): Result<User> {
        return runCatching {
            // Create on remote
            val response = remoteDataSource.createUser(user.toRequest())
            val createdUser = response.toDomain()

            // Cache locally
            localDataSource.insertUser(createdUser.toEntity())

            createdUser
        }
    }

    override suspend fun updateUser(user: User): Result<Unit> {
        return runCatching {
            remoteDataSource.updateUser(user.id, user.toRequest())
            localDataSource.insertUser(user.toEntity())
        }
    }

    override suspend fun deleteUser(userId: String): Result<Unit> {
        return runCatching {
            remoteDataSource.deleteUser(userId)
            localDataSource.deleteUser(userId)
        }
    }

    /**
     * Sync user list from remote
     */
    private suspend fun refreshUsersFromRemote() {
        if (!networkMonitor.isOnline()) return

        runCatching {
            val remoteUsers = remoteDataSource.getUsers()
            localDataSource.replaceAllUsers(
                remoteUsers.map { it.toEntity() }
            )
        }.onFailure { e ->
            // Log only, show local data to UI
            println("Failed to refresh users from remote: $e")
        }
    }

    private suspend fun refreshUserFromRemote(userId: String) {
        if (!networkMonitor.isOnline()) return

        runCatching {
            val remoteUser = remoteDataSource.getUser(userId)
            localDataSource.insertUser(remoteUser.toEntity())
        }.onFailure { e ->
            println("Failed to refresh user from remote: $userId, error: $e")
        }
    }
}
```

### Presentation Layer (ViewModel)

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListViewModel.kt

/**
 * User list screen ViewModel
 *
 * Manages UI state and invokes business logic
 */
class UserListViewModel(
    private val getUsersUseCase: GetUsersUseCase,
    private val coroutineScope: CoroutineScope
) {
    // UI State (single state object)
    private val _uiState = MutableStateFlow(UserListUiState())
    val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

    // For temporary events (Snackbar, navigation, etc.)
    private val _events = Channel<UserListEvent>(Channel.BUFFERED)
    val events: Flow<UserListEvent> = _events.receiveAsFlow()

    private var loadJob: Job? = null

    init {
        loadUsers()
    }

    /**
     * Load user list
     */
    fun loadUsers() {
        loadJob?.cancel()
        loadJob = coroutineScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            getUsersUseCase()
                .catch { e ->
                    _uiState.update {
                        it.copy(isLoading = false, error = e.toUiError())
                    }
                }
                .collect { users ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            users = users.map { user -> user.toUiModel() },
                            error = null
                        )
                    }
                }
        }
    }

    /**
     * Select a user
     */
    fun onUserClick(userId: String) {
        coroutineScope.launch {
            _events.send(UserListEvent.NavigateToDetail(userId))
        }
    }

    /**
     * Retry
     */
    fun onRetryClick() {
        loadUsers()
    }

    /**
     * Dispose ViewModel
     */
    fun onCleared() {
        loadJob?.cancel()
    }
}
```

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListUiState.kt

/**
 * UI state for user list screen
 *
 * Represents state with immutable data class
 */
data class UserListUiState(
    val users: List<UserUiModel> = emptyList(),
    val isLoading: Boolean = false,
    val error: UiError? = null
) {
    // Derived properties
    val isEmpty: Boolean
        get() = users.isEmpty() && !isLoading && error == null

    val showEmptyState: Boolean
        get() = isEmpty

    val showContent: Boolean
        get() = users.isNotEmpty()
}

/**
 * User model for UI layer
 */
data class UserUiModel(
    val id: String,
    val displayName: String,
    val avatarUrl: String?,
    val formattedJoinDate: String
)

/**
 * Temporary UI events
 */
sealed interface UserListEvent {
    data class NavigateToDetail(val userId: String) : UserListEvent
    data class ShowSnackbar(val message: String) : UserListEvent
}
```

---

## Directory Structure

### Recommended Structure

```
project/
├── shared/                              # Shared module
│   ├── build.gradle.kts
│   │
│   └── src/
│       ├── commonMain/
│       │   └── kotlin/com/example/shared/
│       │       │
│       │       ├── core/                # Common components
│       │       │   ├── di/              # DI modules
│       │       │   │   ├── SharedModule.kt
│       │       │   │   └── ViewModelFactory.kt
│       │       │   │
│       │       │   ├── error/           # Error definitions
│       │       │   │   └── AppException.kt
│       │       │   │
│       │       │   ├── network/         # Network
│       │       │   │   └── NetworkMonitor.kt
│       │       │   │
│       │       │   ├── platform/        # Platform abstraction
│       │       │   │   └── Platform.kt
│       │       │   │
│       │       │   └── util/            # Utilities
│       │       │       ├── Uuid.kt
│       │       │       └── DateFormatter.kt
│       │       │
│       │       ├── data/                # Data Layer
│       │       │   ├── local/
│       │       │   │   ├── UserLocalDataSource.kt
│       │       │   │   └── model/
│       │       │   │       └── UserEntityData.kt
│       │       │   │
│       │       │   ├── remote/
│       │       │   │   ├── UserRemoteDataSource.kt
│       │       │   │   └── model/
│       │       │   │       ├── UserResponse.kt
│       │       │   │       └── UserRequest.kt
│       │       │   │
│       │       │   ├── repository/
│       │       │   │   └── UserRepositoryImpl.kt
│       │       │   │
│       │       │   └── mapper/
│       │       │       └── UserMapper.kt
│       │       │
│       │       ├── domain/              # Domain Layer
│       │       │   ├── model/
│       │       │   │   └── User.kt
│       │       │   │
│       │       │   ├── repository/
│       │       │   │   └── UserRepository.kt
│       │       │   │
│       │       │   └── usecase/
│       │       │       ├── GetUsersUseCase.kt
│       │       │       └── GetUserDetailUseCase.kt
│       │       │
│       │       ├── presentation/        # Presentation Layer
│       │       │   ├── model/
│       │       │   │   └── UiError.kt
│       │       │   │
│       │       │   ├── userlist/
│       │       │   │   ├── UserListViewModel.kt
│       │       │   │   └── UserListUiState.kt
│       │       │   │
│       │       │   └── userdetail/
│       │       │       ├── UserDetailViewModel.kt
│       │       │       └── UserDetailUiState.kt
│       │       │
│       │       └── ui/                  # Compose Multiplatform UI
│       │           ├── component/
│       │           │   ├── ErrorContent.kt
│       │           │   ├── EmptyContent.kt
│       │           │   └── LoadingContent.kt
│       │           │
│       │           ├── userlist/
│       │           │   └── UserListScreen.kt
│       │           │
│       │           └── theme/
│       │               └── AppTheme.kt
│       │
│       ├── commonTest/
│       │   └── kotlin/com/example/shared/
│       │       ├── domain/
│       │       │   └── usecase/
│       │       │       └── GetUsersUseCaseTest.kt
│       │       │
│       │       ├── presentation/
│       │       │   └── UserListViewModelTest.kt
│       │       │
│       │       └── test/                # Test utilities
│       │           ├── FakeUserRepository.kt
│       │           ├── FakeGetUsersUseCase.kt
│       │           └── TestUtils.kt
│       │
│       ├── androidMain/
│       │   └── kotlin/com/example/shared/
│       │       ├── core/
│       │       │   ├── di/
│       │       │   │   └── PlatformModule.android.kt
│       │       │   ├── network/
│       │       │   │   └── NetworkMonitor.android.kt
│       │       │   └── platform/
│       │       │       └── Platform.android.kt
│       │       │
│       │       └── util/
│       │           └── Uuid.android.kt
│       │
│       └── iosMain/
│           └── kotlin/com/example/shared/
│               ├── core/
│               │   ├── di/
│               │   │   └── PlatformModule.ios.kt
│               │   ├── network/
│               │   │   └── NetworkMonitor.ios.kt
│               │   └── platform/
│               │       └── Platform.ios.kt
│               │
│               └── util/
│                   └── Uuid.ios.kt
│
├── androidApp/                          # Android app
│   ├── build.gradle.kts
│   └── src/main/
│       ├── kotlin/com/example/android/
│       │   ├── MyApplication.kt
│       │   ├── MainActivity.kt
│       │   └── ui/
│       │       └── navigation/
│       │           └── AppNavigation.kt
│       │
│       └── res/
│
├── iosApp/                              # iOS app
│   ├── iosApp.xcodeproj
│   └── Sources/
│       ├── iOSApp.swift
│       ├── ContentView.swift
│       └── View/
│           ├── UserListView.swift
│           └── UserDetailView.swift
│
├── desktopApp/                          # Desktop app (optional)
│   └── src/jvmMain/
│
└── sqldelight/                          # SQLDelight schema
    └── com/example/shared/
        └── AppDatabase.sq
```

---

## Naming Conventions

### Class Naming

| Type | Suffix | Example |
|------|--------|---------|
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Interface | Repository | `UserRepository` |
| Repository Implementation | RepositoryImpl | `UserRepositoryImpl` |
| DataSource Interface | DataSource | `UserLocalDataSource` |
| DataSource Implementation | DataSourceImpl | `UserLocalDataSourceImpl` |
| SQLDelight Entity | Entity | `UserEntity` |
| API Response | Response | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Event | Event | `UserListEvent` |
| Composable Screen | Screen | `UserListScreen` |
| expect Implementation | .{platform} | `Platform.android.kt`, `Platform.ios.kt` |

### Function Naming

| Type | Pattern | Example |
|------|---------|---------|
| Fetch single data | `get{Entity}` | `getUser(userId)` |
| Fetch multiple data | `get{Entity}s` / `get{Entity}List` | `getUsers()` |
| Create data | `create{Entity}` / `insert{Entity}` | `createUser()` |
| Update data | `update{Entity}` | `updateUser()` |
| Delete data | `delete{Entity}` | `deleteUser()` |
| Event handler | `on{Event}` / `on{Event}Click` | `onUserClick()` |
| Conversion | `to{Target}` | `toDomain()`, `toEntity()`, `toUiModel()` |
| Validation | `is{Condition}` / `has{Property}` | `isValid()`, `hasPermission()` |

### Source Set Naming

| Source Set | Purpose |
|------------|---------|
| commonMain | Code common to all platforms |
| commonTest | Common tests |
| androidMain | Android-specific implementation |
| iosMain | iOS common (all architectures) |
| iosArm64Main | iOS ARM64 (device) |
| iosX64Main | iOS X64 (Intel simulator) |
| iosSimulatorArm64Main | iOS Simulator ARM64 (M1/M2 Mac) |
| desktopMain | Desktop (JVM) |

---

## Best Practices Checklist

### Shared Module (shared)

- [ ] Place business logic (Domain Layer) in commonMain
- [ ] Place data access (Data Layer) in commonMain
- [ ] Place ViewModel in commonMain
- [ ] Abstract platform-specific code with expect/actual
- [ ] UI uses Compose Multiplatform or native per platform

### expect/actual

→ Details: [kmp-expect-actual.md](./kmp-expect-actual.md)

- [ ] Minimize platform-specific implementations
- [ ] Design common interface first
- [ ] actual implementations follow platform Best Practices
- [ ] Prepare Fake implementations in commonTest for testing

### Dependency Injection (Koin)

→ Details: [kmp-di-koin.md](./kmp-di-koin.md)

- [ ] Define common module in sharedModule
- [ ] Define platform-specific in platformModule
- [ ] Create ViewModel via Factory
- [ ] Enable Fake injection for testing

### Data Persistence (SQLDelight)

→ Details: [kmp-data-sqldelight.md](./kmp-data-sqldelight.md)

- [ ] Define schema commonly
- [ ] Implement Driver per platform
- [ ] Use transactions appropriately
- [ ] Monitor changes with Flow

### Networking (Ktor)

→ Details: [kmp-network-ktor.md](./kmp-network-ktor.md)

- [ ] Manage HttpClient with DI
- [ ] Configure engine per platform
- [ ] Unify error handling
- [ ] Use kotlinx-serialization for Serialization

### State Management

→ Details: [kmp-state-udf.md](./kmp-state-udf.md)

- [ ] Manage UI State with single data class
- [ ] Expose state with StateFlow
- [ ] Use Channel for temporary events
- [ ] Follow UDF (Unidirectional Data Flow)

### Testing

→ Details: [kmp-testing.md](./kmp-testing.md)

- [ ] Implement unit tests in commonTest
- [ ] Prefer Fake, minimize Mock
- [ ] Use runTest for Coroutine tests
- [ ] Centralize test utilities

### Error Handling

→ Details: [kmp-error-handling.md](./kmp-error-handling.md)

- [ ] Define AppException hierarchy
- [ ] Common error mapping across platforms
- [ ] Convert to UI error model
- [ ] Implement retry mechanism

---

## Reference Links

### Official Documentation

- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
- [Kotlin Multiplatform: Project structure](https://kotlinlang.org/docs/multiplatform-discover-project.html)
- [expect/actual declarations](https://kotlinlang.org/docs/multiplatform-expect-actual.html)
- [Compose Multiplatform](https://www.jetbrains.com/lp/compose-multiplatform/)

### Official Samples

- [Kotlin Multiplatform Samples](https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-samples.html)
- [KMM Sample (Kotlin Multiplatform Mobile)](https://github.com/Kotlin/kmm-basic-sample)
- [Compose Multiplatform Template](https://github.com/JetBrains/compose-multiplatform-template)

### Libraries

- [Ktor](https://ktor.io/docs/getting-started-ktor-client.html)
- [SQLDelight](https://cashapp.github.io/sqldelight/)
- [Koin](https://insert-koin.io/docs/reference/koin-mp/kmp/)
- [kotlinx-datetime](https://github.com/Kotlin/kotlinx-datetime)
- [kotlinx-serialization](https://github.com/Kotlin/kotlinx.serialization)

### Google Official

- [Android Developers: Kotlin Multiplatform](https://developer.android.com/kotlin/multiplatform)
