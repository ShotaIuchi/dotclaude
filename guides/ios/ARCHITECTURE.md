# iOS Architecture Guide

Apple 公式ガイドラインに基づく、SwiftUI + MVVM / State 管理のベストプラクティス集。

---

## 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [レイヤー構成](#レイヤー構成)
3. [Presentation Layer](#presentation-layer)
4. [Domain Layer](#domain-layer)
5. [Data Layer](#data-layer)
6. [依存性注入 (DI)](#依存性注入-di)
7. [状態管理](#状態管理)
8. [非同期処理 (async/await / Combine)](#非同期処理-asyncawait--combine)
9. [エラーハンドリング](#エラーハンドリング)
10. [テスト戦略](#テスト戦略)
11. [ディレクトリ構造](#ディレクトリ構造)
12. [命名規則](#命名規則)
13. [ベストプラクティス一覧](#ベストプラクティス一覧)

---

## アーキテクチャ概要

### 基本原則

1. **関心の分離 (Separation of Concerns)**
   - UI ロジックとビジネスロジックを明確に分離
   - 各レイヤーは単一責任を持つ

2. **データ駆動型 UI (Data-driven UI)**
   - UI は状態（State）を反映するだけ
   - 状態変更は ViewModel 経由で行う

3. **単一の信頼できる情報源 (Single Source of Truth: SSOT)**
   - データは一箇所で管理し、他はそこから取得
   - Repository がデータの SSOT となる

4. **単方向データフロー (Unidirectional Data Flow: UDF)**
   - イベントは上流へ（View → ViewModel → Repository）
   - 状態は下流へ（Repository → ViewModel → View）

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐    State    ┌─────────────────────────┐   │
│  │    View     │◄────────────│      ViewModel          │   │
│  │  (SwiftUI)  │             │                         │   │
│  │             │────────────►│  - UI State             │   │
│  └─────────────┘   Actions   │  - Business Logic Call  │   │
└─────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer (Optional)                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Use Cases                         │   │
│  │  - 複雑なビジネスロジックのカプセル化                    │   │
│  │  - 複数 Repository の組み合わせ                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Repository                         │   │
│  │  - データアクセスの抽象化                              │   │
│  │  - キャッシュ戦略                                     │   │
│  │  - オフライン対応                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                    │                    │                    │
│                    ▼                    ▼                    │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │   Local DataSource   │  │  Remote DataSource   │        │
│  │   (SwiftData/        │  │   (URLSession/       │        │
│  │    CoreData)         │  │    Alamofire)        │        │
│  └──────────────────────┘  └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## レイヤー構成

### 依存関係の方向

```
Presentation Layer → Domain Layer → Data Layer
```

- 上位レイヤーは下位レイヤーに依存
- 下位レイヤーは上位レイヤーを知らない
- Protocol を通じて依存性を逆転（DIP）

### 各レイヤーの責務

| レイヤー | 責務 | 主要コンポーネント |
|---------|------|-------------------|
| Presentation | 画面表示・ユーザー操作 | View (SwiftUI), ViewModel |
| Domain | ビジネスロジック | UseCase, Domain Model |
| Data | データ取得・永続化 | Repository, DataSource, API |

---

## Presentation Layer

### ViewModel（iOS 17+ @Observable）

```swift
import SwiftUI
import Observation

/**
 * ユーザー一覧画面の ViewModel
 *
 * UI 状態の管理とビジネスロジックの呼び出しを担当
 */
@Observable
final class UserListViewModel {

    // MARK: - 公開プロパティ

    // UI State
    private(set) var uiState = UserListUiState()

    // 一時的なイベント（ナビゲーション、アラート等）
    private(set) var navigationEvent: UserListNavigationEvent?

    // MARK: - 非公開プロパティ

    private let getUsersUseCase: GetUsersUseCaseProtocol
    private var loadTask: Task<Void, Never>?

    // MARK: - 初期化

    init(getUsersUseCase: GetUsersUseCaseProtocol) {
        self.getUsersUseCase = getUsersUseCase
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - 公開関数

    /**
     * ユーザー一覧を読み込む
     */
    func loadUsers() {
        loadTask?.cancel()
        loadTask = Task {
            await performLoadUsers()
        }
    }

    /**
     * ユーザーを選択する
     */
    func onUserTap(_ userId: String) {
        navigationEvent = .detail(userId: userId)
    }

    /**
     * ナビゲーションイベントを消費
     */
    func consumeNavigationEvent() {
        navigationEvent = nil
    }

    /**
     * リトライする
     */
    func onRetryTap() {
        loadUsers()
    }

    // MARK: - 非公開関数

    @MainActor
    private func performLoadUsers() async {
        uiState = uiState.copy(isLoading: true, error: nil)

        do {
            let users = try await getUsersUseCase.execute()
            uiState = uiState.copy(
                users: users.map { $0.toUiModel() },
                isLoading: false
            )
        } catch {
            uiState = uiState.copy(
                isLoading: false,
                error: error.toUiError()
            )
        }
    }
}
```

### ViewModel（iOS 15-16 ObservableObject）

```swift
import SwiftUI
import Combine

/**
 * ユーザー一覧画面の ViewModel（iOS 15-16 対応版）
 */
final class UserListViewModel: ObservableObject {

    // MARK: - 公開プロパティ

    @Published private(set) var uiState = UserListUiState()
    @Published private(set) var navigationEvent: UserListNavigationEvent?

    // MARK: - 非公開プロパティ

    private let getUsersUseCase: GetUsersUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    // MARK: - 初期化

    init(getUsersUseCase: GetUsersUseCaseProtocol) {
        self.getUsersUseCase = getUsersUseCase
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - 公開関数

    @MainActor
    func loadUsers() {
        loadTask?.cancel()
        loadTask = Task {
            uiState = uiState.copy(isLoading: true, error: nil)

            do {
                let users = try await getUsersUseCase.execute()
                uiState = uiState.copy(
                    users: users.map { $0.toUiModel() },
                    isLoading: false
                )
            } catch {
                uiState = uiState.copy(
                    isLoading: false,
                    error: error.toUiError()
                )
            }
        }
    }

    func onUserTap(_ userId: String) {
        navigationEvent = .detail(userId: userId)
    }

    func consumeNavigationEvent() {
        navigationEvent = nil
    }

    func onRetryTap() {
        loadUsers()
    }
}
```

### UI State

```swift
import Foundation

/**
 * ユーザー一覧画面の UI 状態
 *
 * Immutable な構造体で状態を表現
 */
struct UserListUiState: Equatable {

    // MARK: - プロパティ

    let users: [UserUiModel]
    let isLoading: Bool
    let error: UiError?

    // MARK: - 派生プロパティ

    var isEmpty: Bool {
        users.isEmpty && !isLoading && error == nil
    }

    var showEmptyState: Bool {
        isEmpty
    }

    var showContent: Bool {
        !users.isEmpty
    }

    // MARK: - 初期化

    init(
        users: [UserUiModel] = [],
        isLoading: Bool = false,
        error: UiError? = nil
    ) {
        self.users = users
        self.isLoading = isLoading
        self.error = error
    }

    // MARK: - コピー関数

    func copy(
        users: [UserUiModel]? = nil,
        isLoading: Bool? = nil,
        error: UiError?? = nil
    ) -> UserListUiState {
        UserListUiState(
            users: users ?? self.users,
            isLoading: isLoading ?? self.isLoading,
            error: error ?? self.error
        )
    }
}

/**
 * UI 層で使用するユーザーモデル
 */
struct UserUiModel: Equatable, Identifiable {
    let id: String
    let displayName: String
    let avatarUrl: URL?
    let formattedJoinDate: String
}

/**
 * ナビゲーションイベント
 */
enum UserListNavigationEvent: Equatable {
    case detail(userId: String)
}
```

### SwiftUI View

```swift
import SwiftUI

/**
 * ユーザー一覧画面
 */
struct UserListScreen: View {

    // MARK: - プロパティ

    // iOS 17+: @State, iOS 15-16: @StateObject
    @State private var viewModel: UserListViewModel
    @State private var navigationPath = NavigationPath()

    // MARK: - 初期化

    init(viewModel: UserListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            UserListContent(
                uiState: viewModel.uiState,
                onUserTap: viewModel.onUserTap,
                onRetryTap: viewModel.onRetryTap
            )
            .navigationTitle("ユーザー一覧")
            .navigationDestination(for: String.self) { userId in
                UserDetailScreen(userId: userId)
            }
        }
        .task {
            viewModel.loadUsers()
        }
        .onChange(of: viewModel.navigationEvent) { _, event in
            handleNavigationEvent(event)
        }
    }

    // MARK: - 非公開関数

    private func handleNavigationEvent(_ event: UserListNavigationEvent?) {
        guard let event else { return }

        switch event {
        case .detail(let userId):
            navigationPath.append(userId)
        }

        viewModel.consumeNavigationEvent()
    }
}

/**
 * ユーザー一覧のコンテンツ（プレビュー可能）
 */
struct UserListContent: View {

    // MARK: - プロパティ

    let uiState: UserListUiState
    let onUserTap: (String) -> Void
    let onRetryTap: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            if uiState.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = uiState.error {
                ErrorContent(
                    error: error,
                    onRetryTap: onRetryTap
                )
            } else if uiState.showEmptyState {
                EmptyContent()
            } else if uiState.showContent {
                UserList(
                    users: uiState.users,
                    onUserTap: onUserTap
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * ユーザーリスト
 */
struct UserList: View {

    let users: [UserUiModel]
    let onUserTap: (String) -> Void

    var body: some View {
        List(users) { user in
            UserCard(user: user)
                .onTapGesture {
                    onUserTap(user.id)
                }
        }
        .listStyle(.plain)
    }
}

/**
 * プレビュー
 */
#Preview("Loading") {
    UserListContent(
        uiState: UserListUiState(isLoading: true),
        onUserTap: { _ in },
        onRetryTap: {}
    )
}

#Preview("Content") {
    UserListContent(
        uiState: UserListUiState(
            users: [
                UserUiModel(
                    id: "1",
                    displayName: "Alice",
                    avatarUrl: nil,
                    formattedJoinDate: "2024/01/01"
                ),
                UserUiModel(
                    id: "2",
                    displayName: "Bob",
                    avatarUrl: nil,
                    formattedJoinDate: "2024/02/15"
                )
            ]
        ),
        onUserTap: { _ in },
        onRetryTap: {}
    )
}

#Preview("Error") {
    UserListContent(
        uiState: UserListUiState(
            error: UiError(
                message: "通信エラーが発生しました",
                action: .retry
            )
        ),
        onUserTap: { _ in },
        onRetryTap: {}
    )
}
```

---

## Domain Layer

### UseCase

```swift
import Foundation

/**
 * ユーザー一覧取得の UseCase Protocol
 */
protocol GetUsersUseCaseProtocol {
    func execute() async throws -> [User]
}

/**
 * ユーザー一覧取得の UseCase
 *
 * 単一のビジネスロジックをカプセル化
 */
final class GetUsersUseCase: GetUsersUseCaseProtocol {

    // MARK: - 非公開プロパティ

    private let userRepository: UserRepositoryProtocol
    private let analyticsRepository: AnalyticsRepositoryProtocol

    // MARK: - 初期化

    init(
        userRepository: UserRepositoryProtocol,
        analyticsRepository: AnalyticsRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - 公開関数

    /**
     * ユーザー一覧を取得する
     */
    func execute() async throws -> [User] {
        let users = try await userRepository.getUsers()

        // 副作用（アナリティクス送信など）
        await analyticsRepository.logUserListViewed(count: users.count)

        return users
    }
}

/**
 * ユーザー詳細取得の UseCase
 */
final class GetUserDetailUseCase {

    private let userRepository: UserRepositoryProtocol
    private let postRepository: PostRepositoryProtocol

    init(
        userRepository: UserRepositoryProtocol,
        postRepository: PostRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.postRepository = postRepository
    }

    /**
     * ユーザー詳細と投稿を取得する
     *
     * 複数の Repository を組み合わせる例
     */
    func execute(userId: String) async throws -> UserDetail {
        async let user = userRepository.getUser(userId: userId)
        async let posts = postRepository.getPostsByUser(userId: userId)

        return try await UserDetail(
            user: user,
            posts: posts,
            postCount: posts.count
        )
    }
}
```

### Domain Model

```swift
import Foundation

/**
 * ドメインモデル（ビジネスロジックを含む）
 */
struct User: Equatable, Identifiable {
    let id: String
    let name: String
    let email: String
    let joinedAt: Date
    let status: UserStatus

    // ドメインロジック
    var isActive: Bool {
        status == .active
    }

    func canPost() -> Bool {
        isActive && !isBanned()
    }

    private func isBanned() -> Bool {
        status == .banned
    }
}

enum UserStatus: String, Codable {
    case active
    case inactive
    case banned
}

/**
 * ユーザー詳細
 */
struct UserDetail: Equatable {
    let user: User
    let posts: [Post]
    let postCount: Int
}
```

---

## Data Layer

### Repository

```swift
import Foundation

/**
 * ユーザーリポジトリの Protocol
 *
 * Domain 層はこの Protocol に依存
 */
protocol UserRepositoryProtocol {
    func getUsers() async throws -> [User]
    func getUser(userId: String) async throws -> User
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws
    func deleteUser(userId: String) async throws

    // リアクティブなデータストリーム（Combine）
    var usersPublisher: AnyPublisher<[User], Never> { get }
}

/**
 * ユーザーリポジトリの実装
 *
 * オフラインファースト戦略を採用
 */
final class UserRepository: UserRepositoryProtocol {

    // MARK: - 非公開プロパティ

    private let localDataSource: UserLocalDataSourceProtocol
    private let remoteDataSource: UserRemoteDataSourceProtocol
    private let networkMonitor: NetworkMonitorProtocol

    private let usersSubject = CurrentValueSubject<[User], Never>([])

    // MARK: - 公開プロパティ

    var usersPublisher: AnyPublisher<[User], Never> {
        usersSubject.eraseToAnyPublisher()
    }

    // MARK: - 初期化

    init(
        localDataSource: UserLocalDataSourceProtocol,
        remoteDataSource: UserRemoteDataSourceProtocol,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.networkMonitor = networkMonitor
    }

    // MARK: - 公開関数

    /**
     * ユーザー一覧を取得
     *
     * オフラインファースト：
     * 1. まずローカルキャッシュを返す
     * 2. バックグラウンドでリモートから取得
     * 3. 取得したデータでローカルを更新
     */
    func getUsers() async throws -> [User] {
        // まずローカルから取得
        let localUsers = try await localDataSource.getUsers()
        usersSubject.send(localUsers.map { $0.toDomain() })

        // バックグラウンドでリモートから同期
        Task {
            await refreshUsersFromRemote()
        }

        return localUsers.map { $0.toDomain() }
    }

    /**
     * 単一ユーザーを取得
     */
    func getUser(userId: String) async throws -> User {
        // まずローカルから取得
        if let localUser = try? await localDataSource.getUser(userId: userId) {
            // バックグラウンドでリモートから同期
            Task {
                await refreshUserFromRemote(userId: userId)
            }
            return localUser.toDomain()
        }

        // ローカルになければリモートから取得
        let remoteUser = try await remoteDataSource.getUser(userId: userId)
        try await localDataSource.insertUser(remoteUser.toEntity())

        return remoteUser.toDomain()
    }

    /**
     * ユーザーを作成
     */
    func createUser(_ user: User) async throws -> User {
        // リモートに作成
        let response = try await remoteDataSource.createUser(user.toRequest())
        let createdUser = response.toDomain()

        // ローカルにキャッシュ
        try await localDataSource.insertUser(createdUser.toEntity())

        return createdUser
    }

    func updateUser(_ user: User) async throws {
        try await remoteDataSource.updateUser(userId: user.id, request: user.toRequest())
        try await localDataSource.insertUser(user.toEntity())
    }

    func deleteUser(userId: String) async throws {
        try await remoteDataSource.deleteUser(userId: userId)
        try await localDataSource.deleteUser(userId: userId)
    }

    // MARK: - 非公開関数

    /**
     * リモートからユーザー一覧を同期
     */
    private func refreshUsersFromRemote() async {
        guard networkMonitor.isConnected else { return }

        do {
            let remoteUsers = try await remoteDataSource.getUsers()
            try await localDataSource.replaceAllUsers(remoteUsers.map { $0.toEntity() })
            usersSubject.send(remoteUsers.map { $0.toDomain() })
        } catch {
            // ログ出力のみ、UI にはローカルデータを表示
            print("Failed to refresh users from remote: \(error)")
        }
    }

    private func refreshUserFromRemote(userId: String) async {
        guard networkMonitor.isConnected else { return }

        do {
            let remoteUser = try await remoteDataSource.getUser(userId: userId)
            try await localDataSource.insertUser(remoteUser.toEntity())
        } catch {
            print("Failed to refresh user from remote: \(userId), error: \(error)")
        }
    }
}
```

### Local DataSource (SwiftData / iOS 17+)

```swift
import Foundation
import SwiftData

/**
 * ユーザーローカルデータソース Protocol
 */
protocol UserLocalDataSourceProtocol {
    func getUsers() async throws -> [UserEntity]
    func getUser(userId: String) async throws -> UserEntity
    func insertUser(_ user: UserEntity) async throws
    func insertUsers(_ users: [UserEntity]) async throws
    func replaceAllUsers(_ users: [UserEntity]) async throws
    func deleteUser(userId: String) async throws
}

/**
 * SwiftData を使用したローカルデータソース
 */
@ModelActor
actor UserLocalDataSource: UserLocalDataSourceProtocol {

    func getUsers() async throws -> [UserEntity] {
        let descriptor = FetchDescriptor<UserEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getUser(userId: String) async throws -> UserEntity {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == userId }
        )
        guard let user = try modelContext.fetch(descriptor).first else {
            throw AppError.data(.notFound("User not found: \(userId)"))
        }
        return user
    }

    func insertUser(_ user: UserEntity) async throws {
        modelContext.insert(user)
        try modelContext.save()
    }

    func insertUsers(_ users: [UserEntity]) async throws {
        for user in users {
            modelContext.insert(user)
        }
        try modelContext.save()
    }

    func replaceAllUsers(_ users: [UserEntity]) async throws {
        try modelContext.delete(model: UserEntity.self)
        for user in users {
            modelContext.insert(user)
        }
        try modelContext.save()
    }

    func deleteUser(userId: String) async throws {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == userId }
        )
        if let user = try modelContext.fetch(descriptor).first {
            modelContext.delete(user)
            try modelContext.save()
        }
    }
}

/**
 * SwiftData Entity
 */
@Model
final class UserEntity {
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var joinedAt: Date
    var status: String

    init(
        id: String,
        name: String,
        email: String,
        joinedAt: Date,
        status: String
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.joinedAt = joinedAt
        self.status = status
    }
}
```

### Remote DataSource (URLSession)

```swift
import Foundation

/**
 * ユーザーリモートデータソース Protocol
 */
protocol UserRemoteDataSourceProtocol {
    func getUsers() async throws -> [UserResponse]
    func getUser(userId: String) async throws -> UserResponse
    func createUser(_ request: CreateUserRequest) async throws -> UserResponse
    func updateUser(userId: String, request: UpdateUserRequest) async throws -> UserResponse
    func deleteUser(userId: String) async throws
}

/**
 * URLSession を使用したリモートデータソース
 */
final class UserRemoteDataSource: UserRemoteDataSourceProtocol {

    // MARK: - 非公開プロパティ

    private let apiClient: APIClientProtocol

    // MARK: - 初期化

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - 公開関数

    func getUsers() async throws -> [UserResponse] {
        try await apiClient.request(
            endpoint: .users,
            method: .get
        )
    }

    func getUser(userId: String) async throws -> UserResponse {
        try await apiClient.request(
            endpoint: .user(id: userId),
            method: .get
        )
    }

    func createUser(_ request: CreateUserRequest) async throws -> UserResponse {
        try await apiClient.request(
            endpoint: .users,
            method: .post,
            body: request
        )
    }

    func updateUser(userId: String, request: UpdateUserRequest) async throws -> UserResponse {
        try await apiClient.request(
            endpoint: .user(id: userId),
            method: .put,
            body: request
        )
    }

    func deleteUser(userId: String) async throws {
        try await apiClient.requestVoid(
            endpoint: .user(id: userId),
            method: .delete
        )
    }
}

/**
 * API クライアント
 */
protocol APIClientProtocol {
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> T

    func requestVoid(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?
    ) async throws
}

extension APIClientProtocol {
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: method, body: body)
    }

    func requestVoid(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws {
        try await requestVoid(endpoint: endpoint, method: method, body: body)
    }
}

final class APIClient: APIClientProtocol {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder

        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: method, body: body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    func requestVoid(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?
    ) async throws {
        let request = try buildRequest(endpoint: endpoint, method: method, body: body)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    private func buildRequest(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.unknown)
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw AppError.auth(.unauthorized)
        case 404:
            throw AppError.data(.notFound())
        case 409:
            throw AppError.data(.conflict("Resource already exists"))
        case 500..<600:
            throw AppError.network(.server(code: httpResponse.statusCode))
        default:
            throw AppError.network(.unknown)
        }
    }
}

enum APIEndpoint {
    case users
    case user(id: String)

    var path: String {
        switch self {
        case .users:
            return "users"
        case .user(let id):
            return "users/\(id)"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/**
 * API レスポンスモデル
 */
struct UserResponse: Codable {
    let id: String
    let name: String
    let email: String
    let joinedAt: Date
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, name, email, status
        case joinedAt = "joined_at"
    }
}

struct CreateUserRequest: Encodable {
    let name: String
    let email: String
}

struct UpdateUserRequest: Encodable {
    let name: String
    let email: String
}
```

### Model Mapping

```swift
import Foundation

// MARK: - Entity ↔ Domain

extension UserEntity {
    /**
     * Entity → Domain
     */
    func toDomain() -> User {
        User(
            id: id,
            name: name,
            email: email,
            joinedAt: joinedAt,
            status: UserStatus(rawValue: status) ?? .inactive
        )
    }
}

extension User {
    /**
     * Domain → Entity
     */
    func toEntity() -> UserEntity {
        UserEntity(
            id: id,
            name: name,
            email: email,
            joinedAt: joinedAt,
            status: status.rawValue
        )
    }

    /**
     * Domain → Request
     */
    func toRequest() -> CreateUserRequest {
        CreateUserRequest(name: name, email: email)
    }
}

// MARK: - Response → Domain

extension UserResponse {
    /**
     * Response → Domain
     */
    func toDomain() -> User {
        User(
            id: id,
            name: name,
            email: email,
            joinedAt: joinedAt,
            status: UserStatus(rawValue: status.lowercased()) ?? .inactive
        )
    }

    /**
     * Response → Entity
     */
    func toEntity() -> UserEntity {
        UserEntity(
            id: id,
            name: name,
            email: email,
            joinedAt: joinedAt,
            status: status.lowercased()
        )
    }
}

// MARK: - Domain → UI

extension User {
    /**
     * Domain → UI Model
     */
    func toUiModel(dateFormatter: DateFormatter = .userJoinDate) -> UserUiModel {
        UserUiModel(
            id: id,
            displayName: name,
            avatarUrl: nil,
            formattedJoinDate: dateFormatter.string(from: joinedAt)
        )
    }
}

extension DateFormatter {
    static let userJoinDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}
```

---

## 依存性注入 (DI)

### Container パターン（シンプルな DI）

```swift
import Foundation
import SwiftData

/**
 * 依存性コンテナ
 *
 * シングルトンで依存オブジェクトを管理
 */
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - 非公開プロパティ

    private let modelContainer: ModelContainer
    private let apiClient: APIClientProtocol
    private let networkMonitor: NetworkMonitorProtocol

    // MARK: - キャッシュ済み依存

    private var cachedUserRepository: UserRepositoryProtocol?
    private var cachedAnalyticsRepository: AnalyticsRepositoryProtocol?

    // MARK: - 初期化

    private init() {
        // SwiftData ModelContainer
        do {
            modelContainer = try ModelContainer(for: UserEntity.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // API Client
        apiClient = APIClient(
            baseURL: URL(string: Configuration.apiBaseURL)!
        )

        // Network Monitor
        networkMonitor = NetworkMonitor()
    }

    // テスト用初期化
    init(
        modelContainer: ModelContainer,
        apiClient: APIClientProtocol,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.modelContainer = modelContainer
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
    }

    // MARK: - DataSource

    func makeUserLocalDataSource() -> UserLocalDataSourceProtocol {
        UserLocalDataSource(modelContainer: modelContainer)
    }

    func makeUserRemoteDataSource() -> UserRemoteDataSourceProtocol {
        UserRemoteDataSource(apiClient: apiClient)
    }

    // MARK: - Repository

    func makeUserRepository() -> UserRepositoryProtocol {
        if let cached = cachedUserRepository {
            return cached
        }

        let repository = UserRepository(
            localDataSource: makeUserLocalDataSource(),
            remoteDataSource: makeUserRemoteDataSource(),
            networkMonitor: networkMonitor
        )
        cachedUserRepository = repository
        return repository
    }

    func makeAnalyticsRepository() -> AnalyticsRepositoryProtocol {
        if let cached = cachedAnalyticsRepository {
            return cached
        }

        let repository = AnalyticsRepository()
        cachedAnalyticsRepository = repository
        return repository
    }

    // MARK: - UseCase

    func makeGetUsersUseCase() -> GetUsersUseCaseProtocol {
        GetUsersUseCase(
            userRepository: makeUserRepository(),
            analyticsRepository: makeAnalyticsRepository()
        )
    }

    // MARK: - ViewModel

    func makeUserListViewModel() -> UserListViewModel {
        UserListViewModel(
            getUsersUseCase: makeGetUsersUseCase()
        )
    }
}
```

### Environment を使用した DI（SwiftUI）

```swift
import SwiftUI

/**
 * 依存性を Environment 経由で注入
 */

// Environment Key
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

/**
 * App での使用例
 */
@main
struct MyApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, DependencyContainer.shared)
        }
    }
}

/**
 * View での使用例
 */
struct UserListScreenWrapper: View {

    @Environment(\.dependencies) private var dependencies

    var body: some View {
        UserListScreen(viewModel: dependencies.makeUserListViewModel())
    }
}
```

### Protocol-based DI（テスタビリティ重視）

```swift
import Foundation

/**
 * 依存性プロバイダー Protocol
 */
protocol DependencyProviding {
    // DataSource
    func userLocalDataSource() -> UserLocalDataSourceProtocol
    func userRemoteDataSource() -> UserRemoteDataSourceProtocol

    // Repository
    func userRepository() -> UserRepositoryProtocol
    func analyticsRepository() -> AnalyticsRepositoryProtocol

    // UseCase
    func getUsersUseCase() -> GetUsersUseCaseProtocol

    // ViewModel
    func userListViewModel() -> UserListViewModel
}

/**
 * 本番用実装
 */
final class ProductionDependencyProvider: DependencyProviding {

    private let container = DependencyContainer.shared

    func userLocalDataSource() -> UserLocalDataSourceProtocol {
        container.makeUserLocalDataSource()
    }

    func userRemoteDataSource() -> UserRemoteDataSourceProtocol {
        container.makeUserRemoteDataSource()
    }

    func userRepository() -> UserRepositoryProtocol {
        container.makeUserRepository()
    }

    func analyticsRepository() -> AnalyticsRepositoryProtocol {
        container.makeAnalyticsRepository()
    }

    func getUsersUseCase() -> GetUsersUseCaseProtocol {
        container.makeGetUsersUseCase()
    }

    func userListViewModel() -> UserListViewModel {
        container.makeUserListViewModel()
    }
}

/**
 * テスト用実装
 */
final class MockDependencyProvider: DependencyProviding {

    var mockUserLocalDataSource: UserLocalDataSourceProtocol?
    var mockUserRemoteDataSource: UserRemoteDataSourceProtocol?
    var mockUserRepository: UserRepositoryProtocol?
    var mockAnalyticsRepository: AnalyticsRepositoryProtocol?
    var mockGetUsersUseCase: GetUsersUseCaseProtocol?

    func userLocalDataSource() -> UserLocalDataSourceProtocol {
        mockUserLocalDataSource ?? FakeUserLocalDataSource()
    }

    func userRemoteDataSource() -> UserRemoteDataSourceProtocol {
        mockUserRemoteDataSource ?? FakeUserRemoteDataSource()
    }

    func userRepository() -> UserRepositoryProtocol {
        mockUserRepository ?? FakeUserRepository()
    }

    func analyticsRepository() -> AnalyticsRepositoryProtocol {
        mockAnalyticsRepository ?? FakeAnalyticsRepository()
    }

    func getUsersUseCase() -> GetUsersUseCaseProtocol {
        mockGetUsersUseCase ?? FakeGetUsersUseCase()
    }

    func userListViewModel() -> UserListViewModel {
        UserListViewModel(getUsersUseCase: getUsersUseCase())
    }
}
```

---

## 状態管理

### @Observable vs ObservableObject

| 特徴 | @Observable (iOS 17+) | ObservableObject (iOS 15+) |
|------|----------------------|---------------------------|
| 監視精度 | プロパティ単位 | オブジェクト全体 |
| パフォーマンス | 高い | 低い（不要な再描画が発生しやすい） |
| コード量 | 少ない | 多い（@Published が必要） |
| View 側の記述 | @State | @StateObject / @ObservedObject |

### 状態のスコープ

```swift
/**
 * 状態のスコープに応じた適切な管理方法
 */

// MARK: - 画面ローカル状態（View 内で完結）

struct SearchBar: View {

    // View 内のローカル状態
    @State private var searchText = ""

    let onSearch: (String) -> Void

    var body: some View {
        HStack {
            TextField("検索", text: $searchText)
            Button("検索") {
                onSearch(searchText)
            }
        }
    }
}

// MARK: - 画面状態（ViewModel で管理）

struct UserListScreen: View {

    // 画面の状態は ViewModel で管理
    @State private var viewModel: UserListViewModel

    var body: some View {
        UserListContent(uiState: viewModel.uiState, ...)
    }
}

// MARK: - アプリ全体の状態（共有オブジェクト）

@Observable
final class AppState {
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var theme: AppTheme = .system
}

@main
struct MyApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
```

### Binding パターン

```swift
/**
 * Binding を使った状態の共有
 */

struct ParentView: View {

    @State private var selectedItem: String?

    var body: some View {
        ChildView(selectedItem: $selectedItem)
    }
}

struct ChildView: View {

    @Binding var selectedItem: String?

    var body: some View {
        Button("選択") {
            selectedItem = "item-1"
        }
    }
}

/**
 * 読み取り専用の Binding
 */
extension Binding {
    static func readOnly(_ value: Value) -> Binding<Value> {
        Binding(
            get: { value },
            set: { _ in }
        )
    }
}
```

### Reducer パターン（複雑な状態管理）

```swift
/**
 * Reducer パターンによる状態管理
 *
 * 複雑な状態遷移を明示的に管理
 */

// Action
enum UserListAction {
    case loadUsers
    case loadUsersSuccess([User])
    case loadUsersFailure(Error)
    case selectUser(String)
    case refresh
}

// State
struct UserListState: Equatable {
    var users: [User] = []
    var isLoading: Bool = false
    var error: Error?
    var selectedUserId: String?

    static func == (lhs: UserListState, rhs: UserListState) -> Bool {
        lhs.users == rhs.users &&
        lhs.isLoading == rhs.isLoading &&
        lhs.selectedUserId == rhs.selectedUserId
    }
}

// Reducer
func userListReducer(state: inout UserListState, action: UserListAction) {
    switch action {
    case .loadUsers, .refresh:
        state.isLoading = true
        state.error = nil

    case .loadUsersSuccess(let users):
        state.users = users
        state.isLoading = false
        state.error = nil

    case .loadUsersFailure(let error):
        state.isLoading = false
        state.error = error

    case .selectUser(let userId):
        state.selectedUserId = userId
    }
}

// Store
@Observable
final class UserListStore {

    private(set) var state = UserListState()

    private let getUsersUseCase: GetUsersUseCaseProtocol

    init(getUsersUseCase: GetUsersUseCaseProtocol) {
        self.getUsersUseCase = getUsersUseCase
    }

    @MainActor
    func dispatch(_ action: UserListAction) async {
        userListReducer(state: &state, action: action)

        // 副作用の処理
        switch action {
        case .loadUsers, .refresh:
            do {
                let users = try await getUsersUseCase.execute()
                userListReducer(state: &state, action: .loadUsersSuccess(users))
            } catch {
                userListReducer(state: &state, action: .loadUsersFailure(error))
            }

        default:
            break
        }
    }
}
```

---

## 非同期処理 (async/await / Combine)

### async/await の基本

```swift
/**
 * async/await を使った非同期処理
 */

// 基本的な非同期関数
func fetchUser(id: String) async throws -> User {
    let response = try await apiClient.request(
        endpoint: .user(id: id),
        method: .get
    )
    return response.toDomain()
}

// 並列実行
func fetchUserDetail(userId: String) async throws -> UserDetail {
    async let user = userRepository.getUser(userId: userId)
    async let posts = postRepository.getPostsByUser(userId: userId)

    return try await UserDetail(
        user: user,
        posts: posts,
        postCount: posts.count
    )
}

// タイムアウト付き
func fetchWithTimeout<T>(
    timeout: Duration = .seconds(30),
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(for: timeout)
            throw AppError.network(.timeout)
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

### Task の管理

```swift
/**
 * Task の適切な管理
 */
@Observable
final class UserDetailViewModel {

    private(set) var uiState = UserDetailUiState()

    private let getUserDetailUseCase: GetUserDetailUseCase
    private var loadTask: Task<Void, Never>?

    init(getUserDetailUseCase: GetUserDetailUseCase) {
        self.getUserDetailUseCase = getUserDetailUseCase
    }

    deinit {
        // ViewModel 破棄時に Task をキャンセル
        loadTask?.cancel()
    }

    func loadUser(userId: String) {
        // 既存の Task をキャンセル
        loadTask?.cancel()

        loadTask = Task {
            await performLoadUser(userId: userId)
        }
    }

    @MainActor
    private func performLoadUser(userId: String) async {
        uiState = uiState.copy(isLoading: true)

        do {
            let userDetail = try await getUserDetailUseCase.execute(userId: userId)

            // キャンセルチェック
            guard !Task.isCancelled else { return }

            uiState = uiState.copy(
                userDetail: userDetail,
                isLoading: false
            )
        } catch is CancellationError {
            // キャンセルは無視
            return
        } catch {
            uiState = uiState.copy(
                isLoading: false,
                error: error.toUiError()
            )
        }
    }
}
```

### Combine との併用

```swift
import Combine

/**
 * Combine を使ったリアクティブなデータストリーム
 */

// Publisher を使ったリアルタイム更新
protocol UserRepositoryProtocol {
    // 単発の取得
    func getUsers() async throws -> [User]

    // リアルタイムストリーム
    var usersPublisher: AnyPublisher<[User], Never> { get }
}

// View での使用
struct UserListScreen: View {

    @State private var viewModel: UserListViewModel
    @State private var users: [User] = []

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .onReceive(viewModel.usersPublisher) { users in
            self.users = users
        }
    }
}

/**
 * async/await と Combine の変換
 */
extension Publisher where Failure == Never {

    // Publisher → AsyncStream
    func values() -> AsyncStream<Output> {
        AsyncStream { continuation in
            let cancellable = self.sink { value in
                continuation.yield(value)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

extension AsyncSequence {

    // AsyncSequence → Publisher
    func publisher() -> AnyPublisher<Element, Error> {
        let subject = PassthroughSubject<Element, Error>()

        Task {
            do {
                for try await element in self {
                    subject.send(element)
                }
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }

        return subject.eraseToAnyPublisher()
    }
}
```

### AsyncSequence の活用

```swift
/**
 * AsyncSequence を使った連続データ処理
 */

// ページネーション
struct PaginatedUsers: AsyncSequence {

    typealias Element = [User]

    let repository: UserRepositoryProtocol
    let pageSize: Int

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(repository: repository, pageSize: pageSize)
    }

    struct AsyncIterator: AsyncIteratorProtocol {

        let repository: UserRepositoryProtocol
        let pageSize: Int
        var currentPage = 0
        var hasMore = true

        mutating func next() async throws -> [User]? {
            guard hasMore else { return nil }

            let users = try await repository.getUsers(
                page: currentPage,
                size: pageSize
            )

            hasMore = users.count == pageSize
            currentPage += 1

            return users.isEmpty ? nil : users
        }
    }
}

// 使用例
func loadAllUsers() async throws -> [User] {
    var allUsers: [User] = []

    for try await users in PaginatedUsers(
        repository: userRepository,
        pageSize: 20
    ) {
        allUsers.append(contentsOf: users)
    }

    return allUsers
}
```

---

## エラーハンドリング

### エラー型の階層

```swift
import Foundation

/**
 * アプリケーションエラーの階層
 */
enum AppError: Error, Equatable {

    // ネットワークエラー
    case network(NetworkError)

    // データエラー
    case data(DataError)

    // 認証エラー
    case auth(AuthError)

    // 不明なエラー
    case unknown(String)

    enum NetworkError: Equatable {
        case noConnection
        case timeout
        case server(code: Int)
        case unknown
    }

    enum DataError: Equatable {
        case notFound(String = "Data not found")
        case validation(String)
        case conflict(String)
    }

    enum AuthError: Equatable {
        case unauthorized
        case sessionExpired
    }
}

extension AppError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .network(.noConnection):
            return "インターネット接続がありません"
        case .network(.timeout):
            return "リクエストがタイムアウトしました"
        case .network(.server(let code)):
            return "サーバーエラー（\(code)）"
        case .network(.unknown):
            return "通信エラーが発生しました"
        case .data(.notFound(let message)):
            return message
        case .data(.validation(let message)):
            return message
        case .data(.conflict(let message)):
            return message
        case .auth(.unauthorized):
            return "認証が必要です"
        case .auth(.sessionExpired):
            return "セッションの有効期限が切れました"
        case .unknown(let message):
            return message
        }
    }
}
```

### Result 型の活用

```swift
/**
 * Result 型を使ったエラーハンドリング
 */

// 成功/失敗を明示的に表現
typealias AppResult<T> = Result<T, AppError>

extension Result where Failure == AppError {

    // 成功時の値を取得（失敗時は nil）
    var success: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    // 失敗時のエラーを取得（成功時は nil）
    var failure: AppError? {
        guard case .failure(let error) = self else { return nil }
        return error
    }

    // map のショートハンド
    func mapSuccess<T>(_ transform: (Success) -> T) -> Result<T, AppError> {
        map(transform)
    }
}

// Repository での使用
func createUser(_ user: User) async -> AppResult<User> {
    do {
        let response = try await remoteDataSource.createUser(user.toRequest())
        let createdUser = response.toDomain()
        try await localDataSource.insertUser(createdUser.toEntity())
        return .success(createdUser)
    } catch let error as AppError {
        return .failure(error)
    } catch {
        return .failure(.unknown(error.localizedDescription))
    }
}

// ViewModel での使用
func createUser(_ user: User) async {
    uiState = uiState.copy(isLoading: true)

    let result = await userRepository.createUser(user)

    switch result {
    case .success(let createdUser):
        uiState = uiState.copy(
            user: createdUser.toUiModel(),
            isLoading: false
        )
    case .failure(let error):
        uiState = uiState.copy(
            isLoading: false,
            error: error.toUiError()
        )
    }
}
```

### UI エラーモデル

```swift
/**
 * UI 用エラーモデル
 */
struct UiError: Equatable {
    let message: String
    let action: ErrorAction?

    init(message: String, action: ErrorAction? = nil) {
        self.message = message
        self.action = action
    }
}

enum ErrorAction: Equatable {
    case retry
    case login
    case dismiss
}

/**
 * Error → UiError 変換
 */
extension Error {

    func toUiError() -> UiError {
        if let appError = self as? AppError {
            return appError.toUiError()
        }
        return UiError(message: localizedDescription, action: .dismiss)
    }
}

extension AppError {

    func toUiError() -> UiError {
        switch self {
        case .network(.noConnection):
            return UiError(
                message: "インターネット接続がありません",
                action: .retry
            )
        case .network(.timeout):
            return UiError(
                message: "リクエストがタイムアウトしました",
                action: .retry
            )
        case .network(.server):
            return UiError(
                message: "サーバーエラーが発生しました",
                action: .retry
            )
        case .auth(.unauthorized), .auth(.sessionExpired):
            return UiError(
                message: "ログインが必要です",
                action: .login
            )
        default:
            return UiError(
                message: errorDescription ?? "エラーが発生しました",
                action: .dismiss
            )
        }
    }
}
```

### エラー表示コンポーネント

```swift
/**
 * エラー表示 View
 */
struct ErrorContent: View {

    let error: UiError
    let onRetryTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(error.message)
                .font(.headline)
                .multilineTextAlignment(.center)

            if error.action == .retry {
                Button("再試行") {
                    onRetryTap()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

/**
 * Alert 用 Modifier
 */
extension View {

    func errorAlert(
        error: Binding<UiError?>,
        onRetry: @escaping () -> Void = {}
    ) -> some View {
        alert(
            "エラー",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { uiError in
            if uiError.action == .retry {
                Button("再試行") { onRetry() }
            }
            Button("OK", role: .cancel) {}
        } message: { uiError in
            Text(uiError.message)
        }
    }
}
```

---

## テスト戦略

### テストピラミッド

```
         ┌─────────┐
         │   E2E   │  ← 少数の重要フロー
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository、ViewModel のテスト
         │  tion   │
         ├─────────┤
         │  Unit   │  ← UseCase、Domain Model のテスト
         │  Tests  │     最も多く書く
         └─────────┘
```

### Unit Test

```swift
import XCTest
@testable import MyApp

/**
 * UseCase のユニットテスト
 */
final class GetUsersUseCaseTests: XCTestCase {

    // MARK: - プロパティ

    private var sut: GetUsersUseCase!
    private var fakeUserRepository: FakeUserRepository!
    private var fakeAnalyticsRepository: FakeAnalyticsRepository!

    // MARK: - セットアップ

    override func setUp() {
        super.setUp()
        fakeUserRepository = FakeUserRepository()
        fakeAnalyticsRepository = FakeAnalyticsRepository()
        sut = GetUsersUseCase(
            userRepository: fakeUserRepository,
            analyticsRepository: fakeAnalyticsRepository
        )
    }

    override func tearDown() {
        sut = nil
        fakeUserRepository = nil
        fakeAnalyticsRepository = nil
        super.tearDown()
    }

    // MARK: - テスト

    func test_execute_returnsUsersFromRepository() async throws {
        // Given
        let expectedUsers = [
            User.stub(id: "1", name: "Alice"),
            User.stub(id: "2", name: "Bob")
        ]
        fakeUserRepository.stubbedUsers = expectedUsers

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, expectedUsers)
    }

    func test_execute_logsAnalytics() async throws {
        // Given
        let users = [User.stub(), User.stub()]
        fakeUserRepository.stubbedUsers = users

        // When
        _ = try await sut.execute()

        // Then
        XCTAssertEqual(fakeAnalyticsRepository.loggedUserListViewedCount, 2)
    }

    func test_execute_throwsError_whenRepositoryFails() async {
        // Given
        fakeUserRepository.stubbedError = AppError.network(.noConnection)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, .network(.noConnection))
        }
    }
}
```

### ViewModel Test

```swift
import XCTest
@testable import MyApp

/**
 * ViewModel のテスト
 */
@MainActor
final class UserListViewModelTests: XCTestCase {

    // MARK: - プロパティ

    private var sut: UserListViewModel!
    private var fakeGetUsersUseCase: FakeGetUsersUseCase!

    // MARK: - セットアップ

    override func setUp() {
        super.setUp()
        fakeGetUsersUseCase = FakeGetUsersUseCase()
        sut = UserListViewModel(getUsersUseCase: fakeGetUsersUseCase)
    }

    override func tearDown() {
        sut = nil
        fakeGetUsersUseCase = nil
        super.tearDown()
    }

    // MARK: - テスト

    func test_initialState_isNotLoading() {
        // Then
        XCTAssertFalse(sut.uiState.isLoading)
        XCTAssertTrue(sut.uiState.users.isEmpty)
        XCTAssertNil(sut.uiState.error)
    }

    func test_loadUsers_setsLoadingState() async {
        // Given
        fakeGetUsersUseCase.delay = 0.1
        fakeGetUsersUseCase.stubbedUsers = [User.stub()]

        // When
        sut.loadUsers()

        // Then（すぐにローディング状態になる）
        // 注: @Observable の更新は同期的なので、Task 開始直後に確認
        try? await Task.sleep(for: .milliseconds(10))
        XCTAssertTrue(sut.uiState.isLoading)
    }

    func test_loadUsers_success_updatesUsers() async {
        // Given
        let expectedUsers = [
            User.stub(id: "1", name: "Alice"),
            User.stub(id: "2", name: "Bob")
        ]
        fakeGetUsersUseCase.stubbedUsers = expectedUsers

        // When
        sut.loadUsers()

        // 非同期処理の完了を待つ
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertFalse(sut.uiState.isLoading)
        XCTAssertEqual(sut.uiState.users.count, 2)
        XCTAssertEqual(sut.uiState.users[0].displayName, "Alice")
    }

    func test_loadUsers_failure_setsError() async {
        // Given
        fakeGetUsersUseCase.stubbedError = AppError.network(.noConnection)

        // When
        sut.loadUsers()
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertFalse(sut.uiState.isLoading)
        XCTAssertNotNil(sut.uiState.error)
    }

    func test_onUserTap_setsNavigationEvent() {
        // When
        sut.onUserTap("user-123")

        // Then
        XCTAssertEqual(sut.navigationEvent, .detail(userId: "user-123"))
    }

    func test_consumeNavigationEvent_clearsEvent() {
        // Given
        sut.onUserTap("user-123")

        // When
        sut.consumeNavigationEvent()

        // Then
        XCTAssertNil(sut.navigationEvent)
    }
}
```

### Fake / Stub の作成

```swift
/**
 * Fake Repository（状態を持つテスト用実装）
 */
final class FakeUserRepository: UserRepositoryProtocol {

    // MARK: - Stubs

    var stubbedUsers: [User] = []
    var stubbedError: AppError?

    // MARK: - Call Tracking

    private(set) var getUsersCallCount = 0
    private(set) var createUserCalls: [User] = []

    // MARK: - Protocol

    var usersPublisher: AnyPublisher<[User], Never> {
        Just(stubbedUsers).eraseToAnyPublisher()
    }

    func getUsers() async throws -> [User] {
        getUsersCallCount += 1

        if let error = stubbedError {
            throw error
        }
        return stubbedUsers
    }

    func getUser(userId: String) async throws -> User {
        if let error = stubbedError {
            throw error
        }
        guard let user = stubbedUsers.first(where: { $0.id == userId }) else {
            throw AppError.data(.notFound("User not found: \(userId)"))
        }
        return user
    }

    func createUser(_ user: User) async throws -> User {
        createUserCalls.append(user)

        if let error = stubbedError {
            throw error
        }
        stubbedUsers.append(user)
        return user
    }

    func updateUser(_ user: User) async throws {
        if let error = stubbedError {
            throw error
        }
    }

    func deleteUser(userId: String) async throws {
        if let error = stubbedError {
            throw error
        }
        stubbedUsers.removeAll { $0.id == userId }
    }
}

/**
 * Fake UseCase
 */
final class FakeGetUsersUseCase: GetUsersUseCaseProtocol {

    var stubbedUsers: [User] = []
    var stubbedError: AppError?
    var delay: TimeInterval = 0

    func execute() async throws -> [User] {
        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }

        if let error = stubbedError {
            throw error
        }
        return stubbedUsers
    }
}

/**
 * テスト用スタブ生成
 */
extension User {

    static func stub(
        id: String = UUID().uuidString,
        name: String = "Test User",
        email: String = "test@example.com",
        joinedAt: Date = Date(),
        status: UserStatus = .active
    ) -> User {
        User(
            id: id,
            name: name,
            email: email,
            joinedAt: joinedAt,
            status: status
        )
    }
}
```

### SwiftUI Preview Test

```swift
import XCTest
import SwiftUI
@testable import MyApp

/**
 * SwiftUI スナップショットテスト
 */
final class UserListContentSnapshotTests: XCTestCase {

    func test_loadingState() {
        let view = UserListContent(
            uiState: UserListUiState(isLoading: true),
            onUserTap: { _ in },
            onRetryTap: {}
        )

        // スナップショットライブラリを使用して比較
        // assertSnapshot(matching: view, as: .image)
    }

    func test_contentState() {
        let view = UserListContent(
            uiState: UserListUiState(
                users: [
                    UserUiModel(
                        id: "1",
                        displayName: "Alice",
                        avatarUrl: nil,
                        formattedJoinDate: "2024/01/01"
                    )
                ]
            ),
            onUserTap: { _ in },
            onRetryTap: {}
        )

        // assertSnapshot(matching: view, as: .image)
    }

    func test_errorState() {
        let view = UserListContent(
            uiState: UserListUiState(
                error: UiError(
                    message: "エラーが発生しました",
                    action: .retry
                )
            ),
            onUserTap: { _ in },
            onRetryTap: {}
        )

        // assertSnapshot(matching: view, as: .image)
    }
}
```

---

## ディレクトリ構造

### Feature-based 構造（推奨）

```
MyApp/
├── App/
│   ├── MyApp.swift                    # @main App
│   ├── ContentView.swift
│   └── Configuration.swift            # 環境設定
│
├── Core/                              # 共通コンポーネント
│   ├── Data/
│   │   ├── Network/
│   │   │   ├── APIClient.swift
│   │   │   ├── APIEndpoint.swift
│   │   │   └── NetworkMonitor.swift
│   │   └── Database/
│   │       └── ModelContainer+.swift
│   │
│   ├── DI/
│   │   └── DependencyContainer.swift
│   │
│   ├── Domain/
│   │   └── Model/
│   │       └── AppError.swift
│   │
│   ├── UI/
│   │   ├── Component/
│   │   │   ├── LoadingView.swift
│   │   │   ├── ErrorContent.swift
│   │   │   └── EmptyContent.swift
│   │   ├── Theme/
│   │   │   ├── Color+.swift
│   │   │   └── Font+.swift
│   │   └── Modifier/
│   │       └── ErrorAlert.swift
│   │
│   └── Util/
│       ├── DateFormatter+.swift
│       └── Extensions.swift
│
├── Feature/                           # 機能モジュール
│   │
│   ├── User/                          # ユーザー機能
│   │   ├── Data/
│   │   │   ├── Local/
│   │   │   │   ├── UserEntity.swift
│   │   │   │   └── UserLocalDataSource.swift
│   │   │   ├── Remote/
│   │   │   │   ├── UserResponse.swift
│   │   │   │   ├── UserRequest.swift
│   │   │   │   └── UserRemoteDataSource.swift
│   │   │   ├── Repository/
│   │   │   │   └── UserRepository.swift
│   │   │   └── Mapper/
│   │   │       └── UserMapper.swift
│   │   │
│   │   ├── Domain/
│   │   │   ├── Model/
│   │   │   │   └── User.swift
│   │   │   ├── Repository/
│   │   │   │   └── UserRepositoryProtocol.swift
│   │   │   └── UseCase/
│   │   │       ├── GetUsersUseCase.swift
│   │   │       └── GetUserDetailUseCase.swift
│   │   │
│   │   └── UI/
│   │       ├── List/
│   │       │   ├── UserListScreen.swift
│   │       │   ├── UserListViewModel.swift
│   │       │   └── UserListUiState.swift
│   │       ├── Detail/
│   │       │   ├── UserDetailScreen.swift
│   │       │   ├── UserDetailViewModel.swift
│   │       │   └── UserDetailUiState.swift
│   │       └── Component/
│   │           └── UserCard.swift
│   │
│   ├── Auth/                          # 認証機能
│   │   ├── Data/
│   │   ├── Domain/
│   │   └── UI/
│   │
│   └── Settings/                      # 設定機能
│       ├── Data/
│       ├── Domain/
│       └── UI/
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
│
└── Tests/
    ├── UnitTests/
    │   ├── Core/
    │   └── Feature/
    │       └── User/
    │           ├── Data/
    │           ├── Domain/
    │           └── UI/
    │
    └── UITests/
```

---

## 命名規則

### ファイル・クラス命名

| 種類 | サフィックス | 例 |
|------|-------------|-----|
| SwiftUI View | Screen / View | `UserListScreen`, `UserCard` |
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Protocol | RepositoryProtocol | `UserRepositoryProtocol` |
| Repository 実装 | Repository | `UserRepository` |
| DataSource Protocol | DataSourceProtocol | `UserLocalDataSourceProtocol` |
| DataSource 実装 | DataSource | `UserLocalDataSource` |
| SwiftData Entity | Entity | `UserEntity` |
| API Response | Response | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Navigation Event | NavigationEvent | `UserListNavigationEvent` |

### 関数命名

| 種類 | パターン | 例 |
|------|---------|-----|
| データ取得（単一） | `get{Entity}` | `getUser(userId:)` |
| データ取得（複数） | `get{Entity}s` | `getUsers()` |
| データ作成 | `create{Entity}` / `insert{Entity}` | `createUser(_:)` |
| データ更新 | `update{Entity}` | `updateUser(_:)` |
| データ削除 | `delete{Entity}` | `deleteUser(userId:)` |
| イベントハンドラ | `on{Event}Tap` / `on{Event}` | `onUserTap(_:)` |
| 変換 | `to{Target}` | `toDomain()`, `toEntity()` |
| 検証 | `is{Condition}` / `has{Property}` | `isValid`, `hasPermission` |
| UseCase 実行 | `execute` | `execute()`, `execute(userId:)` |

### 変数命名

| 種類 | パターン | 例 |
|------|---------|-----|
| Boolean | `is{State}` / `has{Property}` / `should{Action}` | `isLoading`, `hasError`, `shouldRefresh` |
| Collection | 複数形 | `users`, `posts` |
| Optional | 必要に応じて説明的に | `selectedUser`, `error` |
| Closure | `on{Event}` | `onTap`, `onComplete` |
| Publisher | `{name}Publisher` | `usersPublisher` |

---

## ベストプラクティス一覧

### ViewModel

- [ ] UI State は単一の構造体で管理
- [ ] 状態は `private(set)` で読み取り専用公開
- [ ] ナビゲーションイベントは別プロパティで管理
- [ ] Task のキャンセル処理を実装
- [ ] `@MainActor` で UI 更新を保証

### Repository

- [ ] Protocol を定義し、実装と分離
- [ ] オフラインファースト戦略の採用
- [ ] async/await でデータ取得
- [ ] Combine Publisher でリアルタイム更新
- [ ] DataSource の詳細を隠蔽

### UseCase

- [ ] 単一責任（1 UseCase = 1 機能）
- [ ] Protocol を定義してテスタビリティ確保
- [ ] 必要な場合のみ作成（シンプルな場合は Repository 直接可）
- [ ] ビジネスロジックのみ、UI ロジックは含めない

### SwiftUI

- [ ] View と ViewModel を分離
- [ ] Stateless / Stateful View を明確に区別
- [ ] Preview を活用した開発
- [ ] `.task` で非同期処理を開始
- [ ] 再描画の最適化（@Observable の活用）

### 依存性注入

- [ ] Protocol を通じて依存性を注入
- [ ] DependencyContainer でライフサイクル管理
- [ ] テスト用の Fake/Mock を容易に差し替え可能
- [ ] Environment を活用した SwiftUI 統合

### テスト

- [ ] UseCase、ViewModel のユニットテスト必須
- [ ] Fake を優先、Mock は最小限
- [ ] `@MainActor` でテスト実行
- [ ] async/await でテストを記述

### エラーハンドリング

- [ ] アプリケーションエラーの階層を定義
- [ ] Repository でエラーをラップ
- [ ] UI 用エラーモデルに変換
- [ ] リトライ機構の実装

### パフォーマンス

- [ ] `@Observable` で最小限の再描画（iOS 17+）
- [ ] Task のキャンセル処理
- [ ] 大量データは AsyncSequence でストリーミング
- [ ] LazyVStack / LazyHStack の活用

---

## 参考リンク

- [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Observation Framework](https://developer.apple.com/documentation/observation)
- [WWDC23 - Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [WWDC23 - Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
