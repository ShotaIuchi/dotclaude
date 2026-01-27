# Kotlin/KMP Feature Patterns

機能別の実装パターン。新機能追加時の参考テンプレート。

---

## Authentication

### トークンベース認証フロー

```
Login → API(/auth/login) → Access Token + Refresh Token
                                    ↓
                          SecureStorage に保存
                                    ↓
                          API リクエストに Authorization ヘッダ付与
                                    ↓
                          401 → Refresh Token で再取得 → 失敗時ログアウト
```

### SecureStorage（expect/actual）

```kotlin
// commonMain
expect class SecureStorage {
    suspend fun save(key: String, value: String)
    suspend fun get(key: String): String?
    suspend fun delete(key: String)
    suspend fun clear()
}

// androidMain — EncryptedSharedPreferences
// iosMain — Keychain Services
```

### AuthRepository パターン

```kotlin
class AuthRepositoryImpl(
    private val api: AuthApi,
    private val secureStorage: SecureStorage,
) : AuthRepository {
    override suspend fun login(email: String, password: String): Result<User> =
        runCatching {
            val response = api.login(LoginRequest(email, password))
            secureStorage.save("access_token", response.accessToken)
            secureStorage.save("refresh_token", response.refreshToken)
            response.user.toDomain()
        }

    override suspend fun refreshToken(): Result<String> =
        runCatching {
            val refresh = secureStorage.get("refresh_token")
                ?: throw AppException.Auth.SessionExpired
            val response = api.refresh(RefreshRequest(refresh))
            secureStorage.save("access_token", response.accessToken)
            response.accessToken
        }
}
```

### Ktor Auth Plugin 統合

```kotlin
install(Auth) {
    bearer {
        loadTokens {
            val access = secureStorage.get("access_token") ?: return@loadTokens null
            val refresh = secureStorage.get("refresh_token") ?: return@loadTokens null
            BearerTokens(access, refresh)
        }
        refreshTokens {
            val result = authRepository.refreshToken()
            result.getOrNull()?.let { newAccess ->
                val refresh = secureStorage.get("refresh_token") ?: return@refreshTokens null
                BearerTokens(newAccess, refresh)
            }
        }
    }
}
```

## Camera

### プラットフォーム抽象化

```kotlin
// commonMain
expect class CameraManager {
    suspend fun takePhoto(): ImageData?
    suspend fun pickFromGallery(): ImageData?
    fun isAvailable(): Boolean
}

data class ImageData(
    val bytes: ByteArray,
    val width: Int,
    val height: Int,
    val mimeType: String,
)
```

### Android 実装

```kotlin
// androidMain
actual class CameraManager(private val context: Context) {
    actual suspend fun takePhoto(): ImageData? {
        // ActivityResultLauncher + FileProvider
        // カメラIntent → 撮影 → Uri → ByteArray変換
    }

    actual suspend fun pickFromGallery(): ImageData? {
        // ActivityResultContracts.PickVisualMedia
    }

    actual fun isAvailable(): Boolean =
        context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
}
```

### iOS 実装

```kotlin
// iosMain
actual class CameraManager {
    actual suspend fun takePhoto(): ImageData? {
        // UIImagePickerController or PHPickerViewController
        // suspendCancellableCoroutine で delegate をラップ
    }

    actual suspend fun pickFromGallery(): ImageData? {
        // PHPickerViewController
    }

    actual fun isAvailable(): Boolean =
        UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera)
}
```

### 権限管理パターン

```kotlin
// commonMain
expect class PermissionManager {
    suspend fun requestCameraPermission(): PermissionResult
    fun checkCameraPermission(): PermissionStatus
}

enum class PermissionStatus { Granted, Denied, NotDetermined }
enum class PermissionResult { Granted, Denied, PermanentlyDenied }
```
