# KMP Compose Multiplatform

Compose Multiplatform UI implementation and SwiftUI integration in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Compose Multiplatform Official](https://www.jetbrains.com/lp/compose-multiplatform/)

---

## Data Models

Define the UI models used throughout the screen components.

```kotlin
// commonMain/kotlin/com/example/shared/ui/model/UiModels.kt

/**
 * UI model for displaying user information
 */
data class UserUiModel(
    val id: String,
    val displayName: String,
    val formattedJoinDate: String
)

/**
 * Error actions available to the user
 */
enum class ErrorAction {
    RETRY,
    DISMISS,
    NAVIGATE_BACK
}

/**
 * UI error representation
 */
data class UiError(
    val message: String,
    val action: ErrorAction = ErrorAction.RETRY
)

/**
 * UI state for user list screen
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
 * Events emitted by UserListViewModel
 */
sealed interface UserListEvent {
    data class NavigateToDetail(val userId: String) : UserListEvent
    data class ShowSnackbar(val message: String) : UserListEvent
}
```

---

## Screen Components

Screen-level composables that connect to ViewModels and handle navigation.

```kotlin
// commonMain/kotlin/com/example/shared/ui/userlist/UserListScreen.kt

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.shared.ui.model.*

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

## Reusable Components

Common UI components that can be shared across multiple screens.

```kotlin
// commonMain/kotlin/com/example/shared/ui/component/ErrorContent.kt

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.shared.ui.model.ErrorAction
import com.example.shared.ui.model.UiError

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

When integrating Kotlin Multiplatform code with SwiftUI, you need:

1. **SKIE (Swift Kotlin Interface Enhancer)**: Generates Swift-friendly APIs from Kotlin code, including `onEnum` for sealed class pattern matching
2. **kotlinx-coroutines-core**: Provides `MainScope()` for managing coroutines on the main thread

### Dependencies

Add SKIE to your `build.gradle.kts`:

```kotlin
plugins {
    id("co.touchlab.skie") version "0.6.1"
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
        }
    }
}
```

### ViewModelFactory

```kotlin
// commonMain/kotlin/com/example/shared/ui/ViewModelFactory.kt

import kotlinx.coroutines.CoroutineScope

/**
 * Factory for creating ViewModels with proper CoroutineScope injection
 */
class ViewModelFactory {
    fun createUserListViewModel(coroutineScope: CoroutineScope): UserListViewModel {
        // Inject dependencies (repository, use cases, etc.)
        return UserListViewModel(coroutineScope)
    }
}
```

### SwiftUI View

```swift
// iOS/Sources/UserListView.swift

import SwiftUI
import Shared  // Kotlin shared module

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

### UI Strategy Selection

**UI can be Compose Multiplatform or platform-native**

- Use Compose Multiplatform when you want maximum code sharing and consistent UI across platforms
- Use platform-native (SwiftUI/UIKit) when you need platform-specific UX patterns or better native integration

### ViewModel Placement

**Place ViewModel in commonMain for sharing**

```kotlin
// commonMain/kotlin/com/example/shared/viewmodel/UserListViewModel.kt
class UserListViewModel(private val scope: CoroutineScope) {
    // Business logic shared across iOS and Android
}
```

This allows both platforms to share the same business logic while implementing platform-specific UI.

### Previewable Design

**Design components to be previewable**

Separate state-dependent content from ViewModel-dependent screens:

```kotlin
// Screen: Depends on ViewModel (not previewable directly)
@Composable
fun UserListScreen(viewModel: UserListViewModel) { ... }

// Content: Takes state as parameter (previewable)
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

### SwiftUI Integration Pattern

**Use wrapper class for SwiftUI integration**

The `ObservableObject` wrapper pattern converts Kotlin Flows to SwiftUI's reactive model:

```swift
@MainActor
class ViewModelWrapper: ObservableObject {
    @Published private(set) var state: UiState
    private let kotlinViewModel: KotlinViewModel

    // Observe Kotlin Flow and update @Published property
    private func observeState() {
        Task {
            for await state in kotlinViewModel.uiState {
                self.state = state
            }
        }
    }
}
```
