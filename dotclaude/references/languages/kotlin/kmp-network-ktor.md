# KMP Network (Ktor)

HTTP client implementation using Ktor in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Ktor Official](https://ktor.io/docs/getting-started-ktor-client.html)

---

## Dependencies

Add the following dependencies to your `build.gradle.kts`:

```kotlin
// shared/build.gradle.kts

kotlin {
    sourceSets {
        val commonMain by getting {
            dependencies {
                // Ktor Client Core
                implementation("io.ktor:ktor-client-core:2.3.7")
                implementation("io.ktor:ktor-client-content-negotiation:2.3.7")
                implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.7")
                implementation("io.ktor:ktor-client-logging:2.3.7")
                implementation("io.ktor:ktor-client-auth:2.3.7")

                // Kotlinx Serialization
                implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
            }
        }

        val androidMain by getting {
            dependencies {
                // Android: OkHttp engine (recommended)
                implementation("io.ktor:ktor-client-okhttp:2.3.7")
            }
        }

        val iosMain by getting {
            dependencies {
                // iOS: Darwin engine
                implementation("io.ktor:ktor-client-darwin:2.3.7")
            }
        }
    }
}
```

---

## HttpClient Configuration

### Common Configuration (expect/actual)

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/HttpClientFactory.kt

import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.plugins.auth.*
import io.ktor.client.plugins.auth.providers.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * Factory for creating platform-specific HttpClient
 */
expect fun createPlatformHttpClient(): HttpClient

/**
 * Configured HttpClient with common settings
 */
fun createHttpClient(
    tokenProvider: suspend () -> String? = { null }
): HttpClient {
    return createPlatformHttpClient().config {
        // JSON serialization
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
                encodeDefaults = true
                prettyPrint = false
            })
        }

        // Logging
        install(Logging) {
            logger = Logger.DEFAULT
            level = LogLevel.HEADERS
        }

        // Authentication (Bearer token)
        install(Auth) {
            bearer {
                loadTokens {
                    tokenProvider()?.let { token ->
                        BearerTokens(token, "")
                    }
                }
                refreshTokens {
                    tokenProvider()?.let { token ->
                        BearerTokens(token, "")
                    }
                }
            }
        }

        // Timeout configuration
        install(HttpTimeout) {
            requestTimeoutMillis = 30_000
            connectTimeoutMillis = 10_000
            socketTimeoutMillis = 30_000
        }

        // Default request configuration
        defaultRequest {
            headers.append("Accept", "application/json")
        }
    }
}
```

### Android Implementation

```kotlin
// androidMain/kotlin/com/example/shared/data/remote/HttpClientFactory.android.kt

import io.ktor.client.*
import io.ktor.client.engine.okhttp.*
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

actual fun createPlatformHttpClient(): HttpClient {
    return HttpClient(OkHttp) {
        engine {
            preconfigured = OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .build()
        }
    }
}
```

### iOS Implementation

```kotlin
// iosMain/kotlin/com/example/shared/data/remote/HttpClientFactory.ios.kt

import io.ktor.client.*
import io.ktor.client.engine.darwin.*

actual fun createPlatformHttpClient(): HttpClient {
    return HttpClient(Darwin) {
        engine {
            configureRequest {
                setAllowsCellularAccess(true)
                setTimeoutInterval(30.0)
            }
        }
    }
}
```

---

## API Client

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiClient.kt

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*

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

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*

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

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant

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

## Error Handling

### Result Wrapper

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/NetworkResult.kt

import io.ktor.client.plugins.*
import io.ktor.http.*

/**
 * Sealed class for network operation results
 */
sealed class NetworkResult<out T> {
    data class Success<T>(val data: T) : NetworkResult<T>()
    data class Error(val exception: NetworkException) : NetworkResult<Nothing>()

    val isSuccess: Boolean get() = this is Success
    val isError: Boolean get() = this is Error

    fun getOrNull(): T? = (this as? Success)?.data
    fun exceptionOrNull(): NetworkException? = (this as? Error)?.exception

    inline fun <R> map(transform: (T) -> R): NetworkResult<R> = when (this) {
        is Success -> Success(transform(data))
        is Error -> this
    }

    inline fun onSuccess(action: (T) -> Unit): NetworkResult<T> {
        if (this is Success) action(data)
        return this
    }

    inline fun onError(action: (NetworkException) -> Unit): NetworkResult<T> {
        if (this is Error) action(exception)
        return this
    }
}
```

