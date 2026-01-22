# KMP Network (Ktor)

HTTP client implementation using Ktor in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Ktor Official](https://ktor.io/docs/getting-started-ktor-client.html)

---

## API Client

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiClient.kt

/**
 * API client using Ktor
 */
class ApiClient(
    private val httpClient: HttpClient,
    private val baseUrl: String
) {
    /**
     * GET request
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
     * POST request
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
     * PUT request
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
     * DELETE request
     */
    suspend fun delete(endpoint: String) {
        httpClient.delete(baseUrl + endpoint)
    }
}
```

---

## RemoteDataSource Implementation

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/UserRemoteDataSource.kt

/**
 * User remote data source
 */
interface UserRemoteDataSource {
    suspend fun getUsers(): List<UserResponse>
    suspend fun getUser(userId: String): UserResponse
    suspend fun createUser(request: CreateUserRequest): UserResponse
    suspend fun updateUser(userId: String, request: UpdateUserRequest): UserResponse
    suspend fun deleteUser(userId: String)
}

/**
 * Remote data source implementation using Ktor
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

## API Models

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/model/UserResponse.kt

/**
 * API response model
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
 * User creation request
 */
@Serializable
data class CreateUserRequest(
    val name: String,
    val email: String
)

/**
 * User update request
 */
@Serializable
data class UpdateUserRequest(
    val name: String,
    val email: String
)

/**
 * Response → Domain conversion
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
 * Response → Entity conversion
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
 * Domain → Request conversion
 */
fun User.toRequest(): CreateUserRequest {
    return CreateUserRequest(
        name = name,
        email = email
    )
}
```

---

## Best Practices

- Manage HttpClient through DI
- Configure engine per platform
- Unify error handling
- Use kotlinx-serialization for Serialization
