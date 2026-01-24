# KMP ネットワーク (Ktor)

Kotlin Multiplatform における Ktor を使用した HTTP クライアント実装。

---

## 概要

Ktor は Kotlin 製の非同期 HTTP クライアントで、KMP プロジェクトで共通のネットワーク層を構築できます。プラットフォーム固有のエンジンを使用しながら、共通の API でネットワーク操作を実装できます。

---

## 依存関係

`build.gradle.kts` に以下の依存関係を追加：

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
                // Android: OkHttp エンジン（推奨）
                implementation("io.ktor:ktor-client-okhttp:2.3.7")
            }
        }

        val iosMain by getting {
            dependencies {
                // iOS: Darwin エンジン
                implementation("io.ktor:ktor-client-darwin:2.3.7")
            }
        }
    }
}
```

---

## HttpClient 設定

### 共通設定 (expect/actual)

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/HttpClientFactory.kt

/**
 * プラットフォーム固有の HttpClient を作成するファクトリ
 */
expect fun createPlatformHttpClient(): HttpClient

/**
 * 共通設定を持つ HttpClient
 */
fun createHttpClient(
    tokenProvider: suspend () -> String? = { null }
): HttpClient {
    return createPlatformHttpClient().config {
        // JSON シリアライゼーション
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
                encodeDefaults = true
                prettyPrint = false
            })
        }

        // ロギング
        install(Logging) {
            logger = Logger.DEFAULT
            level = LogLevel.HEADERS
        }

        // 認証（Bearer トークン）
        install(Auth) {
            bearer {
                loadTokens {
                    tokenProvider()?.let { token ->
                        BearerTokens(token, "")
                    }
                }
            }
        }

        // タイムアウト設定
        install(HttpTimeout) {
            requestTimeoutMillis = 30_000
            connectTimeoutMillis = 10_000
            socketTimeoutMillis = 30_000
        }

        // デフォルトリクエスト設定
        defaultRequest {
            headers.append("Accept", "application/json")
        }
    }
}
```

### Android 実装

```kotlin
// androidMain/kotlin/com/example/shared/data/remote/HttpClientFactory.android.kt

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

### iOS 実装

```kotlin
// iosMain/kotlin/com/example/shared/data/remote/HttpClientFactory.ios.kt

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

## RemoteDataSource 実装

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/UserRemoteDataSource.kt

/**
 * User リモートデータソース
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
```

---

## エラーハンドリング

### カスタム例外

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/NetworkException.kt

/**
 * カスタムネットワーク例外
 */
sealed class NetworkException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    /** ネットワーク接続なし */
    class NoConnection(cause: Throwable? = null) :
        NetworkException("ネットワーク接続がありません", cause)

    /** リクエストタイムアウト */
    class Timeout(cause: Throwable? = null) :
        NetworkException("リクエストがタイムアウトしました", cause)

    /** サーバーエラー (5xx) */
    class ServerError(val code: Int, message: String) :
        NetworkException("サーバーエラー ($code): $message")

    /** クライアントエラー (4xx) */
    class ClientError(val code: Int, message: String) :
        NetworkException("クライアントエラー ($code): $message")

    /** 認証エラー (401) */
    class Unauthorized(message: String = "認証が必要です") :
        NetworkException(message)

    /** 禁止 (403) */
    class Forbidden(message: String = "アクセスが拒否されました") :
        NetworkException(message)

    /** 見つからない (404) */
    class NotFound(message: String = "リソースが見つかりません") :
        NetworkException(message)

    /** パース/シリアライゼーションエラー */
    class ParseError(cause: Throwable? = null) :
        NetworkException("レスポンスの解析に失敗しました", cause)

    /** 不明なエラー */
    class Unknown(message: String, cause: Throwable? = null) :
        NetworkException(message, cause)
}
```

### 安全な API 呼び出しラッパー

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/SafeApiCall.kt

/**
 * 包括的なエラーハンドリングで API 呼び出しを実行
 */
suspend fun <T> safeApiCall(
    apiCall: suspend () -> T
): NetworkResult<T> {
    return try {
        NetworkResult.Success(apiCall())
    } catch (e: CancellationException) {
        throw e // キャンセルを再スロー
    } catch (e: HttpRequestTimeoutException) {
        NetworkResult.Error(NetworkException.Timeout(e))
    } catch (e: ResponseException) {
        val statusCode = e.response.status.value
        val message = e.message ?: "不明なエラー"
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
        // プラットフォーム固有の接続エラーはここでキャッチ
        NetworkResult.Error(
            when {
                e.message?.contains("Unable to resolve host") == true ->
                    NetworkException.NoConnection(e)
                e.message?.contains("timeout") == true ->
                    NetworkException.Timeout(e)
                else -> NetworkException.Unknown(e.message ?: "不明なエラー", e)
            }
        )
    }
}
```

---

## ベストプラクティス

- HttpClient は DI（Koin/Hilt）で管理
- エンジンはプラットフォームごとに設定（Android は OkHttp、iOS は Darwin）
- 一貫したエラーハンドリングのために `safeApiCall` ラッパーを使用
- JSON シリアライゼーションには kotlinx-serialization を使用
- コルーチンでは常に `CancellationException` を適切に処理
- 異なるネットワーク条件に応じて適切なタイムアウト値を設定
- API 認証には Bearer 認証を使用
- リクエストのログはデバッグビルドのみ（本番では `LogLevel.NONE`）
