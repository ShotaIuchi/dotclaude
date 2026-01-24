# KMP 状態管理と UDF

Kotlin Multiplatform における単方向データフロー（UDF）と MVI パターンの実装。

> **ドキュメントのスコープ**: このドキュメントは MVI（Model-View-Intent）パターンと UDF 原則に特化しています。一般的な ViewModel パターンとアーキテクチャ概要については、KMP Architecture Guide を参照してください。このドキュメントは、アーキテクチャガイドで定義された基本パターンを拡張する MVI 固有の実装詳細を提供します。

---

## 概要

単方向データフロー（UDF）は、状態の流れを一方向に制限することで、予測可能で保守しやすいアプリケーションを構築するパターンです。MVI（Model-View-Intent）はこのパターンを実装するアプローチの一つです。

---

## 単方向データフロー（UDF）原則

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

注意: Side Effects は Reduce（状態遷移）によってトリガーされ、UI から直接ではありません。
Effects フロー: UI → Intent → Reduce → Effects Handler → Side Effects → UI
```

---

## MVI パターン実装

### 基本 ViewModel

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
     * Intent を処理
     */
    fun dispatch(intent: Intent) {
        coroutineScope.launch {
            handleIntent(intent)
        }
    }

    /**
     * Intent 処理（サブクラスで実装）
     */
    protected abstract suspend fun handleIntent(intent: Intent)

    /**
     * State を更新
     */
    protected fun updateState(reducer: (State) -> State) {
        _state.update(reducer)
    }

    /**
     * Side Effect を発行
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
 * ユーザーリスト画面の Contract
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
     * Side Effect（一回限りのイベント）
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
 * MVI パターン ViewModel 実装
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

## ベストプラクティス

### 核となる原則

- 単一のデータクラスで UI State を管理
- StateFlow で状態を公開
- 一時的なイベントには Channel を使用
- UDF（単方向データフロー）に従う

### 状態の不変性

- State には常に `data class` を使用し、更新には `copy()` を使用
- 状態を直接変更せず、`updateState { ... }` リデューサーパターンを使用
- 特定の状態フィールドを監視する際は `distinctUntilChanged()` を使用

### Effect 処理

- Effects は一回限りのイベント。設定変更時に再発行しない
- UI レイヤーで収集後すぐに Effects を処理
- 型安全な Effect 処理のために sealed interface を使用

### Intent 設計

- Intent はシンプルなユーザーアクションとして保持（例: `ButtonClicked`、`LoadDataAndNavigate` ではなく）
- 必要に応じて複雑な動作を複数の Intent にマップ
- パラメータを持つ Intent にはデータクラスを使用

### テスト戦略

- Intent → State 遷移を分離してテスト
- Turbine や同様のテストライブラリで Effect 発行を検証
- UseCase をモックして ViewModel ロジックを独立してテスト

---

## プラットフォーム統合

### iOS (Swift) 状態監視

Swift から StateFlow を消費する場合、Kotlin/Native async sequence ブリッジを使用：

```swift
// iOS Swift コードで KMP ViewModel の状態を監視
func observeState() async {
    for await state in viewModel.state {
        // 新しい状態で SwiftUI/UIKit を更新
        updateUI(state)
    }
}
```

### Compose Multiplatform

```kotlin
@Composable
fun UserListScreen(viewModel: UserListMviViewModel) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.effects.collect { effect ->
            when (effect) {
                is UserListContract.Effect.NavigateToDetail -> { /* ナビゲーション */ }
                is UserListContract.Effect.ShowSnackbar -> { /* Snackbar 表示 */ }
            }
        }
    }

    // 状態に基づいて UI をレンダリング
}
```

---

## 関連ドキュメント

- [KMP Error Handling](./kmp-error-handling.md) - UiError 型定義とエラーマッピング
- [KMP Testing](./kmp-testing.md) - ViewModel と MVI テストパターン
- [KMP Architecture](./kmp-architecture.md) - 全体アーキテクチャと ViewModel パターン
