# KMP Authentication Best Practices Guide

Best practices for implementing authentication with KMP (Kotlin Multiplatform) + Ktor.
A guide for implementing multiple login method support, token management, and the standard 401 -> refresh -> retry pattern.

---

## Table of Contents

1. [Goals](#goals)
2. [Architecture Overview](#architecture-overview)
3. [Data Models](#data-models)
4. [Interface Definitions](#interface-definitions)
5. [Ktor Authentication Plugin Implementation](#ktor-authentication-plugin-implementation)
6. [Design Guidelines for Multiple Login Methods](#design-guidelines-for-multiple-login-methods)
7. [Directory Structure Example](#directory-structure-example)
8. [Exception Design](#exception-design)
9. [Implementation Code Examples](#implementation-code-examples)
10. [Task Breakdown for Agents](#task-breakdown-for-agents)

---

## Goals

### Requirements to Achieve

1. **Complete authentication within the shared module**
   - Implement all API communication, token attachment, and 401 -> refresh -> retry in common code
   - Platform-specific code is limited to TokenStore persistence only

2. **Encapsulate login method differences**
   - Network layer only sees `Session`
   - Login method differences are consolidated in `AuthRepository.login()`
   - Refresh logic differences are consolidated in `AuthRepository.refresh()`

3. **Consistent behavior on Android/iOS**
   - Same business logic, same error handling
   - Only UI layer is platform-specific

4. **Handle concurrent 401s without breaking**
   - Mutex prevents multiple refresh triggers
   - Requests during refresh wait and retry

---

## Architecture Overview

### Layer Structure

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
│  │  │   - Observes SessionState                           │    │   │
│  │  │   - Delegates login/logout operations to AuthRepository │   │
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
│  │  │   (expect/actual) │  │   - Per-login-method processing │   │   │
│  │  │   - get/save/clear│  │   - Refresh logic              │   │   │
│  │  └───────────────────┘  └───────────────────────────────┘   │   │
│  │                                │                              │   │
│  │                                ▼                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   Ktor HttpClient + AuthPlugin                      │    │   │
│  │  │   - Automatic Authorization header attachment       │    │   │
│  │  │   - 401 detection → refresh → retry                 │    │   │
│  │  │   - Multiple refresh prevention with Mutex          │    │   │
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

### Separation of Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **UI** | Login screen display, screen navigation based on SessionState |
| **ViewModel** | SessionState observation, triggering login operations |
| **AuthRepository** | Per-login-method processing, refresh logic, SessionState management |
| **TokenStore** | Token persistence (platform-specific) |
| **HttpClient + AuthPlugin** | Authorization header attachment, 401 → refresh → retry |

---

## Data Models

### Session

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/Session.kt

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable

/**
 * Authentication Session
 *
 * Holds unified session information regardless of login method
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
     * Whether the access token is expired
     *
     * If expiresAt is null, it is not considered expired
     */
    fun isExpired(now: Instant = Clock.System.now()): Boolean {
        return expiresAt?.let { now >= it } ?: false
    }

    /**
     * Whether refresh is possible
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
 * Authentication Type
 *
 * Identifies which method was used to log in the session
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
 * Login Method
 *
 * Sealed class holding parameters required for each login method
 */
sealed class LoginMethod {

    /**
     * Email/Password Authentication
     */
    data class EmailPassword(
        val email: String,
        val password: String
    ) : LoginMethod()

    /**
     * Google Sign-In (ID Token method)
     */
    data class GoogleIdToken(
        val idToken: String
    ) : LoginMethod()

    /**
     * Apple Sign In (ID Token method)
     */
    data class AppleIdToken(
        val idToken: String,
        val authorizationCode: String?,
        val fullName: String?
    ) : LoginMethod()

    /**
     * SSO (Authorization Code method)
     */
    data class SsoAuthCode(
        val provider: String,
        val authorizationCode: String,
        val codeVerifier: String?  // When using PKCE
    ) : LoginMethod()

    /**
     * Custom Authentication
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
 * Session State
 *
 * UI layer observes this state to determine screen navigation
 */
sealed class SessionState {

    /**
     * Logged out state
     */
    object LoggedOut : SessionState()

    /**
     * Logged in
     */
    data class LoggedIn(
        val session: Session
    ) : SessionState()

    /**
     * Token refreshing
     *
     * API requests should wait during this state
     */
    data class Refreshing(
        val session: Session
    ) : SessionState()

    /**
     * Session invalid (re-login required)
     *
     * Transitions to this state when refresh fails
     */
    data class ExpiredOrInvalid(
        val reason: String? = null
    ) : SessionState()
}
```

---

## Interface Definitions

### TokenStore

```kotlin
// commonMain/kotlin/com/example/shared/data/auth/TokenStore.kt

import kotlinx.coroutines.flow.Flow

/**
 * Token Persistence Store
 *
 * Provides platform-specific implementation via expect/actual
 */
interface TokenStore {

    /**
     * Get current session
     */
    suspend fun get(): Session?

    /**
     * Observe session changes
     */
    fun flow(): Flow<Session?>

    /**
     * Save session
     */
    suspend fun save(session: Session)

    /**
     * Clear session
     */
    suspend fun clear()
}
```

### AuthRepository

```kotlin
// commonMain/kotlin/com/example/shared/domain/repository/AuthRepository.kt

import kotlinx.coroutines.flow.StateFlow

/**
 * Authentication Repository
 *
 * Login/logout/refresh operations and session state management
 */
interface AuthRepository {

    /**
     * Current session state
     */
    val sessionState: StateFlow<SessionState>

    /**
     * Login
     *
     * @param method Login method and credentials
     * @return Session on success, exception on failure
     */
    suspend fun login(method: LoginMethod): Result<Session>

    /**
     * Token refresh
     *
     * Often called internally, but can also be called explicitly
     *
     * @return New Session on success, exception on failure
     */
    suspend fun refresh(): Result<Session>

    /**
     * Logout
     *
     * Server logout notification and local session clearing
     */
    suspend fun logout()

    /**
     * Get current session
     */
    suspend fun getCurrentSession(): Session?
}
```

---

## Ktor Authentication Plugin Implementation

### Design Points

1. **Automatic Authorization header attachment**
   - Retrieve token from TokenStore and attach to request

2. **401 detection → refresh → retry**
   - Automatically attempt refresh when receiving 401 response
   - Retry original request after successful refresh

3. **Multiple refresh prevention with Mutex**
   - Even if concurrent requests receive 401 simultaneously, refresh occurs only once

4. **Refresh API loop prevention**
   - Do not apply authentication plugin to the refresh API itself
   - Use a dedicated HttpClient

### AuthPlugin Implementation

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
 * Authentication plugin configuration
 */
class AuthPluginConfig {
    var tokenStore: TokenStore? = null
    var refreshTokens: (suspend () -> Result<Session>)? = null
    var onSessionExpired: (suspend () -> Unit)? = null
}

/**
 * Ktor Authentication Plugin
 *
 * - Automatic Authorization header attachment
 * - 401 → refresh → retry
 * - Multiple refresh prevention with Mutex
 */
val AuthPlugin = createClientPlugin("AuthPlugin", ::AuthPluginConfig) {

    val tokenStore = pluginConfig.tokenStore
        ?: throw IllegalStateException("TokenStore must be configured")
    val refreshTokens = pluginConfig.refreshTokens
        ?: throw IllegalStateException("refreshTokens must be configured")
    val onSessionExpired = pluginConfig.onSessionExpired

    val refreshMutex = Mutex()

    // Before sending request: attach Authorization header
    onRequest { request, _ ->
        // Do not apply to refresh API
        if (request.attributes.getOrNull(SkipAuthKey) == true) {
            return@onRequest
        }

        val session = tokenStore.get()
        if (session != null) {
            request.bearerAuth(session.accessToken)
        }
    }

    // After receiving response: if 401, refresh → retry
    on(Send) { request ->
        // Do not apply to refresh API
        if (request.attributes.getOrNull(SkipAuthKey) == true) {
            return@on proceed(request)
        }

        val originalResponse = proceed(request)

        // Return as-is if not 401
        if (originalResponse.status != HttpStatusCode.Unauthorized) {
            return@on originalResponse
        }

        // Attempt refresh (with Mutex for exclusive control)
        val refreshResult = refreshMutex.withLock {
            // Check again as another request may have already refreshed
            val currentSession = tokenStore.get()
            val originalToken = request.headers[HttpHeaders.Authorization]
                ?.removePrefix("Bearer ")

            // No refresh needed if token was already updated
            if (currentSession != null && currentSession.accessToken != originalToken) {
                Result.success(currentSession)
            } else {
                refreshTokens()
            }
        }

        when {
            refreshResult.isSuccess -> {
                // Retry with new token
                val newSession = refreshResult.getOrThrow()
                val retryRequest = HttpRequestBuilder().apply {
                    takeFrom(request)
                    bearerAuth(newSession.accessToken)
                }
                proceed(retryRequest.build())
            }
            else -> {
                // Refresh failed → notify session expiration
                onSessionExpired?.invoke()
                originalResponse
            }
        }
    }
}

/**
 * Key for skipping authentication
 */
val SkipAuthKey = AttributeKey<Boolean>("SkipAuth")

/**
 * Skip authentication for this request
 */
fun HttpRequestBuilder.skipAuth() {
    attributes.put(SkipAuthKey, true)
}
```

### HttpClient Configuration

```kotlin
// commonMain/kotlin/com/example/shared/data/network/HttpClientFactory.kt

import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * HttpClient Factory
 */
class HttpClientFactory(
    private val tokenStore: TokenStore,
    private val authRepository: AuthRepository,
    private val engine: HttpClientEngine
) {
    /**
     * Create authenticated HttpClient
     */
    fun createAuthenticatedClient(): HttpClient {
        return HttpClient(engine) {
            // JSON serialization
            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                    isLenient = true
                    encodeDefaults = true
                })
            }

            // Logging (for debugging)
            install(Logging) {
                level = LogLevel.HEADERS
            }

            // Timeout settings
            install(HttpTimeout) {
                requestTimeoutMillis = 30_000
                connectTimeoutMillis = 10_000
            }

            // Authentication plugin
            install(AuthPlugin) {
                this.tokenStore = this@HttpClientFactory.tokenStore
                this.refreshTokens = {
                    authRepository.refresh()
                }
                this.onSessionExpired = {
                    // Update SessionState to ExpiredOrInvalid
                    // May not need to do anything here if handled within AuthRepository
                }
            }
        }
    }

    /**
     * Create unauthenticated HttpClient (for refresh API)
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

### Refresh API Loop Prevention

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/AuthRemoteDataSource.kt

/**
 * Authentication API Remote Data Source
 *
 * Important: Use unauthenticated HttpClient for refresh API
 */
class AuthRemoteDataSourceImpl(
    private val unauthenticatedClient: HttpClient,  // Unauthenticated client
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

    // Other login method APIs also use unauthenticatedClient
}
```

---

## Design Guidelines for Multiple Login Methods

### Principles

1. **Network layer only sees Session**
   - HttpClient only uses `Session.accessToken`
   - Unaware of login method differences

2. **Encapsulate method differences in AuthRepository.login()**
   - Call appropriate API based on `LoginMethod` type
   - Convert results to unified `Session`

3. **Encapsulate refresh differences in AuthRepository.refresh()**
   - Some authentication methods may have different refresh behavior
   - Execute appropriate refresh logic based on AuthType

### AuthRepository Implementation Example

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
        // Observe TokenStore changes and update SessionState
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

                // Notify that refresh is in progress
                _sessionState.value = SessionState.Refreshing(currentSession)

                val response = authRemoteDataSource.refreshToken(
                    refreshToken = currentSession.refreshToken!!
                )

                val newSession = response.toSession(authType = currentSession.authType)
                tokenStore.save(newSession)
                newSession
            }.onFailure { e ->
                // Session invalid on refresh failure
                _sessionState.value = SessionState.ExpiredOrInvalid(e.message)
            }
        }
    }

    override suspend fun logout() {
        runCatching {
            val session = tokenStore.get()
            if (session != null) {
                // Notify server of logout (continue even if fails)
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

## Directory Structure Example

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
│   │   │   ├── AuthPlugin.kt              # Ktor authentication plugin
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

## Exception Design

### AuthException Hierarchy

```kotlin
// commonMain/kotlin/com/example/shared/data/auth/AuthException.kt

/**
 * Authentication-related exceptions
 */
sealed class AuthException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    /**
     * Not logged in
     */
    class NotLoggedIn : AuthException("Not logged in")

    /**
     * Invalid credentials
     */
    class InvalidCredentials(
        message: String = "Invalid credentials"
    ) : AuthException(message)

    /**
     * Token is invalid or expired
     */
    class TokenInvalid(
        message: String = "Token is invalid or expired"
    ) : AuthException(message)

    /**
     * Refresh is not supported
     */
    class RefreshNotSupported : AuthException("Refresh is not supported for this auth type")

    /**
     * Refresh failed (re-login required)
     */
    class RefreshFailed(
        cause: Throwable? = null
    ) : AuthException("Failed to refresh token", cause)

    /**
     * Account is locked
     */
    class AccountLocked(
        message: String = "Account is locked"
    ) : AuthException(message)

    /**
     * Network error
     */
    class Network(
        cause: Throwable
    ) : AuthException("Network error during authentication", cause)

    /**
     * Unknown error
     */
    class Unknown(
        cause: Throwable
    ) : AuthException("Unknown authentication error", cause)
}
```

### Error Handling in UI Layer

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
                            "Email address or password is incorrect"
                        is AuthException.AccountLocked ->
                            "Account is locked"
                        is AuthException.Network ->
                            "A network error occurred"
                        else ->
                            "Login failed"
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

## Implementation Code Examples

### TokenStore (expect/actual)

```kotlin
// commonMain: interface is already defined in data/auth/TokenStore.kt

// androidMain/kotlin/com/example/shared/data/auth/TokenStore.android.kt

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Android TokenStore implementation
 *
 * Uses EncryptedSharedPreferences for secure storage
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
        // Load on startup
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
 * iOS TokenStore implementation
 *
 * Uses Keychain for secure storage
 */
class IosTokenStore : TokenStore {

    private val json = Json { ignoreUnknownKeys = true }
    private val _sessionFlow = MutableStateFlow<Session?>(null)

    init {
        // Load on startup
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

    // Keychain operation helper functions
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
 * ByteArray → NSData conversion
 */
@OptIn(ExperimentalForeignApi::class)
private fun ByteArray.toNSData(): NSData {
    return usePinned { pinned ->
        NSData.dataWithBytes(pinned.addressOf(0), size.toULong())
    }
}

/**
 * NSData → ByteArray conversion
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
 * Map → CFDictionary conversion
 *
 * Generates CFDictionary to pass to Keychain API
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
// iosMain - required imports
import kotlinx.cinterop.*
import platform.CoreFoundation.*
import platform.Foundation.*
import platform.Security.*
import platform.darwin.memcpy
```

### DI Configuration (Koin)

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

    // AuthRemoteDataSource (uses unauthenticated client)
    single<AuthRemoteDataSource> {
        AuthRemoteDataSourceImpl(
            unauthenticatedClient = get(named("unauthenticated")),
            baseUrl = get(named("baseUrl"))
        )
    }

    // HttpClient (authenticated)
    single(named("authenticated")) {
        HttpClientFactory(
            tokenStore = get(),
            authRepository = get(),
            engine = get()
        ).createAuthenticatedClient()
    }

    // HttpClient (unauthenticated)
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

## Task Breakdown for Agents

### Implementation Steps Checklist

#### Phase 1: Data Model Definition

- [ ] Create `Session` data class
  - accessToken, refreshToken, expiresAt, authType, userId, scopes
  - isExpired(), canRefresh properties
- [ ] Create `AuthType` enum
- [ ] Create `LoginMethod` sealed class
  - EmailPassword, GoogleIdToken, AppleIdToken, SsoAuthCode, Custom
- [ ] Create `SessionState` sealed class
  - LoggedOut, LoggedIn, Refreshing, ExpiredOrInvalid

#### Phase 2: Interface Definition

- [ ] Create `TokenStore` interface
  - get(), flow(), save(), clear()
- [ ] Create `AuthRepository` interface
  - sessionState, login(), refresh(), logout(), getCurrentSession()
- [ ] Create `AuthRemoteDataSource` interface
  - loginWithEmail(), loginWithGoogle(), loginWithApple(), loginWithSso(), refreshToken(), logout()

#### Phase 3: Ktor Authentication Plugin

- [ ] Create `AuthPlugin`
  - AuthPluginConfig class
  - Attach Authorization header in onRequest
  - Detect 401 → refresh → retry in on(Send)
  - Exclusive control with Mutex
- [ ] `SkipAuthKey` and `skipAuth()` extension function
- [ ] Create `HttpClientFactory`
  - createAuthenticatedClient()
  - createUnauthenticatedClient()

#### Phase 4: Exception Design

- [ ] Create `AuthException` sealed class
  - NotLoggedIn, InvalidCredentials, TokenInvalid, RefreshNotSupported, RefreshFailed, AccountLocked, Network, Unknown

#### Phase 5: TokenStore Implementation (expect/actual)

- [ ] Android: Create `AndroidTokenStore`
  - Use EncryptedSharedPreferences
- [ ] iOS: Create `IosTokenStore`
  - Use Keychain

#### Phase 6: AuthRepository Implementation

- [ ] Create `AuthRepositoryImpl`
  - API call based on LoginMethod in login()
  - Mutex exclusive control in refresh()
  - Server notification + TokenStore clear in logout()
  - sessionState update logic

#### Phase 7: API Models & Remote Data Source

- [ ] Create `TokenResponse`, `LoginRequest`, `RefreshTokenRequest`
- [ ] Create `AuthRemoteDataSourceImpl`
  - Use unauthenticated client

#### Phase 8: DI Configuration

- [ ] Create `authModule` (common)
- [ ] Create `platformAuthModule` (Android/iOS)

#### Phase 9: ViewModel

- [ ] Create `LoginViewModel`
- [ ] Create `AuthStateViewModel` (for SessionState observation)

#### Phase 10: Testing

- [ ] Create `FakeTokenStore`
- [ ] Create `FakeAuthRemoteDataSource`
- [ ] Unit tests for `AuthRepositoryImpl`
- [ ] Unit tests for `AuthPlugin` (using MockEngine)

---

## Reference Links

### Official Documentation

- [Ktor Client Authentication](https://ktor.io/docs/auth.html)
- [Ktor Client Plugins](https://ktor.io/docs/client-plugins.html)
- [kotlinx.coroutines Mutex](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.sync/-mutex/)

### Security

- [Android EncryptedSharedPreferences](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

### OAuth/PKCE

- [OAuth 2.0 for Mobile & Native Apps](https://datatracker.ietf.org/doc/html/rfc8252)
- [PKCE Extension](https://datatracker.ietf.org/doc/html/rfc7636)

---

## Related Documents

- [kmp-architecture.md](kmp-architecture.md) - Overall KMP architecture
- [coroutines.md](coroutines.md) - Kotlin Coroutines Best Practices
