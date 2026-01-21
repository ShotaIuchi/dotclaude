# KMP Authentication Best Practices Guide

KMP（Kotlin Multiplatform）+ Ktor での認証実装ベストプラクティス。
複数ログイン方式対応、トークン管理、401→refresh→retry の王道パターンを実装するためのガイド。

---

## 目次

1. [ゴール](#ゴール)
2. [アーキテクチャ概要](#アーキテクチャ概要)
3. [データモデル](#データモデル)
4. [インターフェース定義](#インターフェース定義)
5. [Ktor 認証プラグイン実装](#ktor-認証プラグイン実装)
6. [複数ログイン方式の設計指針](#複数ログイン方式の設計指針)
7. [ディレクトリ構成例](#ディレクトリ構成例)
8. [例外設計](#例外設計)
9. [実装コード例](#実装コード例)
10. [エージェント向けタスク分解](#エージェント向けタスク分解)

---

## ゴール

### 達成すべき要件

1. **shared モジュールで認証を完結**
   - API 通信、トークン付与、401→refresh→retry をすべて共通コードで実装
   - プラットフォーム固有コードは TokenStore の永続化のみ

2. **ログイン方式の差分を閉じ込め**
   - ネットワーク層は `Session` だけを見る
   - ログイン方式の差分は `AuthRepository.login()` に集約
   - refresh ロジックの差分は `AuthRepository.refresh()` に集約

3. **Android/iOS で挙動一致**
   - 同じビジネスロジック、同じエラーハンドリング
   - UI 層のみプラットフォーム固有

4. **並列 401 でも破綻しない**
   - Mutex による refresh 多重発火抑止
   - refresh 中のリクエストは待機してリトライ

---

## アーキテクチャ概要

### レイヤー構成

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Platform UI Layer                                │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │   Android (Compose)  │        │   iOS (SwiftUI)      │          │
│  └──────────────────────┘        └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Shared Module (commonMain)                      │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                        │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   LoginViewModel / AuthStateViewModel               │    │   │
│  │  │   - SessionState を監視                              │    │   │
│  │  │   - ログイン/ログアウト操作を AuthRepository へ       │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Domain Layer                             │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   AuthRepository (interface)                        │    │   │
│  │  │   - login(method: LoginMethod): Result<Session>     │    │   │
│  │  │   - refresh(): Result<Session>                      │    │   │
│  │  │   - logout()                                        │    │   │
│  │  │   - sessionState: StateFlow<SessionState>           │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                              │   │
│  │                                                               │   │
│  │  ┌───────────────────┐  ┌───────────────────────────────┐   │   │
│  │  │   TokenStore      │  │   AuthRepositoryImpl          │   │   │
│  │  │   (expect/actual) │  │   - ログイン方式ごとの処理      │   │   │
│  │  │   - get/save/clear│  │   - refresh ロジック           │   │   │
│  │  └───────────────────┘  └───────────────────────────────┘   │   │
│  │                                │                              │   │
│  │                                ▼                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   Ktor HttpClient + AuthPlugin                      │    │   │
│  │  │   - Authorization ヘッダー自動付与                    │    │   │
│  │  │   - 401 検知 → refresh → retry                      │    │   │
│  │  │   - Mutex による多重 refresh 抑止                    │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Platform-Specific (expect/actual)                 │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │ TokenStore.android   │        │ TokenStore.ios       │          │
│  │ (EncryptedSharedPref)│        │ (Keychain)           │          │
│  └──────────────────────┘        └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

### 責務分離

| レイヤー | 責務 |
|---------|------|
| **UI** | ログイン画面表示、SessionState に応じた画面遷移 |
| **ViewModel** | SessionState 監視、ログイン操作の発火 |
| **AuthRepository** | ログイン方式ごとの処理、refresh ロジック、SessionState 管理 |
| **TokenStore** | トークンの永続化（プラットフォーム固有） |
| **HttpClient + AuthPlugin** | Authorization ヘッダー付与、401→refresh→retry |

---

## データモデル

### Session

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/Session.kt

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable

/**
 * 認証セッション
 *
 * ログイン方式に関わらず、統一されたセッション情報を保持
 */
@Serializable
data class Session(
    val accessToken: String,
    val refreshToken: String?,
    val expiresAt: Instant?,
    val authType: AuthType,
    val userId: String,
    val scopes: Set<String> = emptySet()
) {
    /**
     * アクセストークンが期限切れかどうか
     *
     * expiresAt が null の場合は期限切れとみなさない
     */
    fun isExpired(now: Instant = Clock.System.now()): Boolean {
        return expiresAt?.let { now >= it } ?: false
    }

    /**
     * refresh 可能かどうか
     */
    val canRefresh: Boolean
        get() = refreshToken != null
}
```

### AuthType

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/AuthType.kt

import kotlinx.serialization.Serializable

/**
 * 認証タイプ
 *
 * セッションがどの方式でログインされたかを識別
 */
@Serializable
enum class AuthType {
    EMAIL_PASSWORD,
    GOOGLE,
    APPLE,
    SSO,
    CUSTOM
}
```

### LoginMethod

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/LoginMethod.kt

/**
 * ログイン方式
 *
 * 各ログイン方式に必要なパラメータを保持する sealed class
 */
sealed class LoginMethod {

    /**
     * メール/パスワード認証
     */
    data class EmailPassword(
        val email: String,
        val password: String
    ) : LoginMethod()

    /**
     * Google Sign-In（ID Token 方式）
     */
    data class GoogleIdToken(
        val idToken: String
    ) : LoginMethod()

    /**
     * Apple Sign In（ID Token 方式）
     */
    data class AppleIdToken(
        val idToken: String,
        val authorizationCode: String?,
        val fullName: String?
    ) : LoginMethod()

    /**
     * SSO（Authorization Code 方式）
     */
    data class SsoAuthCode(
        val provider: String,
        val authorizationCode: String,
        val codeVerifier: String?  // PKCE 使用時
    ) : LoginMethod()

    /**
     * カスタム認証
     */
    data class Custom(
        val type: String,
        val credentials: Map<String, String>
    ) : LoginMethod()
}
```

### SessionState

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/SessionState.kt

/**
 * セッション状態
 *
 * UI 層がこの状態を監視して画面遷移を決定
 */
sealed class SessionState {

    /**
     * ログアウト状態
     */
    object LoggedOut : SessionState()

    /**
     * ログイン中
     */
    data class LoggedIn(
        val session: Session
    ) : SessionState()

    /**
     * トークン更新中
     *
     * この状態の間は API リクエストを待機させる
     */
    data class Refreshing(
        val session: Session
    ) : SessionState()

    /**
     * セッション無効（再ログインが必要）
     *
     * refresh が失敗した場合に遷移
     */
    data class ExpiredOrInvalid(
        val reason: String? = null
    ) : SessionState()
}
```

---

## インターフェース定義

### TokenStore

```kotlin
// commonMain/kotlin/com/example/shared/data/auth/TokenStore.kt

import kotlinx.coroutines.flow.Flow

/**
 * トークン永続化ストア
 *
 * expect/actual でプラットフォーム固有の実装を提供
 */
interface TokenStore {

    /**
     * 現在のセッションを取得
     */
    suspend fun get(): Session?

    /**
     * セッションの変更を監視
     */
    fun flow(): Flow<Session?>

    /**
     * セッションを保存
     */
    suspend fun save(session: Session)

    /**
     * セッションをクリア
     */
    suspend fun clear()
}
```

### AuthRepository

```kotlin
// commonMain/kotlin/com/example/shared/domain/repository/AuthRepository.kt

import kotlinx.coroutines.flow.StateFlow

/**
 * 認証リポジトリ
 *
 * ログイン/ログアウト/refresh の操作と、セッション状態の管理
 */
interface AuthRepository {

    /**
     * 現在のセッション状態
     */
    val sessionState: StateFlow<SessionState>

    /**
     * ログイン
     *
     * @param method ログイン方式と認証情報
     * @return 成功時は Session、失敗時は例外
     */
    suspend fun login(method: LoginMethod): Result<Session>

    /**
     * トークン更新
     *
     * 内部的に呼ばれることが多いが、明示的に呼ぶことも可能
     *
     * @return 成功時は新しい Session、失敗時は例外
     */
    suspend fun refresh(): Result<Session>

    /**
     * ログアウト
     *
     * サーバーへのログアウト通知とローカルセッションのクリア
     */
    suspend fun logout()

    /**
     * 現在のセッションを取得
     */
    suspend fun getCurrentSession(): Session?
}
```

---

## Ktor 認証プラグイン実装

### 設計のポイント

1. **Authorization ヘッダーの自動付与**
   - TokenStore からトークンを取得してリクエストに付与

2. **401 検知 → refresh → リトライ**
   - 401 レスポンス受信時に自動で refresh を試行
   - refresh 成功後、元のリクエストをリトライ

3. **Mutex による多重 refresh 抑止**
   - 並列リクエストが同時に 401 を受けても、refresh は 1 回だけ

4. **refresh API のループ防止**
   - refresh API 自体には認証プラグインを適用しない
   - 専用の HttpClient を使用

### AuthPlugin 実装

```kotlin
// commonMain/kotlin/com/example/shared/data/network/AuthPlugin.kt

import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.util.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * 認証プラグインの設定
 */
class AuthPluginConfig {
    var tokenStore: TokenStore? = null
    var refreshTokens: (suspend () -> Result<Session>)? = null
    var onSessionExpired: (suspend () -> Unit)? = null
}

/**
 * Ktor 認証プラグイン
 *
 * - Authorization ヘッダー自動付与
 * - 401 → refresh → retry
 * - Mutex による多重 refresh 抑止
 */
val AuthPlugin = createClientPlugin("AuthPlugin", ::AuthPluginConfig) {

    val tokenStore = pluginConfig.tokenStore
        ?: throw IllegalStateException("TokenStore must be configured")
    val refreshTokens = pluginConfig.refreshTokens
        ?: throw IllegalStateException("refreshTokens must be configured")
    val onSessionExpired = pluginConfig.onSessionExpired

    val refreshMutex = Mutex()

    // リクエスト送信前: Authorization ヘッダーを付与
    onRequest { request, _ ->
        // refresh API には適用しない
        if (request.attributes.getOrNull(SkipAuthKey) == true) {
            return@onRequest
        }

        val session = tokenStore.get()
        if (session != null) {
            request.bearerAuth(session.accessToken)
        }
    }

    // レスポンス受信後: 401 なら refresh → retry
    on(Send) { request ->
        // refresh API には適用しない
        if (request.attributes.getOrNull(SkipAuthKey) == true) {
            return@on proceed(request)
        }

        val originalResponse = proceed(request)

        // 401 でなければそのまま返す
        if (originalResponse.status != HttpStatusCode.Unauthorized) {
            return@on originalResponse
        }

        // refresh を試行（Mutex で排他制御）
        val refreshResult = refreshMutex.withLock {
            // 他のリクエストが既に refresh した可能性があるので再チェック
            val currentSession = tokenStore.get()
            val originalToken = request.headers[HttpHeaders.Authorization]
                ?.removePrefix("Bearer ")

            // トークンが既に更新されていたら refresh 不要
            if (currentSession != null && currentSession.accessToken != originalToken) {
                Result.success(currentSession)
            } else {
                refreshTokens()
            }
        }

        when {
            refreshResult.isSuccess -> {
                // 新しいトークンでリトライ
                val newSession = refreshResult.getOrThrow()
                val retryRequest = HttpRequestBuilder().apply {
                    takeFrom(request)
                    bearerAuth(newSession.accessToken)
                }
                proceed(retryRequest.build())
            }
            else -> {
                // refresh 失敗 → セッション期限切れを通知
                onSessionExpired?.invoke()
                originalResponse
            }
        }
    }
}

/**
 * 認証スキップ用のキー
 */
val SkipAuthKey = AttributeKey<Boolean>("SkipAuth")

/**
 * このリクエストでは認証をスキップする
 */
fun HttpRequestBuilder.skipAuth() {
    attributes.put(SkipAuthKey, true)
}
```

### HttpClient 設定

```kotlin
// commonMain/kotlin/com/example/shared/data/network/HttpClientFactory.kt

import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * HttpClient ファクトリ
 */
class HttpClientFactory(
    private val tokenStore: TokenStore,
    private val authRepository: AuthRepository,
    private val engine: HttpClientEngine
) {
    /**
     * 認証付き HttpClient を作成
     */
    fun createAuthenticatedClient(): HttpClient {
        return HttpClient(engine) {
            // JSON シリアライゼーション
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                    isLenient = true
                    encodeDefaults = true
                })
            }

            // ロギング（デバッグ用）
            install(Logging) {
                level = LogLevel.HEADERS
            }

            // タイムアウト設定
            install(HttpTimeout) {
                requestTimeoutMillis = 30_000
                connectTimeoutMillis = 10_000
            }

            // 認証プラグイン
            install(AuthPlugin) {
                this.tokenStore = this@HttpClientFactory.tokenStore
                this.refreshTokens = {
                    authRepository.refresh()
                }
                this.onSessionExpired = {
                    // SessionState を ExpiredOrInvalid に更新
                    // AuthRepository 内部で処理されるため、ここでは何もしなくてよい場合も
                }
            }
        }
    }

    /**
     * 認証なし HttpClient を作成（refresh API 用）
     */
    fun createUnauthenticatedClient(): HttpClient {
        return HttpClient(engine) {
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                    isLenient = true
                    encodeDefaults = true
                })
            }

            install(HttpTimeout) {
                requestTimeoutMillis = 30_000
                connectTimeoutMillis = 10_000
            }
        }
    }
}
```

### refresh API のループ防止

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/AuthRemoteDataSource.kt

/**
 * 認証 API のリモートデータソース
 *
 * 重要: refresh API には認証なし HttpClient を使用する
 */
class AuthRemoteDataSourceImpl(
    private val unauthenticatedClient: HttpClient,  // 認証なしクライアント
    private val baseUrl: String
) : AuthRemoteDataSource {

    override suspend fun refreshToken(refreshToken: String): TokenResponse {
        return unauthenticatedClient.post("$baseUrl/auth/refresh") {
            contentType(ContentType.Application.Json)
            setBody(RefreshTokenRequest(refreshToken = refreshToken))
        }.body()
    }

    override suspend fun login(request: LoginRequest): TokenResponse {
        return unauthenticatedClient.post("$baseUrl/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }

    // その他のログイン方式の API も同様に unauthenticatedClient を使用
}
```

---

## 複数ログイン方式の設計指針

### 原則

1. **ネットワーク層は Session だけを見る**
   - HttpClient は `Session.accessToken` だけを使用
   - ログイン方式の違いを意識しない

2. **方式の差分は AuthRepository.login() に閉じ込め**
   - `LoginMethod` の種類に応じて適切な API を呼び出す
   - 結果を統一された `Session` に変換

3. **refresh の差分も AuthRepository.refresh() に閉じ込め**
   - 一部の認証方式では refresh の挙動が異なる場合がある
   - AuthType を見て適切な refresh ロジックを実行

### AuthRepository 実装例

```kotlin
// commonMain/kotlin/com/example/shared/data/repository/AuthRepositoryImpl.kt

class AuthRepositoryImpl(
    private val tokenStore: TokenStore,
    private val authRemoteDataSource: AuthRemoteDataSource,
    private val coroutineScope: CoroutineScope
) : AuthRepository {

    private val _sessionState = MutableStateFlow<SessionState>(SessionState.LoggedOut)
    override val sessionState: StateFlow<SessionState> = _sessionState.asStateFlow()

    private val refreshMutex = Mutex()

    init {
        // TokenStore の変更を監視して SessionState を更新
        coroutineScope.launch {
            tokenStore.flow().collect { session ->
                _sessionState.value = when {
                    session == null -> SessionState.LoggedOut
                    session.isExpired() -> SessionState.ExpiredOrInvalid()
                    else -> SessionState.LoggedIn(session)
                }
            }
        }
    }

    override suspend fun login(method: LoginMethod): Result<Session> {
        return runCatching {
            val response = when (method) {
                is LoginMethod.EmailPassword -> {
                    authRemoteDataSource.loginWithEmail(
                        email = method.email,
                        password = method.password
                    )
                }
                is LoginMethod.GoogleIdToken -> {
                    authRemoteDataSource.loginWithGoogle(
                        idToken = method.idToken
                    )
                }
                is LoginMethod.AppleIdToken -> {
                    authRemoteDataSource.loginWithApple(
                        idToken = method.idToken,
                        authorizationCode = method.authorizationCode,
                        fullName = method.fullName
                    )
                }
                is LoginMethod.SsoAuthCode -> {
                    authRemoteDataSource.loginWithSso(
                        provider = method.provider,
                        authorizationCode = method.authorizationCode,
                        codeVerifier = method.codeVerifier
                    )
                }
                is LoginMethod.Custom -> {
                    authRemoteDataSource.loginCustom(
                        type = method.type,
                        credentials = method.credentials
                    )
                }
            }

            val session = response.toSession(authType = method.toAuthType())
            tokenStore.save(session)
            session
        }
    }

    override suspend fun refresh(): Result<Session> {
        return refreshMutex.withLock {
            runCatching {
                val currentSession = tokenStore.get()
                    ?: throw AuthException.NotLoggedIn()

                if (!currentSession.canRefresh) {
                    throw AuthException.RefreshNotSupported()
                }

                // refresh 中であることを通知
                _sessionState.value = SessionState.Refreshing(currentSession)

                val response = authRemoteDataSource.refreshToken(
                    refreshToken = currentSession.refreshToken!!
                )

                val newSession = response.toSession(authType = currentSession.authType)
                tokenStore.save(newSession)
                newSession
            }.onFailure { e ->
                // refresh 失敗時はセッション無効
                _sessionState.value = SessionState.ExpiredOrInvalid(e.message)
            }
        }
    }

    override suspend fun logout() {
        runCatching {
            val session = tokenStore.get()
            if (session != null) {
                // サーバーにログアウトを通知（失敗しても続行）
                authRemoteDataSource.logout(session.accessToken)
            }
        }
        tokenStore.clear()
    }

    override suspend fun getCurrentSession(): Session? {
        return tokenStore.get()
    }

    private fun LoginMethod.toAuthType(): AuthType {
        return when (this) {
            is LoginMethod.EmailPassword -> AuthType.EMAIL_PASSWORD
            is LoginMethod.GoogleIdToken -> AuthType.GOOGLE
            is LoginMethod.AppleIdToken -> AuthType.APPLE
            is LoginMethod.SsoAuthCode -> AuthType.SSO
            is LoginMethod.Custom -> AuthType.CUSTOM
        }
    }
}
```

---

## ディレクトリ構成例

```
shared/src/
├── commonMain/kotlin/com/example/shared/
│   │
│   ├── domain/
│   │   ├── model/
│   │   │   ├── Session.kt
│   │   │   ├── AuthType.kt
│   │   │   ├── LoginMethod.kt
│   │   │   └── SessionState.kt
│   │   │
│   │   └── repository/
│   │       └── AuthRepository.kt
│   │
│   ├── data/
│   │   ├── auth/
│   │   │   ├── TokenStore.kt              # interface
│   │   │   └── AuthException.kt
│   │   │
│   │   ├── network/
│   │   │   ├── AuthPlugin.kt              # Ktor 認証プラグイン
│   │   │   └── HttpClientFactory.kt
│   │   │
│   │   ├── remote/
│   │   │   ├── AuthRemoteDataSource.kt
│   │   │   └── model/
│   │   │       ├── TokenResponse.kt
│   │   │       ├── LoginRequest.kt
│   │   │       └── RefreshTokenRequest.kt
│   │   │
│   │   └── repository/
│   │       └── AuthRepositoryImpl.kt
│   │
│   └── presentation/
│       └── auth/
│           ├── LoginViewModel.kt
│           ├── LoginUiState.kt
│           └── AuthStateViewModel.kt
│
├── androidMain/kotlin/com/example/shared/
│   └── data/auth/
│       └── TokenStore.android.kt          # EncryptedSharedPreferences
│
└── iosMain/kotlin/com/example/shared/
    └── data/auth/
        └── TokenStore.ios.kt              # Keychain
```

---

## 例外設計

### AuthException 階層

```kotlin
// commonMain/kotlin/com/example/shared/data/auth/AuthException.kt

/**
 * 認証関連の例外
 */
sealed class AuthException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    /**
     * ログインしていない
     */
    class NotLoggedIn : AuthException("Not logged in")

    /**
     * 認証情報が無効
     */
    class InvalidCredentials(
        message: String = "Invalid credentials"
    ) : AuthException(message)

    /**
     * トークンが無効または期限切れ
     */
    class TokenInvalid(
        message: String = "Token is invalid or expired"
    ) : AuthException(message)

    /**
     * refresh がサポートされていない
     */
    class RefreshNotSupported : AuthException("Refresh is not supported for this auth type")

    /**
     * refresh に失敗（再ログインが必要）
     */
    class RefreshFailed(
        cause: Throwable? = null
    ) : AuthException("Failed to refresh token", cause)

    /**
     * アカウントがロックされている
     */
    class AccountLocked(
        message: String = "Account is locked"
    ) : AuthException(message)

    /**
     * ネットワークエラー
     */
    class Network(
        cause: Throwable
    ) : AuthException("Network error during authentication", cause)

    /**
     * 不明なエラー
     */
    class Unknown(
        cause: Throwable
    ) : AuthException("Unknown authentication error", cause)
}
```

### UI 層でのエラーハンドリング

```kotlin
// commonMain/kotlin/com/example/shared/presentation/auth/LoginViewModel.kt

class LoginViewModel(
    private val authRepository: AuthRepository,
    private val coroutineScope: CoroutineScope
) {
    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    fun login(email: String, password: String) {
        coroutineScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = authRepository.login(
                LoginMethod.EmailPassword(email, password)
            )

            result.fold(
                onSuccess = { session ->
                    _uiState.update {
                        it.copy(isLoading = false, loginSuccess = true)
                    }
                },
                onFailure = { e ->
                    val errorMessage = when (e) {
                        is AuthException.InvalidCredentials ->
                            "メールアドレスまたはパスワードが正しくありません"
                        is AuthException.AccountLocked ->
                            "アカウントがロックされています"
                        is AuthException.Network ->
                            "ネットワークエラーが発生しました"
                        else ->
                            "ログインに失敗しました"
                    }
                    _uiState.update {
                        it.copy(isLoading = false, error = errorMessage)
                    }
                }
            )
        }
    }
}

data class LoginUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val loginSuccess: Boolean = false
)
```

---

## 実装コード例

### TokenStore（expect/actual）

```kotlin
// commonMain: interface は data/auth/TokenStore.kt で定義済み

// androidMain/kotlin/com/example/shared/data/auth/TokenStore.android.kt

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Android 用 TokenStore 実装
 *
 * EncryptedSharedPreferences を使用してセキュアに保存
 */
class AndroidTokenStore(context: Context) : TokenStore {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "auth_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val json = Json { ignoreUnknownKeys = true }
    private val _sessionFlow = MutableStateFlow<Session?>(null)

    init {
        // 起動時に読み込み
        _sessionFlow.value = get()
    }

    override suspend fun get(): Session? {
        val sessionJson = sharedPreferences.getString(KEY_SESSION, null)
            ?: return null
        return runCatching {
            json.decodeFromString<Session>(sessionJson)
        }.getOrNull()
    }

    override fun flow(): Flow<Session?> = _sessionFlow

    override suspend fun save(session: Session) {
        val sessionJson = json.encodeToString(session)
        sharedPreferences.edit()
            .putString(KEY_SESSION, sessionJson)
            .apply()
        _sessionFlow.value = session
    }

    override suspend fun clear() {
        sharedPreferences.edit()
            .remove(KEY_SESSION)
            .apply()
        _sessionFlow.value = null
    }

    companion object {
        private const val KEY_SESSION = "session"
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/data/auth/TokenStore.ios.kt

import kotlinx.cinterop.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import platform.Foundation.*
import platform.Security.*

/**
 * iOS 用 TokenStore 実装
 *
 * Keychain を使用してセキュアに保存
 */
class IosTokenStore : TokenStore {

    private val json = Json { ignoreUnknownKeys = true }
    private val _sessionFlow = MutableStateFlow<Session?>(null)

    init {
        // 起動時に読み込み
        kotlinx.coroutines.runBlocking {
            _sessionFlow.value = get()
        }
    }

    override suspend fun get(): Session? {
        val data = keychainGet(KEY_SESSION) ?: return null
        return runCatching {
            json.decodeFromString<Session>(data)
        }.getOrNull()
    }

    override fun flow(): Flow<Session?> = _sessionFlow

    override suspend fun save(session: Session) {
        val sessionJson = json.encodeToString(session)
        keychainSave(KEY_SESSION, sessionJson)
        _sessionFlow.value = session
    }

    override suspend fun clear() {
        keychainDelete(KEY_SESSION)
        _sessionFlow.value = null
    }

    // Keychain 操作のヘルパー関数
    @OptIn(ExperimentalForeignApi::class)
    private fun keychainSave(key: String, value: String) {
        keychainDelete(key)

        val data = value.encodeToByteArray().toNSData()
        val query = mapOf(
            kSecClass to kSecClassGenericPassword,
            kSecAttrAccount to key,
            kSecValueData to data,
            kSecAttrAccessible to kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ).toCFDictionary()

        SecItemAdd(query, null)
    }

    @OptIn(ExperimentalForeignApi::class)
    private fun keychainGet(key: String): String? {
        val query = mapOf(
            kSecClass to kSecClassGenericPassword,
            kSecAttrAccount to key,
            kSecReturnData to kCFBooleanTrue,
            kSecMatchLimit to kSecMatchLimitOne
        ).toCFDictionary()

        memScoped {
            val result = alloc<CFTypeRefVar>()
            val status = SecItemCopyMatching(query, result.ptr)

            if (status == errSecSuccess) {
                val data = result.value as? NSData ?: return null
                return data.toByteArray().decodeToString()
            }
        }
        return null
    }

    @OptIn(ExperimentalForeignApi::class)
    private fun keychainDelete(key: String) {
        val query = mapOf(
            kSecClass to kSecClassGenericPassword,
            kSecAttrAccount to key
        ).toCFDictionary()

        SecItemDelete(query)
    }

    companion object {
        private const val KEY_SESSION = "com.example.shared.session"
    }
}

/**
 * ByteArray → NSData 変換
 */
@OptIn(ExperimentalForeignApi::class)
private fun ByteArray.toNSData(): NSData {
    return usePinned { pinned ->
        NSData.dataWithBytes(pinned.addressOf(0), size.toULong())
    }
}

/**
 * NSData → ByteArray 変換
 */
@OptIn(ExperimentalForeignApi::class)
private fun NSData.toByteArray(): ByteArray {
    return ByteArray(length.toInt()).apply {
        usePinned { pinned ->
            memcpy(pinned.addressOf(0), bytes, length)
        }
    }
}

/**
 * Map → CFDictionary 変換
 *
 * Keychain API に渡す CFDictionary を生成
 */
@OptIn(ExperimentalForeignApi::class)
private fun Map<CFStringRef?, Any?>.toCFDictionary(): CFDictionaryRef? {
    val keys = this.keys.toList()
    val values = this.values.map { value ->
        when (value) {
            is String -> CFBridgingRetain(value as NSString)
            is NSData -> CFBridgingRetain(value)
            is Boolean -> if (value) kCFBooleanTrue else kCFBooleanFalse
            else -> value as CFTypeRef?
        }
    }

    return memScoped {
        val keysArray = allocArrayOf(*keys.toTypedArray())
        val valuesArray = allocArrayOf(*values.toTypedArray())

        CFDictionaryCreate(
            kCFAllocatorDefault,
            keysArray.reinterpret(),
            valuesArray.reinterpret(),
            keys.size.toLong(),
            null,
            null
        )
    }
}
```

```kotlin
// iosMain - 必要な import 文
import kotlinx.cinterop.*
import platform.CoreFoundation.*
import platform.Foundation.*
import platform.Security.*
import platform.darwin.memcpy
```

### DI 設定（Koin）

```kotlin
// commonMain/kotlin/com/example/shared/di/AuthModule.kt

import org.koin.core.module.dsl.singleOf
import org.koin.dsl.bind
import org.koin.dsl.module

val authModule = module {

    // AuthRepository
    single<AuthRepository> {
        AuthRepositoryImpl(
            tokenStore = get(),
            authRemoteDataSource = get(),
            coroutineScope = get()
        )
    }

    // AuthRemoteDataSource（認証なしクライアントを使用）
    single<AuthRemoteDataSource> {
        AuthRemoteDataSourceImpl(
            unauthenticatedClient = get(named("unauthenticated")),
            baseUrl = get(named("baseUrl"))
        )
    }

    // HttpClient（認証付き）
    single(named("authenticated")) {
        HttpClientFactory(
            tokenStore = get(),
            authRepository = get(),
            engine = get()
        ).createAuthenticatedClient()
    }

    // HttpClient（認証なし）
    single(named("unauthenticated")) {
        HttpClientFactory(
            tokenStore = get(),
            authRepository = get(),
            engine = get()
        ).createUnauthenticatedClient()
    }
}
```

```kotlin
// androidMain/kotlin/com/example/shared/di/PlatformAuthModule.android.kt

actual val platformAuthModule = module {
    single<TokenStore> {
        AndroidTokenStore(context = get())
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/di/PlatformAuthModule.ios.kt

actual val platformAuthModule = module {
    single<TokenStore> {
        IosTokenStore()
    }
}
```

---

## エージェント向けタスク分解

### 実装ステップ チェックリスト

#### Phase 1: データモデル定義

- [ ] `Session` data class を作成
  - accessToken, refreshToken, expiresAt, authType, userId, scopes
  - isExpired(), canRefresh プロパティ
- [ ] `AuthType` enum を作成
- [ ] `LoginMethod` sealed class を作成
  - EmailPassword, GoogleIdToken, AppleIdToken, SsoAuthCode, Custom
- [ ] `SessionState` sealed class を作成
  - LoggedOut, LoggedIn, Refreshing, ExpiredOrInvalid

#### Phase 2: インターフェース定義

- [ ] `TokenStore` interface を作成
  - get(), flow(), save(), clear()
- [ ] `AuthRepository` interface を作成
  - sessionState, login(), refresh(), logout(), getCurrentSession()
- [ ] `AuthRemoteDataSource` interface を作成
  - loginWithEmail(), loginWithGoogle(), loginWithApple(), loginWithSso(), refreshToken(), logout()

#### Phase 3: Ktor 認証プラグイン

- [ ] `AuthPlugin` を作成
  - AuthPluginConfig クラス
  - onRequest で Authorization ヘッダー付与
  - on(Send) で 401 検知 → refresh → retry
  - Mutex による排他制御
- [ ] `SkipAuthKey` と `skipAuth()` 拡張関数
- [ ] `HttpClientFactory` を作成
  - createAuthenticatedClient()
  - createUnauthenticatedClient()

#### Phase 4: 例外設計

- [ ] `AuthException` sealed class を作成
  - NotLoggedIn, InvalidCredentials, TokenInvalid, RefreshNotSupported, RefreshFailed, AccountLocked, Network, Unknown

#### Phase 5: TokenStore 実装（expect/actual）

- [ ] Android: `AndroidTokenStore` を作成
  - EncryptedSharedPreferences を使用
- [ ] iOS: `IosTokenStore` を作成
  - Keychain を使用

#### Phase 6: AuthRepository 実装

- [ ] `AuthRepositoryImpl` を作成
  - login() で LoginMethod に応じた API 呼び出し
  - refresh() で Mutex 排他制御
  - logout() でサーバー通知 + TokenStore クリア
  - sessionState の更新ロジック

#### Phase 7: API モデル & リモートデータソース

- [ ] `TokenResponse`, `LoginRequest`, `RefreshTokenRequest` を作成
- [ ] `AuthRemoteDataSourceImpl` を作成
  - 認証なしクライアントを使用

#### Phase 8: DI 設定

- [ ] `authModule` を作成（共通）
- [ ] `platformAuthModule` を作成（Android/iOS）

#### Phase 9: ViewModel

- [ ] `LoginViewModel` を作成
- [ ] `AuthStateViewModel` を作成（SessionState 監視用）

#### Phase 10: テスト

- [ ] `FakeTokenStore` を作成
- [ ] `FakeAuthRemoteDataSource` を作成
- [ ] `AuthRepositoryImpl` のユニットテスト
- [ ] `AuthPlugin` のユニットテスト（MockEngine 使用）

---

## 参考リンク

### 公式ドキュメント

- [Ktor Client Authentication](https://ktor.io/docs/auth.html)
- [Ktor Client Plugins](https://ktor.io/docs/client-plugins.html)
- [kotlinx.coroutines Mutex](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.sync/-mutex/)

### セキュリティ

- [Android EncryptedSharedPreferences](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

### OAuth/PKCE

- [OAuth 2.0 for Mobile & Native Apps](https://datatracker.ietf.org/doc/html/rfc8252)
- [PKCE Extension](https://datatracker.ietf.org/doc/html/rfc7636)

---

## 関連ドキュメント

- [kmp-architecture.md](kmp-architecture.md) - KMP 全体のアーキテクチャ
- [coroutines.md](coroutines.md) - Kotlin Coroutines ベストプラクティス
