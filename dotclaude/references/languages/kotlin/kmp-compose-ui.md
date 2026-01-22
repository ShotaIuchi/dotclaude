# KMP Compose Multiplatform

Compose Multiplatform UI implementation and SwiftUI integration in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Compose Multiplatform Official](https://www.jetbrains.com/lp/compose-multiplatform/)

---

## Common UI Components

```kotlin
// commonMain/kotlin/com/example/shared/ui/userlist/UserListScreen.kt

/**
 * User list screen (Compose Multiplatform)
 */
@Composable
fun UserListScreen(
    viewModel: UserListViewModel,
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    // Event handling
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is UserListEvent.NavigateToDetail -> {
                    onNavigateToDetail(event.userId)
                }
                is UserListEvent.ShowSnackbar -> {
                    // Show Snackbar
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
 * User list content (previewable)
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
 * User list
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
 * User card
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

## Common Components

```kotlin
// commonMain/kotlin/com/example/shared/ui/component/ErrorContent.kt

/**
 * Error display component
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
                Text("Retry")
            }
        }
    }
}

/**
 * Empty state display component
 */
@Composable
fun EmptyContent(
    modifier: Modifier = Modifier,
    message: String = "No data available"
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
 * Loading component
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

## SwiftUI Integration (When Using SwiftUI on iOS)

```swift
// iOS/Sources/UserListView.swift

import SwiftUI
import Shared

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
            .navigationTitle("User List")
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
 * Wrap Kotlin ViewModel for SwiftUI
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
        // Create CoroutineScope on MainActor
        let scope = MainScope()
        viewModel = factory.createUserListViewModel(coroutineScope: scope)

        // Observe State
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
                // Navigation handling
                break
            case .showSnackbar(let e):
                // Show Snackbar
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

## Best Practices

- UI can be Compose Multiplatform or platform-native
- Place ViewModel in commonMain for sharing
- Design components to be previewable
- Use wrapper class for SwiftUI integration
