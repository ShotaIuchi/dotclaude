# KMP ネットワーク (Ktor)

Kotlin Multiplatform での Ktor を使用した HTTP クライアント実装。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md) | [Ktor 公式](https://ktor.io/docs/getting-started-ktor-client.html)

---

## API クライアント

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiClient.kt

/**
 * Ktor を使用した API クライアント
 */
class ApiClient(
    private val httpClient: HttpClient,
    private val baseUrl: String
) {
    /**
     * GET リクエスト
     */
    suspend inline fun <reified T> get(
        endpoint: String,
        params: Map<String, String> = emptyMap()
    ): T {
        return httpClient.get(baseUrl + endpoint) {
            params.forEach { (key, value) ->
                parameter(key, value)
            }
        }.body()
    }

    /**
     * POST リクエスト
     */
    suspend inline fun <reified T, reified R> post(
        endpoint: String,
        body: T
    ): R {
        return httpClient.post(baseUrl + endpoint) {
            contentType(ContentType.Application.Json)
            setBody(body)
        }.body()
    }

    /**
     * PUT リクエスト
     */
    suspend inline fun <reified T, reified R> put(
        endpoint: String,
        body: T
    ): R {
        return httpClient.put(baseUrl + endpoint) {
            contentType(ContentType.Application.Json)
            setBody(body)
        }.body()
    }

    /**
     * DELETE リクエスト
     */
    suspend fun delete(endpoint: String) {
        httpClient.delete(baseUrl + endpoint)
    }
}
```

---

## RemoteDataSource 実装

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/UserRemoteDataSource.kt

/**
 * ユーザーリモートデータソース
 */
interface UserRemoteDataSource {
    suspend fun getUsers(): List<UserResponse>
    suspend fun getUser(userId: String): UserResponse
    suspend fun createUser(request: CreateUserRequest): UserResponse
    suspend fun updateUser(userId: String, request: UpdateUserRequest): UserResponse
    suspend fun deleteUser(userId: String)
}

/**
 * Ktor を使用したリモートデータソース実装
 */
class UserRemoteDataSourceImpl(
    private val httpClient: HttpClient
) : UserRemoteDataSource {

    private val baseUrl = "https://api.example.com"

    override suspend fun getUsers(): List<UserResponse> {
        return httpClient.get("$baseUrl/users").body()
    }

    override suspend fun getUser(userId: String): UserResponse {
        return httpClient.get("$baseUrl/users/$userId").body()
    }

    override suspend fun createUser(request: CreateUserRequest): UserResponse {
        return httpClient.post("$baseUrl/users") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }

    override suspend fun updateUser(
        userId: String,
        request: UpdateUserRequest
    ): UserResponse {
        return httpClient.put("$baseUrl/users/$userId") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }

    override suspend fun deleteUser(userId: String) {
        httpClient.delete("$baseUrl/users/$userId")
    }
}
```

---

## API モデル

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/model/UserResponse.kt

/**
 * API レスポンスモデル
 */
@Serializable
data class UserResponse(
    val id: String,
    val name: String,
    val email: String,
    @SerialName("joined_at")
    val joinedAt: String,
    val status: String
)

/**
 * ユーザー作成リクエスト
 */
@Serializable
data class CreateUserRequest(
    val name: String,
    val email: String
)

/**
 * ユーザー更新リクエスト
 */
@Serializable
data class UpdateUserRequest(
    val name: String,
    val email: String
)

/**
 * Response → Domain 変換
 */
fun UserResponse.toDomain(): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.parse(joinedAt),
        status = UserStatus.valueOf(status.uppercase())
    )
}

/**
 * Response → Entity 変換
 */
fun UserResponse.toEntity(): UserEntityData {
    return UserEntityData(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.parse(joinedAt).toEpochMilliseconds(),
        status = status.uppercase()
    )
}

/**
 * Domain → Request 変換
 */
fun User.toRequest(): CreateUserRequest {
    return CreateUserRequest(
        name = name,
        email = email
    )
}
```

---

## ベストプラクティス

- HttpClient は DI で管理
- エンジンはプラットフォーム別に設定
- エラーハンドリングを統一
- Serialization は kotlinx-serialization を使用
