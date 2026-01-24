# KMP Compose Multiplatform

Kotlin Multiplatform における Compose Multiplatform UI 実装と SwiftUI 統合。

---

## 概要

Compose Multiplatform は、Android、iOS、Desktop などの複数プラットフォームで共通の UI コードを使用できるフレームワークです。ViewModel を commonMain に配置することで、ビジネスロジックを共有しながら、プラットフォーム固有の UI も実装できます。

---

## データモデル

画面コンポーネント全体で使用される UI モデルを定義します。

```kotlin
// commonMain/kotlin/com/example/shared/ui/model/UiModels.kt

/**
 * ユーザー情報を表示するための UI モデル
 */
data class UserUiModel(
    val id: String,
    val displayName: String,
    val formattedJoinDate: String
)

/**
 * ユーザーが利用できるエラーアクション
 */
enum class ErrorAction {
    RETRY,
    DISMISS,
    NAVIGATE_BACK
}

/**
 * UI エラー表現
 */
data class UiError(
    val message: String,
    val action: ErrorAction = ErrorAction.RETRY
)

/**
 * ユーザーリスト画面の UI 状態
 */
data class UserListUiState(
    val users: List<UserUiModel> = emptyList(),
    val isLoading: Boolean = false,
    val error: UiError? = null
) {
    val showEmptyState: Boolean get() = !isLoading && error == null && users.isEmpty()
    val showContent: Boolean get() = !isLoading && error == null && users.isNotEmpty()
}

/**
 * UserListViewModel が発行するイベント
 */
sealed interface UserListEvent {
    data class NavigateToDetail(val userId: String) : UserListEvent
    data class ShowSnackbar(val message: String) : UserListEvent
}
```

---

## 画面コンポーネント

ViewModel に接続し、ナビゲーションを処理する画面レベルの Composable。

```kotlin
// commonMain/kotlin/com/example/shared/ui/userlist/UserListScreen.kt

/**
 * ユーザーリスト画面（Compose Multiplatform）
 */
@Composable
fun UserListScreen(
    viewModel: UserListViewModel,
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    // イベント処理
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is UserListEvent.NavigateToDetail -> {
                    onNavigateToDetail(event.userId)
                }
                is UserListEvent.ShowSnackbar -> {
                    // Snackbar を表示
                }
            }
        }
    }

    UserListContent(
        uiState = uiState,
        onUserClick = viewModel::onUserClick,
        onRetryClick = viewModel::onRetryClick
    )
}

/**
 * ユーザーリストコンテンツ（プレビュー可能）
 */
@Composable
fun UserListContent(
    uiState: UserListUiState,
    onUserClick: (String) -> Unit,
    onRetryClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        when {
            uiState.isLoading -> {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.error != null -> {
                ErrorContent(
                    error = uiState.error,
                    onRetryClick = onRetryClick,
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.showEmptyState -> {
                EmptyContent(modifier = Modifier.align(Alignment.Center))
            }
            uiState.showContent -> {
                UserList(users = uiState.users, onUserClick = onUserClick)
            }
        }
    }
}
```

---

## 再利用可能コンポーネント

複数の画面で共有できる共通 UI コンポーネント。

```kotlin
// commonMain/kotlin/com/example/shared/ui/component/ErrorContent.kt

/**
 * エラー表示コンポーネント
 */
@Composable
fun ErrorContent(
    error: UiError,
    onRetryClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Warning,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.error
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = error.message,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )
        if (error.action == ErrorAction.RETRY) {
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onRetryClick) {
                Text("リトライ")
            }
        }
    }
}

/**
 * 空状態表示コンポーネント
 */
@Composable
fun EmptyContent(
    modifier: Modifier = Modifier,
    message: String = "データがありません"
) {
    Column(
        modifier = modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Inbox,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
```

---

## SwiftUI 統合（iOS で SwiftUI を使用する場合）

Kotlin Multiplatform コードを SwiftUI と統合する場合、以下が必要です：

1. **SKIE（Swift Kotlin Interface Enhancer）**: Kotlin コードから Swift フレンドリーな API を生成（sealed class パターンマッチング用の `onEnum` を含む）
2. **kotlinx-coroutines-core**: メインスレッドでコルーチンを管理する `MainScope()` を提供

