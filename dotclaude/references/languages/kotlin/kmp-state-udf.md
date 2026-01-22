# KMP State Management and UDF

Unidirectional Data Flow (UDF) and MVI pattern implementation in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md)
>
> **Document Scope**: This document focuses specifically on the MVI (Model-View-Intent) pattern and UDF principles. For general ViewModel patterns and architecture overview, refer to the KMP Architecture Guide. This document provides complementary, MVI-specific implementation details that extend the base patterns defined in the architecture guide.

---

## Unidirectional Data Flow (UDF) Principles

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌─────────┐                                              │
│   │  State  │◄────────────────────────────────────────┐    │
│   └────┬────┘                                         │    │
│        │                                              │    │
│        ▼                                              │    │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐      │    │
│   │   UI    │─────►│  Intent │─────►│ Reduce  │──────┘    │
│   └─────────┘      └─────────┘      └────┬────┘           │
│                                          │                 │
│        ▲                                 │                 │
│        │                                 ▼                 │
│   ┌────┴────┐                       ┌─────────┐           │
│   │ Side    │◄──────────────────────│ Effects │           │
│   │ Effects │                       │ Handler │           │
│   └─────────┘                       └─────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Note: Side Effects are triggered by Reduce (state transitions), not directly by UI.
Effects flow: UI → Intent → Reduce → Effects Handler → Side Effects → UI
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
     *
     * Note: UiError type is defined in kmp-error-handling.md
     * Note: UserUiModel is a presentation layer model mapped from domain User
     */
    data class State(
        val users: List<UserUiModel> = emptyList(),
        val isLoading: Boolean = false,
        val error: UiError? = null
    ) {
        val isEmpty: Boolean
            get() = users.isEmpty() && !isLoading && error == null
    }

    // --- Type References (see related documentation) ---
    // UiError: Defined in kmp-error-handling.md
    //   sealed interface UiError {
    //       data class Network(val message: String) : UiError
    //       data class Server(val code: Int, val message: String) : UiError
    //       data class Generic(val message: String) : UiError
    //   }
    //
    // Extension functions (presentation/mapper package):
    //   fun Throwable.toUiError(): UiError
    //   fun User.toUiModel(): UserUiModel

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

        loadJob = coroutineScope.launch {
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
}
```

---

## Best Practices

### Core Principles

- Manage UI State with a single data class
- Expose state via StateFlow
- Use Channel for transient events
- Follow UDF (Unidirectional Data Flow)

### State Immutability

- Always use `data class` for State with `copy()` for updates
- Never mutate state directly; use `updateState { ... }` reducer pattern
- Use `distinctUntilChanged()` when observing specific state fields

### Effect Handling

- Effects are one-time events; do not re-emit on configuration changes
- Process effects in UI layer immediately after collection
- Use sealed interfaces for type-safe effect handling

### Intent Design

- Keep Intents as simple user actions (e.g., `ButtonClicked`, not `LoadDataAndNavigate`)
- Map complex behaviors to multiple Intents if needed
- Use data classes for Intents that carry parameters

### Testing Strategies

- Test Intent → State transitions in isolation
- Verify Effect emissions using Turbine or similar test libraries
- Mock use cases to test ViewModel logic independently

> **See Also**: [KMP Testing Guide](./kmp-testing.md) for detailed testing patterns

---

## Platform Integration

### iOS (Swift) State Observation

When consuming StateFlow from Swift, use the Kotlin/Native async sequence bridge:

```swift
// iOS Swift code observing KMP ViewModel state
func observeState() async {
    for await state in viewModel.state {
        // Update SwiftUI/UIKit with new state
        updateUI(state)
    }
}
```

> **See Also**: [KMP Architecture Guide](./kmp-architecture.md) for iOS ViewModel wrapper patterns

### Compose Multiplatform

```kotlin
@Composable
fun UserListScreen(viewModel: UserListMviViewModel) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.effects.collect { effect ->
            when (effect) {
                is UserListContract.Effect.NavigateToDetail -> { /* navigation */ }
                is UserListContract.Effect.ShowSnackbar -> { /* show snackbar */ }
            }
        }
    }

    // Render UI based on state
}
```

---

## Related Documentation

- [KMP Error Handling](./kmp-error-handling.md) - UiError type definitions and error mapping
- [KMP Testing](./kmp-testing.md) - ViewModel and MVI testing patterns
- [KMP Architecture](./kmp-architecture.md) - Overall architecture and ViewModel patterns

---

> **Code Comment Language Policy**: Code comments in this document use English for consistency with Kotlin community conventions. Document explanations are provided in both English headers and content for international accessibility.
