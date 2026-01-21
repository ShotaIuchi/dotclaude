# KMP カメラ実装ガイド

KMP/CMP でのカメラ機能実装のベストプラクティス。OS ネイティブ機能との役割分担を明確にし、共通化すべき部分と OS に委ねる部分を整理。

---

## 目次

1. [役割分担の原則](#役割分担の原則)
2. [依存関係図](#依存関係図)
3. [ディレクトリ構成](#ディレクトリ構成)
4. [expect/actual 実装](#expectactual-実装)
5. [ViewModel と UiState](#viewmodel-と-uistate)
6. [QR / 画像解析](#qr--画像解析)
7. [判断基準表](#判断基準表)
8. [リアルタイム解析](#リアルタイム解析)
9. [パーミッション管理](#パーミッション管理)
10. [ベストプラクティス一覧](#ベストプラクティス一覧)
11. [エージェント向けタスク分解](#エージェント向けタスク分解)

---

## 役割分担の原則

カメラ機能では、KMP/CMP と OS ネイティブで明確な役割分担を行う。

```
🧠 KMP / CMP = 「どう使うか」（UI・状態・ロジック）
📷 OS ネイティブ = 「どう撮るか」（デバイス制御）
```

### KMP/CMP が担当

| 項目 | 説明 |
|------|------|
| 撮影ボタン UI | ボタン配置、押下状態 |
| フロント/リア切替 | カメラ方向の状態管理 |
| フラッシュ ON/OFF 状態 | フラッシュ設定の状態管理 |
| 撮影中/完了の状態管理 | UiState での状態表現 |
| 撮影結果の処理 | アップロード、解析、保存 |

### OS に任せる

| 項目 | Android | iOS |
|------|---------|-----|
| カメラ起動・停止 | CameraX | AVFoundation |
| プレビュー表示 | PreviewView | AVCaptureVideoPreviewLayer |
| フォーカス・露出 | CameraControl | AVCaptureDevice |
| センサー回転 | ImageAnalysis | AVCaptureConnection |
| Surface 管理 | SurfaceProvider | CALayer |

---

## 依存関係図

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CMP UI Layer                                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   CameraScreen (Compose Multiplatform)                        │   │
│  │   - 撮影ボタン                                                 │   │
│  │   - 設定 UI（フラッシュ、カメラ切替）                           │   │
│  │   - プレビュー領域（expect/actual）                            │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    KMP ViewModel / UseCase                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   CameraViewModel                                             │   │
│  │   - CameraUiState 管理                                        │   │
│  │   - onShutterClick / onToggleFlash / onSwitchCamera           │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    expect CameraController                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   - startPreview()                                            │   │
│  │   - stopPreview()                                             │   │
│  │   - capture(): CameraResult                                   │   │
│  │   - switchCamera()                                            │   │
│  │   - setFlash(enabled: Boolean)                                │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│  actual (Android)           │  │  actual (iOS)               │
│  ┌───────────────────────┐  │  │  ┌───────────────────────┐  │
│  │  AndroidCameraController │  │  │  IOSCameraController  │  │
│  │  (CameraX)             │  │  │  (AVFoundation)        │  │
│  └───────────────────────┘  │  │  └───────────────────────┘  │
└─────────────────────────────┘  └─────────────────────────────┘
```

---

## ディレクトリ構成

```
shared/src/
├── commonMain/kotlin/com/example/shared/
│   ├── camera/
│   │   ├── CameraController.kt        # expect 宣言
│   │   ├── CameraResult.kt            # 共通モデル（撮影結果）
│   │   ├── CameraConfig.kt            # 設定モデル
│   │   └── CameraPermission.kt        # パーミッション抽象化
│   │
│   ├── analysis/
│   │   ├── ImageAnalyzer.kt           # expect 宣言
│   │   └── AnalysisResult.kt          # 解析結果モデル
│   │
│   └── presentation/camera/
│       ├── CameraViewModel.kt
│       ├── CameraUiState.kt
│       └── CameraEvent.kt
│
├── androidMain/kotlin/com/example/shared/
│   ├── camera/
│   │   └── CameraController.android.kt  # actual (CameraX)
│   │
│   └── analysis/
│       └── ImageAnalyzer.android.kt     # actual (ML Kit)
│
└── iosMain/kotlin/com/example/shared/
    ├── camera/
    │   └── CameraController.ios.kt      # actual (AVFoundation)
    │
    └── analysis/
        └── ImageAnalyzer.ios.kt         # actual (Vision)
```

---

## expect/actual 実装

### 共通モデル（commonMain）

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraResult.kt

/**
 * 撮影結果
 */
sealed interface CameraResult {
    /**
     * 撮影成功
     * @param imageData JPEG バイト配列
     * @param width 画像幅
     * @param height 画像高さ
     */
    data class Success(
        val imageData: ByteArray,
        val width: Int,
        val height: Int
    ) : CameraResult

    /**
     * 撮影失敗
     */
    data class Error(val message: String) : CameraResult

    /**
     * キャンセル
     */
    object Cancelled : CameraResult
}
```

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraConfig.kt

/**
 * カメラ設定
 */
data class CameraConfig(
    val facing: CameraFacing = CameraFacing.BACK,
    val flashMode: FlashMode = FlashMode.OFF,
    val aspectRatio: AspectRatio = AspectRatio.RATIO_4_3
)

enum class CameraFacing {
    FRONT, BACK
}

enum class FlashMode {
    OFF, ON, AUTO
}

enum class AspectRatio {
    RATIO_4_3,
    RATIO_16_9
}
```

### CameraController expect 宣言

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraController.kt

/**
 * カメラ制御インターフェース（expect 宣言）
 *
 * プラットフォーム固有の実装を抽象化
 */
expect class CameraController {

    /**
     * プレビュー開始
     */
    suspend fun startPreview()

    /**
     * プレビュー停止
     */
    fun stopPreview()

    /**
     * 写真撮影
     * @return 撮影結果
     */
    suspend fun capture(): CameraResult

    /**
     * カメラ切替（フロント/リア）
     */
    suspend fun switchCamera()

    /**
     * フラッシュ設定
     * @param mode フラッシュモード
     */
    fun setFlashMode(mode: FlashMode)

    /**
     * 現在のカメラ方向を取得
     */
    fun getCurrentFacing(): CameraFacing

    /**
     * リソース解放
     */
    fun release()
}
```

### Android actual 実装（CameraX）

```kotlin
// androidMain/kotlin/com/example/shared/camera/CameraController.android.kt

import android.content.Context
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Android CameraX 実装
 */
actual class CameraController(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner
) {
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageCapture: ImageCapture? = null
    private var preview: Preview? = null
    private var camera: Camera? = null

    private var currentFacing = CameraFacing.BACK
    private var currentFlashMode = FlashMode.OFF

    /**
     * プレビュー開始
     */
    actual suspend fun startPreview() = suspendCancellableCoroutine { cont ->
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases()
                cont.resume(Unit)
            } catch (e: Exception) {
                cont.resumeWithException(e)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    /**
     * プレビュー停止
     */
    actual fun stopPreview() {
        cameraProvider?.unbindAll()
    }

    /**
     * 写真撮影
     */
    actual suspend fun capture(): CameraResult = suspendCancellableCoroutine { cont ->
        val imageCapture = imageCapture ?: run {
            cont.resume(CameraResult.Error("ImageCapture not initialized"))
            return@suspendCancellableCoroutine
        }

        imageCapture.takePicture(
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    val buffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)

                    cont.resume(
                        CameraResult.Success(
                            imageData = bytes,
                            width = image.width,
                            height = image.height
                        )
                    )
                    image.close()
                }

                override fun onError(exception: ImageCaptureException) {
                    cont.resume(CameraResult.Error(exception.message ?: "Capture failed"))
                }
            }
        )
    }

    /**
     * カメラ切替
     */
    actual suspend fun switchCamera() {
        currentFacing = when (currentFacing) {
            CameraFacing.BACK -> CameraFacing.FRONT
            CameraFacing.FRONT -> CameraFacing.BACK
        }
        bindCameraUseCases()
    }

    /**
     * フラッシュ設定
     */
    actual fun setFlashMode(mode: FlashMode) {
        currentFlashMode = mode
        imageCapture?.flashMode = when (mode) {
            FlashMode.OFF -> ImageCapture.FLASH_MODE_OFF
            FlashMode.ON -> ImageCapture.FLASH_MODE_ON
            FlashMode.AUTO -> ImageCapture.FLASH_MODE_AUTO
        }
    }

    /**
     * 現在のカメラ方向
     */
    actual fun getCurrentFacing(): CameraFacing = currentFacing

    /**
     * リソース解放
     */
    actual fun release() {
        cameraProvider?.unbindAll()
        cameraProvider = null
    }

    /**
     * カメラユースケースをバインド
     */
    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return

        val cameraSelector = when (currentFacing) {
            CameraFacing.BACK -> CameraSelector.DEFAULT_BACK_CAMERA
            CameraFacing.FRONT -> CameraSelector.DEFAULT_FRONT_CAMERA
        }

        preview = Preview.Builder().build()

        imageCapture = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .setFlashMode(
                when (currentFlashMode) {
                    FlashMode.OFF -> ImageCapture.FLASH_MODE_OFF
                    FlashMode.ON -> ImageCapture.FLASH_MODE_ON
                    FlashMode.AUTO -> ImageCapture.FLASH_MODE_AUTO
                }
            )
            .build()

        cameraProvider.unbindAll()

        camera = cameraProvider.bindToLifecycle(
            lifecycleOwner,
            cameraSelector,
            preview,
            imageCapture
        )
    }
}
```

### iOS actual 実装（AVFoundation）

```kotlin
// iosMain/kotlin/com/example/shared/camera/CameraController.ios.kt

import kotlinx.cinterop.*
import platform.AVFoundation.*
import platform.CoreMedia.*
import platform.Foundation.*
import platform.UIKit.*
import kotlinx.coroutines.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * iOS AVFoundation 実装
 */
actual class CameraController {
    private val captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput? = null
    private var currentDevice: AVCaptureDevice? = null

    private var currentFacing = CameraFacing.BACK
    private var currentFlashMode = FlashMode.OFF

    private var photoContinuation: CancellableContinuation<CameraResult>? = null

    /**
     * プレビュー開始
     */
    actual suspend fun startPreview() {
        captureSession.beginConfiguration()

        // カメラデバイス取得
        val device = getCamera(currentFacing)
        currentDevice = device

        // 入力設定
        val input = AVCaptureDeviceInput.deviceInputWithDevice(device, null)
        if (captureSession.canAddInput(input)) {
            captureSession.addInput(input)
        }

        // 出力設定
        val output = AVCapturePhotoOutput()
        if (captureSession.canAddOutput(output)) {
            captureSession.addOutput(output)
            photoOutput = output
        }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    /**
     * プレビュー停止
     */
    actual fun stopPreview() {
        captureSession.stopRunning()
    }

    /**
     * 写真撮影
     */
    actual suspend fun capture(): CameraResult = suspendCancellableCoroutine { cont ->
        val output = photoOutput ?: run {
            cont.resume(CameraResult.Error("PhotoOutput not initialized"))
            return@suspendCancellableCoroutine
        }

        photoContinuation = cont

        val settings = AVCapturePhotoSettings()

        // フラッシュ設定
        if (output.supportedFlashModes.contains(currentFlashMode.toAVFlashMode())) {
            settings.flashMode = currentFlashMode.toAVFlashMode()
        }

        output.capturePhotoWithSettings(settings, PhotoCaptureDelegate())
    }

    /**
     * カメラ切替
     */
    actual suspend fun switchCamera() {
        currentFacing = when (currentFacing) {
            CameraFacing.BACK -> CameraFacing.FRONT
            CameraFacing.FRONT -> CameraFacing.BACK
        }

        captureSession.beginConfiguration()

        // 既存入力を削除
        captureSession.inputs.forEach { input ->
            captureSession.removeInput(input as AVCaptureInput)
        }

        // 新しいカメラで入力を追加
        val device = getCamera(currentFacing)
        currentDevice = device
        val input = AVCaptureDeviceInput.deviceInputWithDevice(device, null)
        if (captureSession.canAddInput(input)) {
            captureSession.addInput(input)
        }

        captureSession.commitConfiguration()
    }

    /**
     * フラッシュ設定
     */
    actual fun setFlashMode(mode: FlashMode) {
        currentFlashMode = mode
    }

    /**
     * 現在のカメラ方向
     */
    actual fun getCurrentFacing(): CameraFacing = currentFacing

    /**
     * リソース解放
     */
    actual fun release() {
        captureSession.stopRunning()
        captureSession.inputs.forEach { input ->
            captureSession.removeInput(input as AVCaptureInput)
        }
        captureSession.outputs.forEach { output ->
            captureSession.removeOutput(output as AVCaptureOutput)
        }
    }

    /**
     * カメラデバイス取得
     */
    private fun getCamera(facing: CameraFacing): AVCaptureDevice {
        val position = when (facing) {
            CameraFacing.BACK -> AVCaptureDevicePositionBack
            CameraFacing.FRONT -> AVCaptureDevicePositionFront
        }

        return AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            .filterIsInstance<AVCaptureDevice>()
            .first { it.position == position }
    }

    /**
     * FlashMode → AVCaptureFlashMode 変換
     */
    private fun FlashMode.toAVFlashMode(): AVCaptureFlashMode {
        return when (this) {
            FlashMode.OFF -> AVCaptureFlashModeOff
            FlashMode.ON -> AVCaptureFlashModeOn
            FlashMode.AUTO -> AVCaptureFlashModeAuto
        }
    }

    /**
     * 写真撮影デリゲート
     */
    private inner class PhotoCaptureDelegate : NSObject(), AVCapturePhotoCaptureDelegateProtocol {

        override fun captureOutput(
            output: AVCapturePhotoOutput,
            didFinishProcessingPhoto: AVCapturePhoto,
            error: NSError?
        ) {
            val continuation = photoContinuation ?: return
            photoContinuation = null

            if (error != null) {
                continuation.resume(CameraResult.Error(error.localizedDescription))
                return
            }

            val data = didFinishProcessingPhoto.fileDataRepresentation()
            if (data == null) {
                continuation.resume(CameraResult.Error("Failed to get image data"))
                return
            }

            continuation.resume(
                CameraResult.Success(
                    imageData = data.toByteArray(),
                    width = didFinishProcessingPhoto.resolvedSettings
                        .photoDimensions.useContents { width },
                    height = didFinishProcessingPhoto.resolvedSettings
                        .photoDimensions.useContents { height }
                )
            )
        }
    }
}

/**
 * NSData → ByteArray 変換
 */
private fun NSData.toByteArray(): ByteArray {
    return ByteArray(length.toInt()).apply {
        usePinned { pinned ->
            memcpy(pinned.addressOf(0), bytes, length)
        }
    }
}
```

---

## ViewModel と UiState

### CameraUiState

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraUiState.kt

/**
 * カメラ画面の UI 状態
 */
data class CameraUiState(
    val isFlashOn: Boolean = false,
    val isFrontCamera: Boolean = false,
    val isCapturing: Boolean = false,
    val lastCapturedImage: ByteArray? = null,
    val error: CameraError? = null,
    val permissionState: PermissionState = PermissionState.NOT_REQUESTED
) {
    /**
     * 撮影可能かどうか
     */
    val canCapture: Boolean
        get() = !isCapturing && permissionState == PermissionState.GRANTED

    /**
     * プレビュー表示可能かどうか
     */
    val showPreview: Boolean
        get() = permissionState == PermissionState.GRANTED
}

/**
 * カメラエラー
 */
sealed interface CameraError {
    data class CaptureError(val message: String) : CameraError
    object PermissionDenied : CameraError
    object CameraUnavailable : CameraError
}

/**
 * パーミッション状態
 */
enum class PermissionState {
    NOT_REQUESTED,
    GRANTED,
    DENIED
}
```

### CameraEvent

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraEvent.kt

/**
 * カメラ画面のイベント
 */
sealed interface CameraEvent {
    /**
     * 撮影完了
     */
    data class CaptureComplete(val imageData: ByteArray) : CameraEvent

    /**
     * エラー表示
     */
    data class ShowError(val message: String) : CameraEvent

    /**
     * 設定画面へ遷移（パーミッション拒否時）
     */
    object NavigateToSettings : CameraEvent
}
```

### CameraViewModel

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraViewModel.kt

/**
 * カメラ画面の ViewModel
 */
class CameraViewModel(
    private val cameraController: CameraController,
    private val coroutineScope: CoroutineScope
) {
    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    private val _events = Channel<CameraEvent>(Channel.BUFFERED)
    val events: Flow<CameraEvent> = _events.receiveAsFlow()

    /**
     * シャッターボタン押下
     */
    fun onShutterClick() {
        if (!_uiState.value.canCapture) return

        coroutineScope.launch {
            _uiState.update { it.copy(isCapturing = true) }

            when (val result = cameraController.capture()) {
                is CameraResult.Success -> {
                    _uiState.update {
                        it.copy(
                            isCapturing = false,
                            lastCapturedImage = result.imageData
                        )
                    }
                    _events.send(CameraEvent.CaptureComplete(result.imageData))
                }

                is CameraResult.Error -> {
                    _uiState.update {
                        it.copy(
                            isCapturing = false,
                            error = CameraError.CaptureError(result.message)
                        )
                    }
                    _events.send(CameraEvent.ShowError(result.message))
                }

                is CameraResult.Cancelled -> {
                    _uiState.update { it.copy(isCapturing = false) }
                }
            }
        }
    }

    /**
     * フラッシュ切替
     */
    fun onToggleFlash() {
        val newFlashState = !_uiState.value.isFlashOn
        _uiState.update { it.copy(isFlashOn = newFlashState) }

        val mode = if (newFlashState) FlashMode.ON else FlashMode.OFF
        cameraController.setFlashMode(mode)
    }

    /**
     * カメラ切替
     */
    fun onSwitchCamera() {
        coroutineScope.launch {
            cameraController.switchCamera()
            _uiState.update {
                it.copy(isFrontCamera = cameraController.getCurrentFacing() == CameraFacing.FRONT)
            }
        }
    }

    /**
     * パーミッション結果を設定
     */
    fun onPermissionResult(granted: Boolean) {
        _uiState.update {
            it.copy(
                permissionState = if (granted) PermissionState.GRANTED else PermissionState.DENIED,
                error = if (!granted) CameraError.PermissionDenied else null
            )
        }

        if (granted) {
            coroutineScope.launch {
                cameraController.startPreview()
            }
        }
    }

    /**
     * エラーを消去
     */
    fun onDismissError() {
        _uiState.update { it.copy(error = null) }
    }

    /**
     * ViewModel 破棄
     */
    fun onCleared() {
        cameraController.release()
    }
}
```

---

## QR / 画像解析

### 解析結果モデル（共通）

```kotlin
// commonMain/kotlin/com/example/shared/analysis/AnalysisResult.kt

/**
 * 画像解析結果
 */
sealed interface AnalysisResult {
    /**
     * QR コード
     */
    data class QrCode(val content: String) : AnalysisResult

    /**
     * バーコード
     */
    data class Barcode(
        val format: BarcodeFormat,
        val value: String
    ) : AnalysisResult

    /**
     * テキスト（OCR）
     */
    data class Text(val blocks: List<String>) : AnalysisResult

    /**
     * 解析失敗
     */
    data class Error(val message: String) : AnalysisResult

    /**
     * 検出なし
     */
    object NotFound : AnalysisResult
}

/**
 * バーコードフォーマット
 */
enum class BarcodeFormat {
    QR_CODE,
    EAN_13,
    EAN_8,
    UPC_A,
    UPC_E,
    CODE_39,
    CODE_128,
    ITF,
    PDF_417,
    AZTEC,
    DATA_MATRIX,
    UNKNOWN
}
```

### ImageAnalyzer expect/actual

```kotlin
// commonMain/kotlin/com/example/shared/analysis/ImageAnalyzer.kt

/**
 * 画像解析（expect 宣言）
 */
expect class ImageAnalyzer {
    /**
     * 画像を解析
     * @param imageData JPEG/PNG バイト配列
     * @return 解析結果
     */
    suspend fun analyze(imageData: ByteArray): AnalysisResult
}
```

```kotlin
// androidMain/kotlin/com/example/shared/analysis/ImageAnalyzer.android.kt

import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Android ML Kit 実装
 */
actual class ImageAnalyzer {

    private val options = BarcodeScannerOptions.Builder()
        .setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS)
        .build()

    private val scanner = BarcodeScanning.getClient(options)

    actual suspend fun analyze(imageData: ByteArray): AnalysisResult =
        suspendCancellableCoroutine { cont ->
            val image = InputImage.fromByteArray(
                imageData,
                /* width = */ 0,  // 自動検出
                /* height = */ 0,
                /* rotationDegrees = */ 0,
                InputImage.IMAGE_FORMAT_NV21
            )

            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    if (barcodes.isEmpty()) {
                        cont.resume(AnalysisResult.NotFound)
                        return@addOnSuccessListener
                    }

                    val barcode = barcodes.first()
                    val result = when (barcode.format) {
                        Barcode.FORMAT_QR_CODE -> {
                            AnalysisResult.QrCode(barcode.rawValue ?: "")
                        }
                        else -> {
                            AnalysisResult.Barcode(
                                format = barcode.format.toBarcodeFormat(),
                                value = barcode.rawValue ?: ""
                            )
                        }
                    }
                    cont.resume(result)
                }
                .addOnFailureListener { e ->
                    cont.resume(AnalysisResult.Error(e.message ?: "Analysis failed"))
                }
        }

    /**
     * ML Kit バーコードフォーマット変換
     */
    private fun Int.toBarcodeFormat(): BarcodeFormat {
        return when (this) {
            Barcode.FORMAT_QR_CODE -> BarcodeFormat.QR_CODE
            Barcode.FORMAT_EAN_13 -> BarcodeFormat.EAN_13
            Barcode.FORMAT_EAN_8 -> BarcodeFormat.EAN_8
            Barcode.FORMAT_UPC_A -> BarcodeFormat.UPC_A
            Barcode.FORMAT_UPC_E -> BarcodeFormat.UPC_E
            Barcode.FORMAT_CODE_39 -> BarcodeFormat.CODE_39
            Barcode.FORMAT_CODE_128 -> BarcodeFormat.CODE_128
            Barcode.FORMAT_ITF -> BarcodeFormat.ITF
            Barcode.FORMAT_PDF417 -> BarcodeFormat.PDF_417
            Barcode.FORMAT_AZTEC -> BarcodeFormat.AZTEC
            Barcode.FORMAT_DATA_MATRIX -> BarcodeFormat.DATA_MATRIX
            else -> BarcodeFormat.UNKNOWN
        }
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/analysis/ImageAnalyzer.ios.kt

import kotlinx.cinterop.*
import platform.CoreImage.*
import platform.Vision.*
import platform.Foundation.*
import kotlinx.coroutines.*
import kotlin.coroutines.resume

/**
 * iOS Vision Framework 実装
 */
actual class ImageAnalyzer {

    actual suspend fun analyze(imageData: ByteArray): AnalysisResult =
        suspendCancellableCoroutine { cont ->
            val nsData = imageData.toNSData()
            val ciImage = CIImage.imageWithData(nsData) ?: run {
                cont.resume(AnalysisResult.Error("Failed to create CIImage"))
                return@suspendCancellableCoroutine
            }

            val request = VNDetectBarcodesRequest { request, error ->
                if (error != null) {
                    cont.resume(AnalysisResult.Error(error.localizedDescription))
                    return@VNDetectBarcodesRequest
                }

                val results = request?.results?.filterIsInstance<VNBarcodeObservation>()
                if (results.isNullOrEmpty()) {
                    cont.resume(AnalysisResult.NotFound)
                    return@VNDetectBarcodesRequest
                }

                val observation = results.first()
                val result = when (observation.symbology) {
                    VNBarcodeSymbologyQR -> {
                        AnalysisResult.QrCode(observation.payloadStringValue ?: "")
                    }
                    else -> {
                        AnalysisResult.Barcode(
                            format = observation.symbology.toBarcodeFormat(),
                            value = observation.payloadStringValue ?: ""
                        )
                    }
                }
                cont.resume(result)
            }

            val handler = VNImageRequestHandler(ciImage, NSDictionary())
            handler.performRequests(listOf(request), null)
        }

    /**
     * Vision symbology → BarcodeFormat 変換
     */
    private fun String.toBarcodeFormat(): BarcodeFormat {
        return when (this) {
            VNBarcodeSymbologyQR -> BarcodeFormat.QR_CODE
            VNBarcodeSymbologyEAN13 -> BarcodeFormat.EAN_13
            VNBarcodeSymbologyEAN8 -> BarcodeFormat.EAN_8
            VNBarcodeSymbologyUPCE -> BarcodeFormat.UPC_E
            VNBarcodeSymbologyCode39 -> BarcodeFormat.CODE_39
            VNBarcodeSymbologyCode128 -> BarcodeFormat.CODE_128
            VNBarcodeSymbologyITF14 -> BarcodeFormat.ITF
            VNBarcodeSymbologyPDF417 -> BarcodeFormat.PDF_417
            VNBarcodeSymbologyAztec -> BarcodeFormat.AZTEC
            VNBarcodeSymbologyDataMatrix -> BarcodeFormat.DATA_MATRIX
            else -> BarcodeFormat.UNKNOWN
        }
    }
}

/**
 * ByteArray → NSData 変換
 */
private fun ByteArray.toNSData(): NSData {
    return usePinned { pinned ->
        NSData.dataWithBytes(pinned.addressOf(0), size.toULong())
    }
}
```

---

## 判断基準表

| やりたいこと | 方針 | 備考 |
|-------------|------|------|
| 写真撮るだけ | ◎ 基本構成で十分 | CameraController + ViewModel |
| QR/バーコード読み取り | ◎ 解析は OS 側 | ImageAnalyzer expect/actual |
| OCR（文字認識） | ○ 解析は OS 側 | ML Kit / Vision Text |
| 動画撮影 | △ 共通化最小限 | 複雑なため OS 依存大 |
| 連続撮影（バースト） | △ OS 依存大 | CameraX / AVFoundation 個別実装 |
| リアルタイム解析 | △ パフォーマンス考慮 | カメラプレビュー中の解析 |
| 高度な制御（露出、ISO） | ✕ OS 別実装推奨 | プラットフォーム固有 API |
| AR 機能 | ✕ OS 別実装推奨 | ARCore / ARKit |

---

## リアルタイム解析

カメラプレビュー中にフレームを解析する場合の実装パターン。QR スキャナーなどで使用。

### 設計のポイント

1. **解析頻度の制御**
   - 全フレーム解析は不要（CPU/バッテリー消費大）
   - 100-500ms 間隔で十分

2. **バックグラウンドスレッドで解析**
   - UI スレッドをブロックしない
   - 解析結果のみ UI スレッドに返す

3. **共通化の範囲**
   - 解析ロジック呼び出し・結果処理は KMP
   - フレーム取得は OS ネイティブ

### RealtimeAnalyzer expect/actual

```kotlin
// commonMain/kotlin/com/example/shared/analysis/RealtimeAnalyzer.kt

/**
 * リアルタイム解析（expect 宣言）
 */
expect class RealtimeAnalyzer {
    /**
     * 解析開始
     * @param onResult 解析結果コールバック（メインスレッドで呼ばれる）
     */
    fun start(onResult: (AnalysisResult) -> Unit)

    /**
     * 解析停止
     */
    fun stop()

    /**
     * 解析中かどうか
     */
    val isAnalyzing: Boolean
}
```

### Android 実装（CameraX ImageAnalysis）

```kotlin
// androidMain/kotlin/com/example/shared/analysis/RealtimeAnalyzer.android.kt

import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import kotlinx.coroutines.*
import java.util.concurrent.Executors

/**
 * Android リアルタイム解析実装
 */
actual class RealtimeAnalyzer(
    private val lifecycleOwner: LifecycleOwner,
    private val cameraProvider: ProcessCameraProvider
) {
    private val executor = Executors.newSingleThreadExecutor()
    private val scanner = BarcodeScanning.getClient()
    private var imageAnalysis: ImageAnalysis? = null
    private var resultCallback: ((AnalysisResult) -> Unit)? = null

    private var _isAnalyzing = false
    actual val isAnalyzing: Boolean get() = _isAnalyzing

    // スロットリング用
    private var lastAnalysisTime = 0L
    private val analysisIntervalMs = 200L

    actual fun start(onResult: (AnalysisResult) -> Unit) {
        resultCallback = onResult
        _isAnalyzing = true

        imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also { analysis ->
                analysis.setAnalyzer(executor) { imageProxy ->
                    processImage(imageProxy)
                }
            }

        // CameraProvider にバインド
        cameraProvider.bindToLifecycle(
            lifecycleOwner,
            CameraSelector.DEFAULT_BACK_CAMERA,
            imageAnalysis
        )
    }

    actual fun stop() {
        _isAnalyzing = false
        imageAnalysis?.let { cameraProvider.unbind(it) }
        imageAnalysis = null
        resultCallback = null
    }

    @androidx.camera.core.ExperimentalGetImage
    private fun processImage(imageProxy: ImageProxy) {
        val currentTime = System.currentTimeMillis()

        // スロットリング: 一定間隔でのみ解析
        if (currentTime - lastAnalysisTime < analysisIntervalMs) {
            imageProxy.close()
            return
        }
        lastAnalysisTime = currentTime

        val mediaImage = imageProxy.image
        if (mediaImage == null) {
            imageProxy.close()
            return
        }

        val inputImage = InputImage.fromMediaImage(
            mediaImage,
            imageProxy.imageInfo.rotationDegrees
        )

        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                if (barcodes.isNotEmpty()) {
                    val barcode = barcodes.first()
                    val result = when (barcode.format) {
                        Barcode.FORMAT_QR_CODE ->
                            AnalysisResult.QrCode(barcode.rawValue ?: "")
                        else ->
                            AnalysisResult.Barcode(
                                format = barcode.format.toBarcodeFormat(),
                                value = barcode.rawValue ?: ""
                            )
                    }
                    // メインスレッドでコールバック
                    MainScope().launch {
                        resultCallback?.invoke(result)
                    }
                }
            }
            .addOnCompleteListener {
                imageProxy.close()
            }
    }
}
```

### iOS 実装（AVCaptureVideoDataOutput）

```kotlin
// iosMain/kotlin/com/example/shared/analysis/RealtimeAnalyzer.ios.kt

import kotlinx.cinterop.*
import platform.AVFoundation.*
import platform.CoreMedia.*
import platform.Vision.*
import platform.darwin.*

/**
 * iOS リアルタイム解析実装
 */
actual class RealtimeAnalyzer(
    private val captureSession: AVCaptureSession
) {
    private var videoOutput: AVCaptureVideoDataOutput? = null
    private var resultCallback: ((AnalysisResult) -> Unit)? = null
    private val processingQueue = dispatch_queue_create(
        "com.example.analysis",
        null
    )

    private var _isAnalyzing = false
    actual val isAnalyzing: Boolean get() = _isAnalyzing

    // スロットリング用
    private var lastAnalysisTime: ULong = 0UL
    private val analysisIntervalNs: ULong = 200_000_000UL  // 200ms

    actual fun start(onResult: (AnalysisResult) -> Unit) {
        resultCallback = onResult
        _isAnalyzing = true

        val output = AVCaptureVideoDataOutput().apply {
            setSampleBufferDelegate(
                SampleBufferDelegate(),
                processingQueue
            )
            alwaysDiscardsLateVideoFrames = true
        }

        if (captureSession.canAddOutput(output)) {
            captureSession.addOutput(output)
            videoOutput = output
        }
    }

    actual fun stop() {
        _isAnalyzing = false
        videoOutput?.let { captureSession.removeOutput(it) }
        videoOutput = null
        resultCallback = null
    }

    private inner class SampleBufferDelegate :
        NSObject(), AVCaptureVideoDataOutputSampleBufferDelegateProtocol {

        override fun captureOutput(
            output: AVCaptureOutput,
            didOutputSampleBuffer: CMSampleBufferRef?,
            fromConnection: AVCaptureConnection
        ) {
            val sampleBuffer = didOutputSampleBuffer ?: return

            // スロットリング
            val currentTime = clock_gettime_nsec_np(CLOCK_MONOTONIC)
            if (currentTime - lastAnalysisTime < analysisIntervalNs) {
                return
            }
            lastAnalysisTime = currentTime

            val pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ?: return

            val request = VNDetectBarcodesRequest { request, error ->
                if (error != null) return@VNDetectBarcodesRequest

                val results = request?.results?.filterIsInstance<VNBarcodeObservation>()
                if (results.isNullOrEmpty()) return@VNDetectBarcodesRequest

                val observation = results.first()
                val result = when (observation.symbology) {
                    VNBarcodeSymbologyQR ->
                        AnalysisResult.QrCode(observation.payloadStringValue ?: "")
                    else ->
                        AnalysisResult.Barcode(
                            format = observation.symbology.toBarcodeFormat(),
                            value = observation.payloadStringValue ?: ""
                        )
                }

                // メインスレッドでコールバック
                dispatch_async(dispatch_get_main_queue()) {
                    resultCallback?.invoke(result)
                }
            }

            val handler = VNImageRequestHandler(pixelBuffer, NSDictionary())
            handler.performRequests(listOf(request), null)
        }
    }
}
```

### ViewModel での使用例

```kotlin
// commonMain/kotlin/com/example/shared/presentation/scanner/ScannerViewModel.kt

/**
 * QR スキャナー ViewModel
 */
class ScannerViewModel(
    private val realtimeAnalyzer: RealtimeAnalyzer,
    private val coroutineScope: CoroutineScope
) {
    private val _uiState = MutableStateFlow(ScannerUiState())
    val uiState: StateFlow<ScannerUiState> = _uiState.asStateFlow()

    private val _events = Channel<ScannerEvent>(Channel.BUFFERED)
    val events: Flow<ScannerEvent> = _events.receiveAsFlow()

    /**
     * スキャン開始
     */
    fun startScanning() {
        if (realtimeAnalyzer.isAnalyzing) return

        _uiState.update { it.copy(isScanning = true) }

        realtimeAnalyzer.start { result ->
            when (result) {
                is AnalysisResult.QrCode -> {
                    // QR 検出時は自動停止
                    stopScanning()
                    coroutineScope.launch {
                        _events.send(ScannerEvent.QrDetected(result.content))
                    }
                }
                is AnalysisResult.Barcode -> {
                    stopScanning()
                    coroutineScope.launch {
                        _events.send(ScannerEvent.BarcodeDetected(
                            result.format,
                            result.value
                        ))
                    }
                }
                else -> { /* 検出なし、継続 */ }
            }
        }
    }

    /**
     * スキャン停止
     */
    fun stopScanning() {
        realtimeAnalyzer.stop()
        _uiState.update { it.copy(isScanning = false) }
    }

    fun onCleared() {
        stopScanning()
    }
}

data class ScannerUiState(
    val isScanning: Boolean = false,
    val permissionState: PermissionState = PermissionState.NOT_REQUESTED
)

sealed interface ScannerEvent {
    data class QrDetected(val content: String) : ScannerEvent
    data class BarcodeDetected(val format: BarcodeFormat, val value: String) : ScannerEvent
}
```

### パフォーマンス注意点

| 項目 | 推奨値 | 理由 |
|------|--------|------|
| 解析間隔 | 100-500ms | CPU/バッテリー節約 |
| バックプレッシャー | KEEP_ONLY_LATEST | メモリ節約 |
| 解析スレッド | 専用スレッド | UI ブロック防止 |
| 解析停止 | 検出成功時 | 重複検出防止 |

---

## パーミッション管理

### CameraPermission expect/actual

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraPermission.kt

/**
 * カメラパーミッション管理（expect 宣言）
 */
expect class CameraPermission {
    /**
     * パーミッション状態を確認
     */
    fun checkPermission(): PermissionState

    /**
     * パーミッションをリクエスト
     * @param onResult 結果コールバック
     */
    fun requestPermission(onResult: (Boolean) -> Unit)
}
```

```kotlin
// androidMain/kotlin/com/example/shared/camera/CameraPermission.android.kt

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.result.ActivityResultLauncher
import androidx.core.content.ContextCompat

/**
 * Android パーミッション実装
 */
actual class CameraPermission(
    private val context: Context,
    private val permissionLauncher: ActivityResultLauncher<String>
) {
    private var resultCallback: ((Boolean) -> Unit)? = null

    actual fun checkPermission(): PermissionState {
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        return if (granted) PermissionState.GRANTED else PermissionState.DENIED
    }

    actual fun requestPermission(onResult: (Boolean) -> Unit) {
        resultCallback = onResult
        permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    /**
     * パーミッション結果を受け取る（Activity から呼び出し）
     */
    fun onPermissionResult(granted: Boolean) {
        resultCallback?.invoke(granted)
        resultCallback = null
    }
}
```

```kotlin
// iosMain/kotlin/com/example/shared/camera/CameraPermission.ios.kt

import platform.AVFoundation.*
import platform.Foundation.*

/**
 * iOS パーミッション実装
 */
actual class CameraPermission {

    actual fun checkPermission(): PermissionState {
        return when (AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)) {
            AVAuthorizationStatusAuthorized -> PermissionState.GRANTED
            AVAuthorizationStatusDenied,
            AVAuthorizationStatusRestricted -> PermissionState.DENIED
            else -> PermissionState.NOT_REQUESTED
        }
    }

    actual fun requestPermission(onResult: (Boolean) -> Unit) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { granted ->
            dispatch_async(dispatch_get_main_queue()) {
                onResult(granted)
            }
        }
    }
}
```

---

## ベストプラクティス一覧

### 役割分担

- [ ] UI・状態管理は KMP/CMP で共通化
- [ ] カメラデバイス制御は OS ネイティブに委任
- [ ] 画像解析は OS の ML ライブラリを使用

### expect/actual

- [ ] CameraController を expect 宣言で抽象化
- [ ] Android は CameraX を使用
- [ ] iOS は AVFoundation を使用
- [ ] 共通モデル（CameraResult 等）を commonMain に配置

### ViewModel

- [ ] CameraUiState で撮影状態を管理
- [ ] パーミッション状態を UiState に含める
- [ ] イベント（CameraEvent）で一度きりの通知

### パーミッション

- [ ] パーミッションチェックを起動時に実行
- [ ] 拒否時は設定画面への導線を提供
- [ ] 状態を UiState で管理

### 画像解析

- [ ] AnalysisResult を共通モデルで定義
- [ ] Android は ML Kit、iOS は Vision を使用
- [ ] リアルタイム解析はパフォーマンスを考慮

---

## 参考リンク

### 公式ドキュメント

- [CameraX (Android)](https://developer.android.com/training/camerax)
- [AVFoundation (iOS)](https://developer.apple.com/av-foundation/)
- [ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)
- [Vision Framework (iOS)](https://developer.apple.com/documentation/vision)

### KMP 関連

- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
- [expect/actual declarations](https://kotlinlang.org/docs/multiplatform-expect-actual.html)

---

## エージェント向けタスク分解

### 写真撮影機能 チェックリスト

#### Phase 1: 共通モデル定義

- [ ] `CameraResult` sealed interface を作成
  - Success, Error, Cancelled
- [ ] `CameraConfig` data class を作成
  - CameraFacing, FlashMode, AspectRatio
- [ ] `CameraError` sealed interface を作成
- [ ] `PermissionState` enum を作成

#### Phase 2: CameraController expect/actual

- [ ] `CameraController` expect 宣言を作成
  - startPreview(), stopPreview(), capture(), switchCamera(), setFlashMode(), release()
- [ ] Android actual 実装（CameraX）
  - ProcessCameraProvider, ImageCapture, Preview
- [ ] iOS actual 実装（AVFoundation）
  - AVCaptureSession, AVCapturePhotoOutput, PhotoCaptureDelegate

#### Phase 3: パーミッション管理

- [ ] `CameraPermission` expect 宣言を作成
  - checkPermission(), requestPermission()
- [ ] Android actual 実装
  - ContextCompat.checkSelfPermission, ActivityResultLauncher
- [ ] iOS actual 実装
  - AVCaptureDevice.authorizationStatusForMediaType

#### Phase 4: ViewModel

- [ ] `CameraUiState` data class を作成
  - isFlashOn, isFrontCamera, isCapturing, permissionState, error
- [ ] `CameraEvent` sealed interface を作成
  - CaptureComplete, ShowError, NavigateToSettings
- [ ] `CameraViewModel` を作成
  - onShutterClick(), onToggleFlash(), onSwitchCamera(), onPermissionResult()

#### Phase 5: DI 設定

- [ ] カメラモジュールを Koin に登録
- [ ] プラットフォーム固有の依存を platformModule に追加

---

### QR/バーコード解析機能 チェックリスト

#### Phase 1: 共通モデル定義

- [ ] `AnalysisResult` sealed interface を作成
  - QrCode, Barcode, Text, Error, NotFound
- [ ] `BarcodeFormat` enum を作成

#### Phase 2: ImageAnalyzer expect/actual

- [ ] `ImageAnalyzer` expect 宣言を作成
  - analyze(imageData: ByteArray): AnalysisResult
- [ ] Android actual 実装（ML Kit）
  - BarcodeScannerOptions, BarcodeScanning.getClient()
- [ ] iOS actual 実装（Vision）
  - VNDetectBarcodesRequest, VNImageRequestHandler

---

### リアルタイム解析機能 チェックリスト

#### Phase 1: RealtimeAnalyzer expect/actual

- [ ] `RealtimeAnalyzer` expect 宣言を作成
  - start(onResult), stop(), isAnalyzing
- [ ] Android actual 実装（CameraX ImageAnalysis）
  - ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST
  - スロットリング実装（200ms 間隔）
- [ ] iOS actual 実装（AVCaptureVideoDataOutput）
  - AVCaptureVideoDataOutputSampleBufferDelegateProtocol
  - dispatch_queue_create で専用キュー

#### Phase 2: ScannerViewModel

- [ ] `ScannerUiState` data class を作成
- [ ] `ScannerEvent` sealed interface を作成
- [ ] `ScannerViewModel` を作成
  - startScanning(), stopScanning()
  - 検出成功時の自動停止

#### Phase 3: パフォーマンス最適化

- [ ] スロットリング間隔の調整（100-500ms）
- [ ] バックプレッシャー戦略の確認
- [ ] メモリリークの確認（コールバック解放）

---

### 実装時の注意点

1. **expect/actual の対応確認**
   - コンストラクタ引数がプラットフォームで異なる場合は Factory パターンを検討
   - 共通 interface + DI で依存注入も可

2. **ライフサイクル管理**
   - Android: LifecycleOwner との連携
   - iOS: deinit での明示的リソース解放

3. **テスト戦略**
   - commonTest で ViewModel テスト（FakeCameraController 使用）
   - プラットフォーム固有コードは統合テストで確認

---

## 関連ドキュメント

- [kmp-architecture.md](kmp-architecture.md) - KMP 全体のアーキテクチャ
- [kmp-auth.md](kmp-auth.md) - 認証実装ベストプラクティス
