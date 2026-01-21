# KMP 状態管理と UDF

Kotlin Multiplatform での単方向データフロー (UDF) と MVI パターン実装。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md)

---

## 単方向データフロー (UDF) の原則

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

## MVI パターン実装

### 基底 ViewModel

```kotlin
// commonMain/kotlin/com/example/shared/presentation/mvi/MviViewModel.kt

/**
 * MVI ベースの ViewModel 基底クラス
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
     * Intent を処理する
     */
    fun dispatch(intent: Intent) {
        coroutineScope.launch {
            handleIntent(intent)
        }
    }

    /**
     * Intent のハンドリング（サブクラスで実装）
     */
    protected abstract suspend fun handleIntent(intent: Intent)

    /**
     * State を更新する
     */
    protected fun updateState(reducer: (State) -> State) {
        _state.update(reducer)
    }

    /**
     * Side Effect を発行する
     */
    protected suspend fun emitEffect(effect: Effect) {
        _effects.send(effect)
    }
}
```

### Contract 定義

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListContract.kt

/**
 * ユーザー一覧画面の Contract
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
     * User Intent（ユーザーアクション）
     */
    sealed interface Intent {
        object LoadUsers : Intent
        object Refresh : Intent
        data class UserClicked(val userId: String) : Intent
        object RetryClicked : Intent
    }

    /**
     * Side Effect（一度きりのイベント）
     */
    sealed interface Effect {
        data class NavigateToDetail(val userId: String) : Effect
        data class ShowSnackbar(val message: String) : Effect
    }
}
```

### ViewModel 実装

```kotlin
// commonMain/kotlin/com/example/shared/presentation/userlist/UserListMviViewModel.kt

/**
 * MVI パターンの ViewModel 実装
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

## ベストプラクティス

- UI State は単一の data class で管理
- StateFlow で状態を公開
- 一時的イベントは Channel を使用
- UDF（単方向データフロー）を遵守
