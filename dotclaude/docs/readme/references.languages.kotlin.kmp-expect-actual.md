# KMP expect/actual パターン

共通インターフェースの背後にプラットフォーム固有の実装を抽象化するパターン。

---

## 概要

`expect/actual` は Kotlin Multiplatform の核となる機能で、共通コードでインターフェースを宣言し（expect）、各プラットフォームで具体的な実装を提供（actual）できます。これによりプラットフォーム固有の機能にアクセスしながら、共有コードベースを維持できます。

---

## 基本的な expect/actual

### プラットフォーム情報

```kotlin
// commonMain/kotlin/com/example/shared/core/platform/Platform.kt

/**
 * プラットフォーム情報（expect 宣言）
 */
expect class Platform() {
    val name: String
    val version: String
}

/**
 * プラットフォーム固有ユーティリティ
 */
expect fun getPlatformName(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/platform/Platform.android.kt

/**
 * Android 実装
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
 * iOS 実装
 */
actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName()
    actual val version: String = UIDevice.currentDevice.systemVersion
}

actual fun getPlatformName(): String =
    "${UIDevice.currentDevice.systemName()} ${UIDevice.currentDevice.systemVersion}"
```

---

## ネットワーク監視

```kotlin
// commonMain/kotlin/com/example/shared/core/network/NetworkMonitor.kt

import kotlinx.coroutines.flow.Flow

/**
 * ネットワーク状態監視（expect 宣言）
 *
 * 注意: actual 実装ではプラットフォーム固有のコンストラクタパラメータ
 * （例: Android の Context）が必要な場合があります。これらは通常
 * Koin などの依存性注入（DI）フレームワークを介して提供されます。
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
 * Android 実装
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

        // 初期状態
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
 * iOS 実装
 *
 * 注意: nw_path_monitor は不要になった時点で適切にキャンセルする必要があります。
 * コルーチンで使用する場合、awaitClose ブロックがキャンセルを処理します。
 * 非 Flow 使用の場合は、リソースリークを防ぐために cancel() を呼び出してください。
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
     * ネットワークモニターをキャンセルしてリソースを解放
     * モニターが不要になったら呼び出してください
     */
    fun cancel() {
        nw_path_monitor_cancel(monitor)
    }
}
```

---

## UUID 生成

```kotlin
// commonMain/kotlin/com/example/shared/core/util/Uuid.kt

/**
 * UUID 生成（expect 宣言）
 */
expect fun randomUUID(): String
```

```kotlin
// androidMain/kotlin/com/example/shared/core/util/Uuid.android.kt

import java.util.UUID

/**
 * Android 実装
 */
actual fun randomUUID(): String = UUID.randomUUID().toString()
```

```kotlin
// iosMain/kotlin/com/example/shared/core/util/Uuid.ios.kt

import platform.Foundation.NSUUID

/**
 * iOS 実装
 */
actual fun randomUUID(): String = NSUUID().UUIDString
```

---

## Desktop (JVM) 実装例

```kotlin
// jvmMain/kotlin/com/example/shared/core/platform/Platform.jvm.kt

/**
 * Desktop/JVM 実装
 */
actual class Platform actual constructor() {
    actual val name: String = "JVM"
    actual val version: String = System.getProperty("java.version") ?: "unknown"
}

actual fun getPlatformName(): String = "JVM ${System.getProperty("java.version")}"
```

---

## ベストプラクティス

- プラットフォーム固有の実装を最小限に抑える
- まず共通インターフェースを設計
- actual 実装はプラットフォームのベストプラクティスに従う
- テスト用に commonTest で Fake 実装を準備

### エラーハンドリング

- 失敗する可能性のある操作には `runCatching` または `Result` 型を使用
- クロスプラットフォームのエラーハンドリングのために `commonMain` で共通の例外型を定義
- プラットフォーム固有の例外を共通の例外型でラップ

### テスト戦略

- ユニットテスト用に `commonTest` で `Fake` 実装を作成
- モックを容易にするためにインターフェースベースの設計を使用
- actual 実装はプラットフォーム固有のテストソースセットで別途テスト

### パフォーマンス考慮事項

- `actual` 実装でブロッキング呼び出しを避け、サスペンド関数を優先
- パフォーマンスクリティカルな操作にはプラットフォームネイティブ API を使用
- 高コストなプラットフォームリソースには遅延初期化を検討
