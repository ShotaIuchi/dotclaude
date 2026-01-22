# KMP Error Handling

Common error types and UI error display patterns in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md)

---

## Common Error Types

```kotlin
// commonMain/kotlin/com/example/shared/core/error/AppException.kt

/**
 * Application exception hierarchy
 */
sealed class AppException(
    override val message: String,
    override val cause: Throwable? = null
) : Exception(message, cause) {

    // Network errors
    sealed class Network(message: String, cause: Throwable?) : AppException(message, cause) {
        class NoConnection(cause: Throwable? = null) : Network("No internet connection", cause)
        class Timeout(cause: Throwable? = null) : Network("Request timeout", cause)
        class Server(val code: Int, cause: Throwable? = null) : Network("Server error: $code", cause)
    }

    // Data errors
    sealed class Data(message: String, cause: Throwable?) : AppException(message, cause) {
        class NotFound(message: String = "Data not found") : Data(message, null)
        class Validation(message: String) : Data(message, null)
        class Conflict(message: String) : Data(message, null)
    }

    // Authentication errors
    // Note: Auth errors use object declarations for simplicity since they typically
    // don't carry additional context. If you need to include error codes or metadata,
    // consider converting to data classes: data class Unauthorized(val errorCode: String? = null)
    sealed class Auth(message: String, cause: Throwable?) : AppException(message, cause) {
        object Unauthorized : Auth("Unauthorized", null)
        object SessionExpired : Auth("Session expired", null)
    }

    // Unknown error
    class Unknown(cause: Throwable) : AppException("Unknown error", cause)
}
```

---

## UI Error Model

```kotlin
// commonMain/kotlin/com/example/shared/presentation/model/UiError.kt

/**
 * UI error model
 */
data class UiError(
    val message: String,
    val action: ErrorAction? = null
)

enum class ErrorAction {
    RETRY,
    LOGIN,
    DISMISS
}

/**
 * Throwable → UiError conversion
 */
fun Throwable.toUiError(): UiError {
    return when (this) {
        is AppException.Network.NoConnection -> UiError(
            message = "No internet connection",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Timeout -> UiError(
            message = "Request timed out",
            action = ErrorAction.RETRY
        )
        is AppException.Network.Server -> UiError(
            message = "Server error occurred ($code)",
            action = ErrorAction.RETRY
        )
        is AppException.Auth.Unauthorized -> UiError(
            message = "Authentication required",
            action = ErrorAction.LOGIN
        )
        is AppException.Auth.SessionExpired -> UiError(
            message = "Session has expired",
            action = ErrorAction.LOGIN
        )
        is AppException.Data.NotFound -> UiError(
            message = message,
            action = ErrorAction.DISMISS
        )
        else -> UiError(
            message = "An error occurred",
            action = ErrorAction.DISMISS
        )
    }
}

/**
 * Localization Support
 *
 * For multi-language applications, replace hardcoded strings with localized resources:
 * - Android: Use stringResource(R.string.error_no_connection)
 * - iOS: Use NSLocalizedString or String(localized:) in Swift UI layer
 * - Common: Consider using a StringResources interface with expect/actual for shared strings
 */
```

---

## Ktor Error Handling

> **Version Note**: The `kotlinx.io.IOException` class is available in Kotlin 1.9.20+ with kotlinx-io library.
> For projects using older Kotlin versions, use `java.io.IOException` on JVM/Android targets
> or implement platform-specific exception handling with expect/actual.

```kotlin
// commonMain/kotlin/com/example/shared/data/remote/ApiErrorMapper.kt

/**
 * Map Ktor response to application exception
 */
class ApiErrorMapper {

    fun map(response: HttpResponse): AppException {
        return when (response.status.value) {
            401 -> AppException.Auth.Unauthorized
            403 -> AppException.Auth.Unauthorized
            404 -> AppException.Data.NotFound()
            409 -> AppException.Data.Conflict("Resource already exists")
            in 500..599 -> AppException.Network.Server(response.status.value)
            else -> AppException.Unknown(
                Exception("HTTP ${response.status.value}: ${response.status.description}")
            )
        }
    }

    fun map(throwable: Throwable): AppException {
        return when (throwable) {
            is AppException -> throwable
            is kotlinx.io.IOException -> AppException.Network.NoConnection(throwable)
            is io.ktor.client.plugins.HttpRequestTimeoutException -> AppException.Network.Timeout(throwable)
            else -> AppException.Unknown(throwable)
        }
    }
}
```

---

## Best Practices

- **Define AppException hierarchy**: Create a sealed class hierarchy that represents all possible error states in your application. This provides type-safety and exhaustive when-expression handling, ensuring no error case is accidentally missed.

- **Use common error mapping across platforms**: Centralize error mapping logic in commonMain to ensure consistent error handling behavior across iOS and Android. This reduces platform-specific bugs and simplifies testing.

- **Convert to UI error model**: Transform technical exceptions into user-friendly error messages with appropriate actions. This separation keeps presentation logic clean and allows easy localization of error messages.

- **Implement retry mechanism**: For transient errors (network timeouts, temporary server issues), provide automatic or user-initiated retry capabilities. Consider exponential backoff for automatic retries to avoid overwhelming the server.

---

## Platform-Specific Error Handling

Use expect/actual to handle platform-specific exceptions:

```kotlin
// commonMain/kotlin/com/example/shared/core/error/PlatformErrorMapper.kt

/**
 * Platform-specific error mapper
 */
expect class PlatformErrorMapper() {
    fun mapPlatformException(throwable: Throwable): AppException?
}
```

```kotlin
// androidMain/kotlin/com/example/shared/core/error/PlatformErrorMapper.kt

actual class PlatformErrorMapper actual constructor() {
    actual fun mapPlatformException(throwable: Throwable): AppException? {
        return when (throwable) {
            is java.net.UnknownHostException -> AppException.Network.NoConnection(throwable)
            is java.net.SocketTimeoutException -> AppException.Network.Timeout(throwable)
            is javax.net.ssl.SSLException -> AppException.Network.NoConnection(throwable)
            else -> null
        }
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/core/error/PlatformErrorMapper.kt

actual class PlatformErrorMapper actual constructor() {
    actual fun mapPlatformException(throwable: Throwable): AppException? {
        // iOS network errors are typically wrapped by Ktor
        // Add platform-specific handling as needed
        return when {
            throwable.message?.contains("NSURLErrorDomain") == true ->
                AppException.Network.NoConnection(throwable)
            else -> null
        }
    }
}