### SwiftUI View

```swift
// iOS/Sources/UserListView.swift

import SwiftUI
import Shared  // Kotlin shared モジュール

/**
 * SwiftUI UserListScreen
 */
struct UserListView: View {
    @StateObject private var viewModel: UserListViewModelWrapper

    init() {
        let factory = ViewModelFactory()
        _viewModel = StateObject(wrappedValue: UserListViewModelWrapper(factory: factory))
    }

    var body: some View {
        NavigationStack {
            UserListContent(
                state: viewModel.state,
                onUserTap: viewModel.onUserClick,
                onRetryTap: viewModel.onRetryClick
            )
            .navigationTitle("ユーザーリスト")
        }
        .task {
            await viewModel.observeEvents()
        }
    }
}

/**
 * SwiftUI 用に Kotlin ViewModel をラップ
 */
@MainActor
class UserListViewModelWrapper: ObservableObject {
    @Published private(set) var state = UserListUiState(
        users: [],
        isLoading: false,
        error: nil
    )

    private let viewModel: UserListViewModel
    private var stateJob: Task<Void, Never>?

    init(factory: ViewModelFactory) {
        // MainActor 上で CoroutineScope を作成
        let scope = MainScope()
        viewModel = factory.createUserListViewModel(coroutineScope: scope)

        // State を監視
        observeState()
    }

    private func observeState() {
        stateJob = Task {
            for await state in viewModel.uiState {
                self.state = state
            }
        }
    }

    func observeEvents() async {
        for await event in viewModel.events {
            switch onEnum(of: event) {
            case .navigateToDetail(let e):
                // ナビゲーション処理
                break
            case .showSnackbar(let e):
                // Snackbar 表示
                break
            }
        }
    }

    func onUserClick(userId: String) {
        viewModel.onUserClick(userId: userId)
    }

    func onRetryClick() {
        viewModel.onRetryClick()
    }

    deinit {
        stateJob?.cancel()
        viewModel.onCleared()
    }
}
```

---

## ベストプラクティス

### UI 戦略の選択

**UI は Compose Multiplatform またはプラットフォームネイティブ**

- 最大限のコード共有と一貫した UI が必要な場合は Compose Multiplatform を使用
- プラットフォーム固有の UX パターンやより良いネイティブ統合が必要な場合はプラットフォームネイティブ（SwiftUI/UIKit）を使用

### ViewModel の配置

**ViewModel は共有のために commonMain に配置**

```kotlin
// commonMain/kotlin/com/example/shared/viewmodel/UserListViewModel.kt
class UserListViewModel(private val scope: CoroutineScope) {
    // iOS と Android で共有されるビジネスロジック
}
```

これにより、両プラットフォームが同じビジネスロジックを共有しながら、プラットフォーム固有の UI を実装できます。

### プレビュー可能な設計

**コンポーネントはプレビュー可能に設計**

状態依存のコンテンツと ViewModel 依存の画面を分離：

```kotlin
// Screen: ViewModel に依存（直接プレビュー不可）
@Composable
fun UserListScreen(viewModel: UserListViewModel) { ... }

// Content: 状態をパラメータとして受け取る（プレビュー可能）
@Composable
fun UserListContent(
    uiState: UserListUiState,
    onUserClick: (String) -> Unit,
    onRetryClick: () -> Unit
) { ... }

// Preview
@Preview
@Composable
fun UserListContentPreview() {
    UserListContent(
        uiState = UserListUiState(users = listOf(sampleUser)),
        onUserClick = {},
        onRetryClick = {}
    )
}
```

### SwiftUI 統合パターン

**SwiftUI 統合にはラッパークラスを使用**

`ObservableObject` ラッパーパターンで Kotlin Flow を SwiftUI のリアクティブモデルに変換：

```swift
@MainActor
class ViewModelWrapper: ObservableObject {
    @Published private(set) var state: UiState
    private let kotlinViewModel: KotlinViewModel

    // Kotlin Flow を監視して @Published プロパティを更新
    private func observeState() {
        Task {
            for await state in kotlinViewModel.uiState {
                self.state = state
            }
        }
    }
}
```
