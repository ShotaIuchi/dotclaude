# KMP State Management and UDF

Unidirectional Data Flow (UDF) and MVI pattern implementation in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md)

---

## Unidirectional Data Flow (UDF) Principles

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│   ┌─────────┐                                         │
│   │  State  │◄───────────────────────────────────┐   │
│   └────┬────┘                                    │   │
│        │                                         │   │
│        ▼                                         │   │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐ │   │
│   │   UI    │─────►│  Intent │─────►│ Reduce  │─┘   │
│   └─────────┘      └─────────┘      └─────────┘     │
│                                                      │
│        ▲                                             │
│        │                                             │
│   ┌────┴────┐                                        │
│   │ Side    │◄───────────────────────────────────────┘
│   │ Effects │
│   └─────────┘
│
└────────────────────────────────────────────────────────┘
```

---

## MVI Pattern Implementation

### Base ViewModel

```kotlin
// commonMain/kotlin/com/example/shared/presentation/mvi/MviViewModel.kt

/**
 * MVI-based ViewModel base class
 */
abstract class MviViewModel<State, Intent, Effect>(
    initialState: State,
    private val coroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()

    private val _effects = Channel<Effect>(Channel.BUFFERED)
    val effects: Flow<Effect> = _effects.receiveAsFlow()

    /**
     * Process Intent
     */
    fun dispatch(intent: Intent) {
        coroutineScope.launch {
            handleIntent(intent)
        }
    }

    /**
     * Intent handling (implement in subclass)
     */
    protected abstract suspend fun handleIntent(intent: Intent)

    /**
     * Update State
     */
    protected fun updateState(reducer: (State) -> State) {
        _state.update(reducer)
    }

    /**
     * Emit Side Effect
     */
    protected suspend fun emitEffect(effect: Effect) {
        _effects.send(effect)
    }
}
```

### Contract Definition

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListContract.kt

/**
 * User list screen Contract
 */
object UserListContract {

    /**
     * UI State
     */
    data class State(
        val users: List<UserUiModel> = emptyList(),
        val isLoading: Boolean = false,
        val error: UiError? = null
    ) {
        val isEmpty: Boolean
            get() = users.isEmpty() && !isLoading && error == null
    }

    /**
     * User Intent (user actions)
     */
    sealed interface Intent {
        object LoadUsers : Intent
        object Refresh : Intent
        data class UserClicked(val userId: String) : Intent
        object RetryClicked : Intent
    }

    /**
     * Side Effect (one-time events)
     */
    sealed interface Effect {
        data class NavigateToDetail(val userId: String) : Effect
        data class ShowSnackbar(val message: String) : Effect
    }
}
```

### ViewModel Implementation

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListMviViewModel.kt

/**
 * MVI pattern ViewModel implementation
 */
class UserListMviViewModel(
    private val getUsersUseCase: GetUsersUseCase,
    coroutineScope: CoroutineScope
) : MviViewModel<
    UserListContract.State,
    UserListContract.Intent,
    UserListContract.Effect
>(
    initialState = UserListContract.State(),
    coroutineScope = coroutineScope
) {
    private var loadJob: Job? = null

    init {
        dispatch(UserListContract.Intent.LoadUsers)
    }

    override suspend fun handleIntent(intent: UserListContract.Intent) {
        when (intent) {
            is UserListContract.Intent.LoadUsers,
            is UserListContract.Intent.Refresh,
            is UserListContract.Intent.RetryClicked -> loadUsers()

            is UserListContract.Intent.UserClicked -> {
                emitEffect(UserListContract.Effect.NavigateToDetail(intent.userId))
            }
        }
    }

    private suspend fun loadUsers() {
        loadJob?.cancel()
        updateState { it.copy(isLoading = true, error = null) }

        getUsersUseCase()
            .catch { e ->
                updateState { it.copy(isLoading = false, error = e.toUiError()) }
            }
            .collect { users ->
                updateState {
                    it.copy(
                        isLoading = false,
                        users = users.map { user -> user.toUiModel() }
                    )
                }
            }
    }
}
```

---

## Best Practices

- Manage UI State with a single data class
- Expose state via StateFlow
- Use Channel for transient events
- Follow UDF (Unidirectional Data Flow)
