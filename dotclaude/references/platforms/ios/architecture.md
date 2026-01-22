# iOS Architecture Guide

Best practices for SwiftUI + MVVM / State management based on Apple's official guidelines.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Layer Structure](#layer-structure)
3. [Presentation Layer](#presentation-layer)
4. [Domain Layer](#domain-layer)
5. [Data Layer](#data-layer)
6. [Dependency Injection (DI)](#dependency-injection-di)
7. [State Management](#state-management)
8. [Async Processing (async/await / Combine)](#async-processing-asyncawait--combine)
9. [Error Handling](#error-handling)
10. [Testing Strategy](#testing-strategy)
11. [Directory Structure](#directory-structure)
12. [Naming Conventions](#naming-conventions)
13. [Best Practices Checklist](#best-practices-checklist)

---

## Architecture Overview

### Core Principles

1. **Separation of Concerns**
   - Clearly separate UI logic from business logic
   - Each layer has a single responsibility

2. **Data-driven UI**
   - UI only reflects state
   - State changes are made through ViewModel

3. **Single Source of Truth (SSOT)**
   - Data is managed in one place, others retrieve from there
   - Repository becomes the SSOT for data

4. **Unidirectional Data Flow (UDF)**
   - Events flow upstream (View → ViewModel → Repository)
   - State flows downstream (Repository → ViewModel → View)

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
│  │  - Encapsulate complex business logic                │   │
│  │  - Combine multiple Repositories                     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Repository                         │   │
│  │  - Abstract data access                              │   │
│  │  - Caching strategy                                  │   │
│  │  - Offline support                                   │   │
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

## Layer Structure

### Dependency Direction

```
Presentation Layer → Domain Layer → Data Layer
```

- Upper layers depend on lower layers
- Lower layers don't know about upper layers
- Invert dependencies through Protocols (DIP)

### Layer Responsibilities

| Layer | Responsibility | Main Components |
|-------|----------------|-----------------|
| Presentation | Screen display / User interaction | View (SwiftUI), ViewModel |
| Domain | Business logic | UseCase, Domain Model |
| Data | Data retrieval / Persistence | Repository, DataSource, API |

---

## Presentation Layer

### ViewModel (iOS 17+ @Observable)

```swift
import SwiftUI
import Observation

/**
 * ViewModel for User List Screen
 *
 * Responsible for UI state management and business logic calls
 */
@Observable
final class UserListViewModel {

    // MARK: - Public Properties

    // UI State
    private(set) var uiState = UserListUiState()

    // Temporary events (navigation, alerts, etc.)
    private(set) var navigationEvent: UserListNavigationEvent?

    // MARK: - Private Properties

    private let getUsersUseCase: GetUsersUseCaseProtocol
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(getUsersUseCase: GetUsersUseCaseProtocol) {
        self.getUsersUseCase = getUsersUseCase
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public Functions

    /**
     * Load user list
     */
    func loadUsers() {
        loadTask?.cancel()
        loadTask = Task {
            await performLoadUsers()
        }
    }

    /**
     * Select a user
     */
    func onUserTap(_ userId: String) {
        navigationEvent = .detail(userId: userId)
    }

    /**
     * Consume navigation event
     */
    func consumeNavigationEvent() {
        navigationEvent = nil
    }

    /**
     * Retry
     */
    func onRetryTap() {
        loadUsers()
    }

    // MARK: - Private Functions

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

### ViewModel (iOS 15-16 ObservableObject)

```swift
import SwiftUI
import Combine

/**
 * ViewModel for User List Screen (iOS 15-16 compatible)
 */
final class UserListViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var uiState = UserListUiState()
    @Published private(set) var navigationEvent: UserListNavigationEvent?

    // MARK: - Private Properties

    private let getUsersUseCase: GetUsersUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(getUsersUseCase: GetUsersUseCaseProtocol) {
        self.getUsersUseCase = getUsersUseCase
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public Functions

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
 * UI state for User List Screen
 *
 * Represent state with immutable struct
 */
struct UserListUiState: Equatable {

    // MARK: - Properties

    let users: [UserUiModel]
    let isLoading: Bool
    let error: UiError?

    // MARK: - Derived Properties

    var isEmpty: Bool {
        users.isEmpty && !isLoading && error == nil
    }

    var showEmptyState: Bool {
        isEmpty
    }

    var showContent: Bool {
        !users.isEmpty
    }

    // MARK: - Initialization

    init(
        users: [UserUiModel] = [],
        isLoading: Bool = false,
        error: UiError? = nil
    ) {
        self.users = users
        self.isLoading = isLoading
        self.error = error
    }

    // MARK: - Copy Function

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
 * User model for UI layer
 */
struct UserUiModel: Equatable, Identifiable {
    let id: String
    let displayName: String
    let avatarUrl: URL?
    let formattedJoinDate: String
}

/**
 * Navigation events
 */
enum UserListNavigationEvent: Equatable {
    case detail(userId: String)
}
```

### SwiftUI View

```swift
import SwiftUI

/**
 * User List Screen
 */
struct UserListScreen: View {

    // MARK: - Properties

    // iOS 17+: @State, iOS 15-16: @StateObject
    @State private var viewModel: UserListViewModel
    @State private var navigationPath = NavigationPath()

    // MARK: - Initialization

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
            .navigationTitle("User List")
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

    // MARK: - Private Functions

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
 * User List Content (previewable)
 */
struct UserListContent: View {

    // MARK: - Properties

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
 * User List
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
 * Previews
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
                message: "A communication error occurred",
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
 * UseCase Protocol for getting user list
 */
protocol GetUsersUseCaseProtocol {
    func execute() async throws -> [User]
}

/**
 * UseCase for getting user list
 *
 * Encapsulates single business logic
 */
final class GetUsersUseCase: GetUsersUseCaseProtocol {

    // MARK: - Private Properties

    private let userRepository: UserRepositoryProtocol
    private let analyticsRepository: AnalyticsRepositoryProtocol

    // MARK: - Initialization

    init(
        userRepository: UserRepositoryProtocol,
        analyticsRepository: AnalyticsRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Public Functions

    /**
     * Get user list
     */
    func execute() async throws -> [User] {
        let users = try await userRepository.getUsers()

        // Side effects (analytics, etc.)
        await analyticsRepository.logUserListViewed(count: users.count)

        return users
    }
}

/**
 * UseCase for getting user detail
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
     * Get user detail and posts
     *
     * Example of combining multiple Repositories
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
 * Domain model (contains business logic)
 */
struct User: Equatable, Identifiable {
    let id: String
    let name: String
    let email: String
    let joinedAt: Date
    let status: UserStatus

    // Domain logic
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
 * User Detail
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
 * User Repository Protocol
 *
 * Domain layer depends on this Protocol
 */
protocol UserRepositoryProtocol {
    func getUsers() async throws -> [User]
    func getUser(userId: String) async throws -> User
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws
    func deleteUser(userId: String) async throws

    // Reactive data stream (Combine)
    var usersPublisher: AnyPublisher<[User], Never> { get }
}

/**
 * User Repository implementation
 *
 * Adopts offline-first strategy
 */
final class UserRepository: UserRepositoryProtocol {

    // MARK: - Private Properties

    private let localDataSource: UserLocalDataSourceProtocol
    private let remoteDataSource: UserRemoteDataSourceProtocol
    private let networkMonitor: NetworkMonitorProtocol

    private let usersSubject = CurrentValueSubject<[User], Never>([])

    // MARK: - Public Properties

    var usersPublisher: AnyPublisher<[User], Never> {
        usersSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(
        localDataSource: UserLocalDataSourceProtocol,
        remoteDataSource: UserRemoteDataSourceProtocol,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.networkMonitor = networkMonitor
    }

    // MARK: - Public Functions

    /**
     * Get user list
     *
     * Offline-first:
     * 1. First return local cache
     * 2. Fetch from remote in background
     * 3. Update local with fetched data
     */
    func getUsers() async throws -> [User] {
        // First get from local
        let localUsers = try await localDataSource.getUsers()
        usersSubject.send(localUsers.map { $0.toDomain() })

        // Sync from remote in background
        Task {
            await refreshUsersFromRemote()
        }

        return localUsers.map { $0.toDomain() }
    }

    /**
     * Get single user
     */
    func getUser(userId: String) async throws -> User {
        // First get from local
        if let localUser = try? await localDataSource.getUser(userId: userId) {
            // Sync from remote in background
            Task {
                await refreshUserFromRemote(userId: userId)
            }
            return localUser.toDomain()
        }

        // If not in local, get from remote
        let remoteUser = try await remoteDataSource.getUser(userId: userId)
        try await localDataSource.insertUser(remoteUser.toEntity())

        return remoteUser.toDomain()
    }

    /**
     * Create user
     */
    func createUser(_ user: User) async throws -> User {
        // Create on remote
        let response = try await remoteDataSource.createUser(user.toRequest())
        let createdUser = response.toDomain()

        // Cache locally
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

    // MARK: - Private Functions

    /**
     * Sync user list from remote
     */
    private func refreshUsersFromRemote() async {
        guard networkMonitor.isConnected else { return }

        do {
            let remoteUsers = try await remoteDataSource.getUsers()
            try await localDataSource.replaceAllUsers(remoteUsers.map { $0.toEntity() })
            usersSubject.send(remoteUsers.map { $0.toDomain() })
        } catch {
            // Log only, show local data to UI
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
 * User Local DataSource Protocol
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
 * Local DataSource using SwiftData
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
 * User Remote DataSource Protocol
 */
protocol UserRemoteDataSourceProtocol {
    func getUsers() async throws -> [UserResponse]
    func getUser(userId: String) async throws -> UserResponse
    func createUser(_ request: CreateUserRequest) async throws -> UserResponse
    func updateUser(userId: String, request: UpdateUserRequest) async throws -> UserResponse
    func deleteUser(userId: String) async throws
}

/**
 * Remote DataSource using URLSession
 */
final class UserRemoteDataSource: UserRemoteDataSourceProtocol {

    // MARK: - Private Properties

    private let apiClient: APIClientProtocol

    // MARK: - Initialization

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Public Functions

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
 * API Client
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
 * API Response model
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
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
```

---

## Dependency Injection (DI)

### Container Pattern (Simple DI)

```swift
import Foundation
import SwiftData

/**
 * Dependency Container
 *
 * Manage dependency objects as singleton
 */
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Private Properties

    private let modelContainer: ModelContainer
    private let apiClient: APIClientProtocol
    private let networkMonitor: NetworkMonitorProtocol

    // MARK: - Cached Dependencies

    private var cachedUserRepository: UserRepositoryProtocol?
    private var cachedAnalyticsRepository: AnalyticsRepositoryProtocol?

    // MARK: - Initialization

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

    // Initialization for testing
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

### DI using Environment (SwiftUI)

```swift
import SwiftUI

/**
 * Inject dependencies via Environment
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
 * Usage example in App
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
 * Usage example in View
 */
struct UserListScreenWrapper: View {

    @Environment(\.dependencies) private var dependencies

    var body: some View {
        UserListScreen(viewModel: dependencies.makeUserListViewModel())
    }
}
```

### Protocol-based DI (Testability focused)

```swift
import Foundation

/**
 * Dependency Provider Protocol
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
 * Production implementation
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
 * Test implementation
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

## State Management

### @Observable vs ObservableObject

| Feature | @Observable (iOS 17+) | ObservableObject (iOS 15+) |
|---------|----------------------|---------------------------|
| Observation granularity | Property level | Entire object |
| Performance | High | Low (prone to unnecessary redraws) |
| Code amount | Less | More (@Published required) |
| View side notation | @State | @StateObject / @ObservedObject |

### State Scope

```swift
/**
 * Appropriate management based on state scope
 */

// MARK: - Screen Local State (contained within View)

struct SearchBar: View {

    // Local state within View
    @State private var searchText = ""

    let onSearch: (String) -> Void

    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
            Button("Search") {
                onSearch(searchText)
            }
        }
    }
}

// MARK: - Screen State (managed by ViewModel)

struct UserListScreen: View {

    // Screen state managed by ViewModel
    @State private var viewModel: UserListViewModel

    var body: some View {
        UserListContent(uiState: viewModel.uiState, ...)
    }
}

// MARK: - App-wide State (shared object)

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

### Binding Pattern

```swift
/**
 * Sharing state with Binding
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
        Button("Select") {
            selectedItem = "item-1"
        }
    }
}

/**
 * Read-only Binding
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

### Reducer Pattern (Complex state management)

```swift
/**
 * State management with Reducer pattern
 *
 * Explicitly manage complex state transitions
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

        // Handle side effects
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

## Async Processing (async/await / Combine)

### async/await Basics

```swift
/**
 * Async processing with async/await
 */

// Basic async function
func fetchUser(id: String) async throws -> User {
    let response = try await apiClient.request(
        endpoint: .user(id: id),
        method: .get
    )
    return response.toDomain()
}

// Parallel execution
func fetchUserDetail(userId: String) async throws -> UserDetail {
    async let user = userRepository.getUser(userId: userId)
    async let posts = postRepository.getPostsByUser(userId: userId)

    return try await UserDetail(
        user: user,
        posts: posts,
        postCount: posts.count
    )
}

// With timeout
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

### Task Management

```swift
/**
 * Proper Task management
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
        // Cancel Task on ViewModel destruction
        loadTask?.cancel()
    }

    func loadUser(userId: String) {
        // Cancel existing Task
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

            // Check for cancellation
            guard !Task.isCancelled else { return }

            uiState = uiState.copy(
                userDetail: userDetail,
                isLoading: false
            )
        } catch is CancellationError {
            // Ignore cancellation
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

### Using with Combine

```swift
import Combine

/**
 * Reactive data stream with Combine
 */

// Real-time updates with Publisher
protocol UserRepositoryProtocol {
    // One-shot retrieval
    func getUsers() async throws -> [User]

    // Real-time stream
    var usersPublisher: AnyPublisher<[User], Never> { get }
}

// Usage in View
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
 * Converting between async/await and Combine
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

### Using AsyncSequence

```swift
/**
 * Continuous data processing with AsyncSequence
 */

// Pagination
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

// Usage
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

## Error Handling

### Error Type Hierarchy

```swift
import Foundation

/**
 * Application error hierarchy
 */
enum AppError: Error, Equatable {

    // Network errors
    case network(NetworkError)

    // Data errors
    case data(DataError)

    // Auth errors
    case auth(AuthError)

    // Unknown error
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
            return "No internet connection"
        case .network(.timeout):
            return "Request timed out"
        case .network(.server(let code)):
            return "Server error (\(code))"
        case .network(.unknown):
            return "A communication error occurred"
        case .data(.notFound(let message)):
            return message
        case .data(.validation(let message)):
            return message
        case .data(.conflict(let message)):
            return message
        case .auth(.unauthorized):
            return "Authentication required"
        case .auth(.sessionExpired):
            return "Session has expired"
        case .unknown(let message):
            return message
        }
    }
}
```

### Using Result Type

```swift
/**
 * Error handling with Result type
 */

// Explicitly represent success/failure
typealias AppResult<T> = Result<T, AppError>

extension Result where Failure == AppError {

    // Get value on success (nil on failure)
    var success: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    // Get error on failure (nil on success)
    var failure: AppError? {
        guard case .failure(let error) = self else { return nil }
        return error
    }

    // Shorthand for map
    func mapSuccess<T>(_ transform: (Success) -> T) -> Result<T, AppError> {
        map(transform)
    }
}

// Usage in Repository
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

// Usage in ViewModel
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

### UI Error Model

```swift
/**
 * UI error model
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
 * Error → UiError conversion
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
                message: "No internet connection",
                action: .retry
            )
        case .network(.timeout):
            return UiError(
                message: "Request timed out",
                action: .retry
            )
        case .network(.server):
            return UiError(
                message: "A server error occurred",
                action: .retry
            )
        case .auth(.unauthorized), .auth(.sessionExpired):
            return UiError(
                message: "Login required",
                action: .login
            )
        default:
            return UiError(
                message: errorDescription ?? "An error occurred",
                action: .dismiss
            )
        }
    }
}
```

### Error Display Component

```swift
/**
 * Error Display View
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
                Button("Retry") {
                    onRetryTap()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

/**
 * Alert Modifier
 */
extension View {

    func errorAlert(
        error: Binding<UiError?>,
        onRetry: @escaping () -> Void = {}
    ) -> some View {
        alert(
            "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { uiError in
            if uiError.action == .retry {
                Button("Retry") { onRetry() }
            }
            Button("OK", role: .cancel) {}
        } message: { uiError in
            Text(uiError.message)
        }
    }
}
```

---

## Testing Strategy

### Test Pyramid

```
         ┌─────────┐
         │   E2E   │  ← Few critical flows
         │  Tests  │
         ├─────────┤
         │ Integra-│  ← Repository, ViewModel tests
         │  tion   │
         ├─────────┤
         │  Unit   │  ← UseCase, Domain Model tests
         │  Tests  │     Write the most of these
         └─────────┘
```

### Unit Test

```swift
import XCTest
@testable import MyApp

/**
 * UseCase unit test
 */
final class GetUsersUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: GetUsersUseCase!
    private var fakeUserRepository: FakeUserRepository!
    private var fakeAnalyticsRepository: FakeAnalyticsRepository!

    // MARK: - Setup

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

    // MARK: - Tests

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
 * ViewModel test
 */
@MainActor
final class UserListViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: UserListViewModel!
    private var fakeGetUsersUseCase: FakeGetUsersUseCase!

    // MARK: - Setup

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

    // MARK: - Tests

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

        // Then (should be loading immediately)
        // Note: @Observable updates are synchronous, check right after Task starts
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

        // Wait for async processing to complete
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

### Fake / Stub Creation

```swift
/**
 * Fake Repository (test implementation with state)
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
 * Stub generator for testing
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
 * SwiftUI Snapshot test
 */
final class UserListContentSnapshotTests: XCTestCase {

    func test_loadingState() {
        let view = UserListContent(
            uiState: UserListUiState(isLoading: true),
            onUserTap: { _ in },
            onRetryTap: {}
        )

        // Compare using snapshot library
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
                    message: "An error occurred",
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

## Directory Structure

### Feature-based Structure (Recommended)

```
MyApp/
├── App/
│   ├── MyApp.swift                    # @main App
│   ├── ContentView.swift
│   └── Configuration.swift            # Environment configuration
│
├── Core/                              # Common components
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
├── Feature/                           # Feature modules
│   │
│   ├── User/                          # User feature
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
│   ├── Auth/                          # Auth feature
│   │   ├── Data/
│   │   ├── Domain/
│   │   └── UI/
│   │
│   └── Settings/                      # Settings feature
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

## Naming Conventions

### File/Class Naming

| Type | Suffix | Example |
|------|--------|---------|
| SwiftUI View | Screen / View | `UserListScreen`, `UserCard` |
| ViewModel | ViewModel | `UserListViewModel` |
| UseCase | UseCase | `GetUsersUseCase` |
| Repository Protocol | RepositoryProtocol | `UserRepositoryProtocol` |
| Repository Implementation | Repository | `UserRepository` |
| DataSource Protocol | DataSourceProtocol | `UserLocalDataSourceProtocol` |
| DataSource Implementation | DataSource | `UserLocalDataSource` |
| SwiftData Entity | Entity | `UserEntity` |
| API Response | Response | `UserResponse` |
| API Request | Request | `CreateUserRequest` |
| UI State | UiState | `UserListUiState` |
| UI Model | UiModel | `UserUiModel` |
| Navigation Event | NavigationEvent | `UserListNavigationEvent` |

### Function Naming

| Type | Pattern | Example |
|------|---------|---------|
| Get single data | `get{Entity}` | `getUser(userId:)` |
| Get multiple data | `get{Entity}s` | `getUsers()` |
| Create data | `create{Entity}` / `insert{Entity}` | `createUser(_:)` |
| Update data | `update{Entity}` | `updateUser(_:)` |
| Delete data | `delete{Entity}` | `deleteUser(userId:)` |
| Event handler | `on{Event}Tap` / `on{Event}` | `onUserTap(_:)` |
| Conversion | `to{Target}` | `toDomain()`, `toEntity()` |
| Validation | `is{Condition}` / `has{Property}` | `isValid`, `hasPermission` |
| UseCase execution | `execute` | `execute()`, `execute(userId:)` |

### Variable Naming

| Type | Pattern | Example |
|------|---------|---------|
| Boolean | `is{State}` / `has{Property}` / `should{Action}` | `isLoading`, `hasError`, `shouldRefresh` |
| Collection | Plural | `users`, `posts` |
| Optional | Descriptive as needed | `selectedUser`, `error` |
| Closure | `on{Event}` | `onTap`, `onComplete` |
| Publisher | `{name}Publisher` | `usersPublisher` |

---

## Best Practices Checklist

### ViewModel

- [ ] Manage UI State with a single struct
- [ ] Expose state as read-only with `private(set)`
- [ ] Manage navigation events as separate property
- [ ] Implement Task cancellation
- [ ] Ensure UI updates with `@MainActor`

### Repository

- [ ] Define Protocol and separate from implementation
- [ ] Adopt offline-first strategy
- [ ] Use async/await for data retrieval
- [ ] Use Combine Publisher for real-time updates
- [ ] Hide DataSource details

### UseCase

- [ ] Single responsibility (1 UseCase = 1 function)
- [ ] Define Protocol for testability
- [ ] Create only when needed (direct Repository call is fine for simple cases)
- [ ] Business logic only, no UI logic

### SwiftUI

- [ ] Separate View and ViewModel
- [ ] Clearly distinguish Stateless / Stateful Views
- [ ] Leverage Preview for development
- [ ] Start async processing with `.task`
- [ ] Optimize redraws (leverage @Observable)

### Dependency Injection

- [ ] Inject dependencies through Protocols
- [ ] Manage lifecycle with DependencyContainer
- [ ] Enable easy replacement with Fake/Mock for testing
- [ ] Integrate with SwiftUI using Environment

### Testing

- [ ] Unit tests for UseCase and ViewModel are required
- [ ] Prefer Fakes, minimize Mocks
- [ ] Execute tests with `@MainActor`
- [ ] Write tests with async/await

### Error Handling

- [ ] Define application error hierarchy
- [ ] Wrap errors in Repository
- [ ] Convert to UI error model
- [ ] Implement retry mechanism

### Performance

- [ ] Minimize redraws with `@Observable` (iOS 17+)
- [ ] Implement Task cancellation
- [ ] Stream large data with AsyncSequence
- [ ] Leverage LazyVStack / LazyHStack

---

## References

- [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Observation Framework](https://developer.apple.com/documentation/observation)
- [WWDC23 - Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [WWDC23 - Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
