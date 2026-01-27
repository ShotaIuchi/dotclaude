# Android Architecture Patterns

MVVM / UDF / Repository patterns based on Google's official Android Architecture Guide.

## Core Principles

1. **Separation of Concerns** - Clearly separate UI logic from business logic
2. **Data-Driven UI** - UI only reflects state
3. **Single Source of Truth (SSOT)** - Repository is the SSOT for data
4. **Unidirectional Data Flow (UDF)** - Events flow upstream, state flows downstream
   - Example: User taps "Refresh" button -> ViewModel receives event -> UseCase fetches data -> Repository returns Result -> ViewModel updates UiState -> Compose recomposes UI

```
UI Layer -> Domain Layer -> Data Layer
    ^                          |
    +-------- State -----------+
```

## Layer Structure

| Layer | Responsibility | Key Components |
|-------|----------------|----------------|
| UI | Display and user interaction | Activity, Fragment, Compose, ViewModel |
| Domain | Business logic (optional layer) | UseCase, Domain Model |
| Data | Data retrieval and persistence | Repository, DataSource, DAO, API |

### Domain Layer Details

The Domain layer is optional but recommended for complex applications:

- **UseCase**: Encapsulates a single business operation. Coordinates between UI and Data layers, contains business rules, and is reusable across multiple ViewModels.
- **Domain Model**: Pure Kotlin data classes representing business entities. Independent of framework-specific types (no Room annotations, no API response models).

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

## Hilt Dependency Injection

Basic Hilt module structure:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DataModule {
    @Provides
    @Singleton
    fun provideUserRepository(api: UserApi, dao: UserDao): UserRepository =
        UserRepositoryImpl(api, dao)
}

@Module
@InstallIn(ViewModelComponent::class)
object DomainModule {
    @Provides
    fun provideGetUsersUseCase(repository: UserRepository): GetUsersUseCase =
        GetUsersUseCase(repository)
}
```

## Jetpack Compose State Management

State hoisting and remember best practices:

```kotlin
// State hoisting: lift state to caller
@Composable
fun UserListScreen(viewModel: UserListViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    UserListContent(
        users = uiState.users,
        onRefresh = viewModel::refresh
    )
}

// remember for expensive calculations
@Composable
fun UserListContent(users: List<User>, onRefresh: () -> Unit) {
    val sortedUsers = remember(users) { users.sortedBy { it.name } }
    // ...
}
```

## Error Handling Patterns

Using sealed class for result handling:

```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Throwable) : Result<Nothing>()
    object Loading : Result<Nothing>()
}

// In ViewModel
private val _uiState = MutableStateFlow<UserListUiState>(UserListUiState.Loading)
val uiState: StateFlow<UserListUiState> = _uiState.asStateFlow()

fun loadUsers() {
    viewModelScope.launch {
        getUsersUseCase().collect { result ->
            _uiState.value = when (result) {
                is Result.Success -> UserListUiState.Success(result.data)
                is Result.Error -> UserListUiState.Error(result.exception.message)
                is Result.Loading -> UserListUiState.Loading
            }
        }
    }
}
```

## Navigation Component Integration

Navigation with type-safe arguments:

```kotlin
// Define routes
sealed class Screen(val route: String) {
    object UserList : Screen("users")
    object UserDetail : Screen("users/{userId}") {
        fun createRoute(userId: String) = "users/$userId"
    }
}

// NavHost setup
NavHost(navController, startDestination = Screen.UserList.route) {
    composable(Screen.UserList.route) {
        UserListScreen(onUserClick = { userId ->
            navController.navigate(Screen.UserDetail.createRoute(userId))
        })
    }
    composable(
        route = Screen.UserDetail.route,
        arguments = listOf(navArgument("userId") { type = NavType.StringType })
    ) { backStackEntry ->
        UserDetailScreen(userId = backStackEntry.arguments?.getString("userId"))
    }
}
```
