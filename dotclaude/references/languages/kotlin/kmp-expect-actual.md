# KMP expect/actual Pattern

A pattern for abstracting platform-specific implementations behind common interfaces.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [Official Documentation](https://kotlinlang.org/docs/multiplatform-expect-actual.html)

---

## Basic expect/actual

### Platform Information

```kotlin
// commonMain/kotlin/com/example/shared/core/platform/Platform.kt

/**
 * Platform information (expect declaration)
 */
expect class Platform() {
    val name: String
    val version: String
}

/**
 * Platform-specific utility
 */
expect fun getPlatformName(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/platform/Platform.android.kt

/**
 * Android implementation
 */
actual class Platform actual constructor() {
    actual val name: String = "Android"
    actual val version: String = "${android.os.Build.VERSION.SDK_INT}"
}

actual fun getPlatformName(): String = "Android ${android.os.Build.VERSION.SDK_INT}"
```

```kotlin
// iosMain/kotlin/com/example/shared/core/platform/Platform.ios.kt

import platform.UIKit.UIDevice

/**
 * iOS implementation
 */
actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName()
    actual val version: String = UIDevice.currentDevice.systemVersion
}

actual fun getPlatformName(): String =
    "${UIDevice.currentDevice.systemName()} ${UIDevice.currentDevice.systemVersion}"
```

---

## Network Monitoring

```kotlin
// commonMain/kotlin/com/example/shared/core/network/NetworkMonitor.kt

import kotlinx.coroutines.flow.Flow

/**
 * Network state monitoring (expect declaration)
 *
 * Note: The actual implementations may require platform-specific
 * constructor parameters (e.g., Context on Android). These are
 * typically provided via dependency injection (DI) frameworks like Koin.
 */
expect class NetworkMonitor {
    fun isOnline(): Boolean
    fun observeNetworkState(): Flow<Boolean>
}
```

```kotlin
// androidMain/kotlin/com/example/shared/core/network/NetworkMonitor.android.kt

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

/**
 * Android implementation
 */
actual class NetworkMonitor(
    private val context: Context
) {
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    actual fun isOnline(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(true)
            }

            override fun onLost(network: Network) {
                trySend(false)
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(request, callback)

        // Initial state
        trySend(isOnline())

        awaitClose {
            connectivityManager.unregisterNetworkCallback(callback)
        }
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/core/network/NetworkMonitor.ios.kt

import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import platform.Network.*
import platform.darwin.dispatch_get_main_queue

/**
 * iOS implementation
 *
 * Note: The nw_path_monitor must be properly cancelled when no longer needed.
 * When using with coroutines, the awaitClose block handles cancellation.
 * For non-Flow usage, ensure cancel() is called to prevent resource leaks.
 */
actual class NetworkMonitor {
    private val monitor = nw_path_monitor_create()
    private var currentPath: nw_path_t? = null

    init {
        nw_path_monitor_set_update_handler(monitor) { path ->
            currentPath = path
        }
        nw_path_monitor_set_queue(monitor, dispatch_get_main_queue())
        nw_path_monitor_start(monitor)
    }

    actual fun isOnline(): Boolean {
        val path = currentPath ?: return false
        return nw_path_get_status(path) == nw_path_status_satisfied
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        nw_path_monitor_set_update_handler(monitor) { path ->
            val isConnected = nw_path_get_status(path) == nw_path_status_satisfied
            trySend(isConnected)
        }

        awaitClose {
            nw_path_monitor_cancel(monitor)
        }
    }

    /**
     * Cancel the network monitor and release resources.
     * Call this when the monitor is no longer needed.
     */
    fun cancel() {
        nw_path_monitor_cancel(monitor)
    }
}
```

---

## UUID Generation

```kotlin
// commonMain/kotlin/com/example/shared/core/util/Uuid.kt

/**
 * UUID generation (expect declaration)
 */
expect fun randomUUID(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/util/Uuid.android.kt

import java.util.UUID

/**
 * Android implementation
 */
actual fun randomUUID(): String = UUID.randomUUID().toString()
```

```kotlin
// iosMain/kotlin/com/example/shared/core/util/Uuid.ios.kt

import platform.Foundation.NSUUID

/**
 * iOS implementation
 */
actual fun randomUUID(): String = NSUUID().UUIDString
```

---

## Desktop (JVM) Implementation Example

```kotlin
// jvmMain/kotlin/com/example/shared/core/platform/Platform.jvm.kt

/**
 * Desktop/JVM implementation
 */
actual class Platform actual constructor() {
    actual val name: String = "JVM"
    actual val version: String = System.getProperty("java.version") ?: "unknown"
}

actual fun getPlatformName(): String = "JVM ${System.getProperty("java.version")}"
```

```kotlin
// jvmMain/kotlin/com/example/shared/core/network/NetworkMonitor.jvm.kt

import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import java.net.InetSocketAddress
import java.net.Socket

/**
 * Desktop/JVM implementation
 */
actual class NetworkMonitor {
    actual fun isOnline(): Boolean {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress("8.8.8.8", 53), 1500)
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    actual fun observeNetworkState(): Flow<Boolean> = callbackFlow {
        // Simple polling-based implementation for JVM
        // For production, consider using a more sophisticated approach
        val checkInterval = 5000L
        var running = true

        kotlinx.coroutines.launch {
            while (running) {
                trySend(isOnline())
                kotlinx.coroutines.delay(checkInterval)
            }
        }

        awaitClose { running = false }
    }
}
```

---

## Best Practices

- Keep platform-specific implementations to a minimum
- Design common interfaces first
- Follow platform Best Practices for actual implementations
- Prepare Fake implementations for testing in commonTest

### Error Handling

- Use `runCatching` or `Result` types for operations that may fail
- Define common exception types in `commonMain` for cross-platform error handling
- Wrap platform-specific exceptions in common exception types

### Testing Strategy

- Create `Fake` implementations in `commonTest` for unit testing
- Use interface-based design to enable easy mocking
- Test actual implementations separately in platform-specific test source sets

### Performance Considerations

- Avoid blocking calls in `actual` implementations; prefer suspending functions
- Use platform-native APIs for performance-critical operations
- Consider lazy initialization for expensive platform resources