### Custom Exceptions

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/NetworkException.kt

/**
 * Custom network exceptions
 */
sealed class NetworkException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    /** No network connection */
    class NoConnection(cause: Throwable? = null) :
        NetworkException("No network connection", cause)

    /** Request timeout */
    class Timeout(cause: Throwable? = null) :
        NetworkException("Request timed out", cause)

    /** Server error (5xx) */
    class ServerError(val code: Int, message: String) :
        NetworkException("Server error ($code): $message")

    /** Client error (4xx) */
    class ClientError(val code: Int, message: String) :
        NetworkException("Client error ($code): $message")

    /** Unauthorized (401) */
    class Unauthorized(message: String = "Authentication required") :
        NetworkException(message)

    /** Forbidden (403) */
    class Forbidden(message: String = "Access denied") :
        NetworkException(message)

    /** Not found (404) */
    class NotFound(message: String = "Resource not found") :
        NetworkException(message)

    /** Parse/serialization error */
    class ParseError(cause: Throwable? = null) :
        NetworkException("Failed to parse response", cause)

    /** Unknown error */
    class Unknown(message: String, cause: Throwable? = null) :
        NetworkException(message, cause)
}
```

### Safe API Call Wrapper

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/SafeApiCall.kt

import io.ktor.client.plugins.*
import io.ktor.http.*
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.SerializationException

/**
 * Executes API call with comprehensive error handling
 */
suspend fun <T> safeApiCall(
    apiCall: suspend () -> T
): NetworkResult<T> {
    return try {
        NetworkResult.Success(apiCall())
    } catch (e: CancellationException) {
        throw e // Re-throw cancellation
    } catch (e: HttpRequestTimeoutException) {
        NetworkResult.Error(NetworkException.Timeout(e))
    } catch (e: ResponseException) {
        val statusCode = e.response.status.value
        val message = e.message ?: "Unknown error"
        NetworkResult.Error(
            when (statusCode) {
                401 -> NetworkException.Unauthorized(message)
                403 -> NetworkException.Forbidden(message)
                404 -> NetworkException.NotFound(message)
                in 400..499 -> NetworkException.ClientError(statusCode, message)
                in 500..599 -> NetworkException.ServerError(statusCode, message)
                else -> NetworkException.Unknown(message, e)
            }
        )
    } catch (e: SerializationException) {
        NetworkResult.Error(NetworkException.ParseError(e))
    } catch (e: Exception) {
        // Platform-specific connection errors are caught here
        NetworkResult.Error(
            when {
                e.message?.contains("Unable to resolve host") == true ->
                    NetworkException.NoConnection(e)
                e.message?.contains("timeout") == true ->
                    NetworkException.Timeout(e)
                else -> NetworkException.Unknown(e.message ?: "Unknown error", e)
            }
        )
    }
}
```

### Usage in RemoteDataSource

```kotlin
// Example usage with error handling
class UserRemoteDataSourceImpl(
    private val httpClient: HttpClient
) : UserRemoteDataSource {

    override suspend fun getUsers(): NetworkResult<List<UserResponse>> {
        return safeApiCall {
            httpClient.get("$baseUrl/users").body()
        }
    }

    override suspend fun getUser(userId: String): NetworkResult<UserResponse> {
        return safeApiCall {
            httpClient.get("$baseUrl/users/$userId").body()
        }
    }
}
```

---

## Best Practices

- Manage HttpClient through DI (Koin/Hilt)
- Configure engine per platform (OkHttp for Android, Darwin for iOS)
- Use `safeApiCall` wrapper for consistent error handling
- Use kotlinx-serialization for JSON serialization
- Always handle `CancellationException` properly in coroutines
- Set appropriate timeout values for different network conditions
- Use Bearer authentication for API authorization
- Log requests in debug builds only (`LogLevel.NONE` in production)
