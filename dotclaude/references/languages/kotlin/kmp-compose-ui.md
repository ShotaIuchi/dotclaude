# KMP Compose Multiplatform

Kotlin Multiplatform での Compose Multiplatform UI 実装と SwiftUI 連携。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md) | [Compose Multiplatform 公式](https://www.jetbrains.com/lp/compose-multiplatform/)

---

## 共通 UI コンポーネント

```kotlin
// commonMain/kotlin/com/example/shared/ui/userlist/UserListScreen.kt

/**
 * ユーザー一覧画面（Compose Multiplatform）
 */
@Composable
fun UserListScreen(
    viewModel: UserListViewModel,
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    // イベントの処理
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is UserListEvent.NavigateToDetail -> {
                    onNavigateToDetail(event.userId)
                }
                is UserListEvent.ShowSnackbar -> {
                    // Snackbar 表示
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
 * ユーザー一覧のコンテンツ（プレビュー可能）
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
                EmptyContent(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.showContent -> {
                UserList(
                    users = uiState.users,
                    onUserClick = onUserClick
                )
            }
        }
    }
}

/**
 * ユーザーリスト
 */
@Composable
fun UserList(
    users: List<UserUiModel>,
    onUserClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(modifier = modifier) {
        items(
            items = users,
            key = { it.id }
        ) { user ->
            UserCard(
                user = user,
                onClick = { onUserClick(user.id) }
            )
        }
    }
}

/**
 * ユーザーカード
 */
@Composable
fun UserCard(
    user: UserUiModel,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = user.displayName,
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = user.formattedJoinDate,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
```

---

## 共通コンポーネント

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
                Text("再試行")
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

/**
 * ローディングコンポーネント
 */
@Composable
fun LoadingContent(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}
```

---

## SwiftUI 連携（iOS で SwiftUI を使う場合）

```swift
// iOS/Sources/UserListView.swift

import SwiftUI
import Shared

/**
 * SwiftUI での UserListScreen
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
            .navigationTitle("ユーザー一覧")
            .navigationDestination(for: String.self) { userId in
                UserDetailView(userId: userId)
            }
        }
        .task {
            await viewModel.observeEvents()
        }
    }
}

/**
 * Kotlin ViewModel を SwiftUI でラップ
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
        // MainActor で CoroutineScope を作成
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

- UI は Compose Multiplatform または各プラットフォームネイティブ
- ViewModel は commonMain に配置して共有
- プレビュー可能なコンポーネント設計
- SwiftUI 連携時は Wrapper クラスでブリッジ
