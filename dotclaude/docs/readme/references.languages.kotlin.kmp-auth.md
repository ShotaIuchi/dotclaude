# KMP 認証ベストプラクティスガイド

KMP（Kotlin Multiplatform）+ Ktor での認証実装のベストプラクティス。
複数のログイン方式のサポート、トークン管理、標準的な 401 → リフレッシュ → リトライパターンの実装ガイド。

---

## 概要

このガイドでは、KMP プロジェクトにおける認証機能の実装パターンを解説します。主な目標は以下の通りです：

1. **認証を shared モジュール内で完結** - API 通信、トークン付与、401 → リフレッシュ → リトライを共通コードで実装
2. **ログイン方式の違いをカプセル化** - ネットワーク層は `Session` のみを見る
3. **Android/iOS で一貫した動作** - 同じビジネスロジック、同じエラーハンドリング
4. **同時 401 でも破綻しない** - Mutex で複数のリフレッシュトリガーを防止

---

## アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────────────────┐
│                     プラットフォーム UI Layer                          │
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
│  │  │   - login/logout 操作を AuthRepository に委譲        │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                 │                                    │
│                                 ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                              │   │
│  │                                                               │   │
│  │  ┌───────────────────┐  ┌───────────────────────────────┐   │   │
│  │  │   TokenStore      │  │   AuthRepositoryImpl          │   │   │
│  │  │   (expect/actual) │  │   - ログイン方式ごとの処理     │   │   │
│  │  │   - get/save/clear│  │   - リフレッシュロジック       │   │   │
│  │  └───────────────────┘  └───────────────────────────────┘   │   │
│  │                                │                              │   │
│  │                                ▼                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │   Ktor HttpClient + AuthPlugin                      │    │   │
│  │  │   - Authorization ヘッダーの自動付与                 │    │   │
│  │  │   - 401 検知 → リフレッシュ → リトライ               │    │   │
│  │  │   - Mutex による多重リフレッシュ防止                 │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    プラットフォーム固有 (expect/actual)               │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │ TokenStore.android   │        │ TokenStore.ios       │          │
│  │ (EncryptedSharedPref)│        │ (Keychain)           │          │
│  └──────────────────────┘        └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## データモデル

### Session

```kotlin
// commonMain/kotlin/com/example/shared/domain/model/Session.kt

/**
 * 認証セッション
 *
 * ログイン方式に関係なく統一されたセッション情報を保持
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
     */
    fun isExpired(now: Instant = Clock.System.now()): Boolean {
        return expiresAt?.let { now >= it } ?: false
    }

    /**
     * リフレッシュ可能かどうか
     */
    val canRefresh: Boolean
        get() = refreshToken != null
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
     * Google サインイン（ID Token 方式）
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
     * ログイン済み
     */
    data class LoggedIn(val session: Session) : SessionState()

    /**
     * トークンリフレッシュ中
     *
     * この状態では API リクエストは待機すべき
     */
    data class Refreshing(val session: Session) : SessionState()

    /**
     * セッション無効（再ログイン必要）
     *
     * リフレッシュ失敗時にこの状態に遷移
     */
    data class ExpiredOrInvalid(val reason: String? = null) : SessionState()
}
```

---

## インターフェース定義

### TokenStore

```kotlin
// commonMain/kotlin/com/example/shared/data/auth/TokenStore.kt

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

/**
 * 認証リポジトリ
 *
 * ログイン/ログアウト/リフレッシュ操作とセッション状態管理
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
     * トークンリフレッシュ
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

## Ktor 認証プラグイン

### 設計ポイント

1. **Authorization ヘッダーの自動付与** - TokenStore からトークンを取得しリクエストに付与
2. **401 検知 → リフレッシュ → リトライ** - 401 レスポンス時に自動的にリフレッシュを試行
3. **Mutex による多重リフレッシュ防止** - 同時に 401 を受けても 1 回だけリフレッシュ
4. **リフレッシュ API のループ防止** - リフレッシュ API 自体には認証プラグインを適用しない

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

    /** ログインしていない */
    class NotLoggedIn : AuthException("ログインしていません")

    /** 認証情報が無効 */
    class InvalidCredentials(message: String = "認証情報が無効です") : AuthException(message)

    /** トークンが無効または期限切れ */
    class TokenInvalid(message: String = "トークンが無効または期限切れです") : AuthException(message)

    /** リフレッシュがサポートされていない */
    class RefreshNotSupported : AuthException("この認証タイプではリフレッシュがサポートされていません")

    /** リフレッシュ失敗（再ログイン必要） */
    class RefreshFailed(cause: Throwable? = null) : AuthException("トークンのリフレッシュに失敗しました", cause)

    /** アカウントがロックされている */
    class AccountLocked(message: String = "アカウントがロックされています") : AuthException(message)

    /** ネットワークエラー */
    class Network(cause: Throwable) : AuthException("認証中にネットワークエラーが発生しました", cause)

    /** 不明なエラー */
    class Unknown(cause: Throwable) : AuthException("不明な認証エラー", cause)
}
```

---

## プラットフォーム固有実装

### TokenStore

- **Android**: `EncryptedSharedPreferences` を使用してセキュアに保存
- **iOS**: `Keychain` を使用してセキュアに保存

---

## 実装チェックリスト

### Phase 1: データモデル定義

- [ ] `Session` データクラスを作成
- [ ] `AuthType` enum を作成
- [ ] `LoginMethod` sealed class を作成
- [ ] `SessionState` sealed class を作成

### Phase 2: インターフェース定義

- [ ] `TokenStore` インターフェースを作成
- [ ] `AuthRepository` インターフェースを作成
- [ ] `AuthRemoteDataSource` インターフェースを作成

### Phase 3: Ktor 認証プラグイン

- [ ] `AuthPlugin` を作成
- [ ] `SkipAuthKey` と `skipAuth()` 拡張関数
- [ ] `HttpClientFactory` を作成

### Phase 4: 例外設計

- [ ] `AuthException` sealed class を作成

### Phase 5: TokenStore 実装 (expect/actual)

- [ ] Android: `AndroidTokenStore` を作成（EncryptedSharedPreferences 使用）
- [ ] iOS: `IosTokenStore` を作成（Keychain 使用）

### Phase 6: AuthRepository 実装

- [ ] `AuthRepositoryImpl` を作成

### Phase 7: DI 設定

- [ ] `authModule`（共通）を作成
- [ ] `platformAuthModule`（Android/iOS）を作成

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
