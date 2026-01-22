# KMP Camera Implementation Guide

Best Practices for implementing camera functionality in KMP/CMP. Clarifies Role Distribution between OS native features, organizing what should be shared and what should be delegated to the OS.

---

## Table of Contents

1. [Principles of Role Distribution](#principles-of-role-distribution)
2. [Dependency Diagram](#dependency-diagram)
3. [Directory Structure](#directory-structure)
4. [expect/actual Implementation](#expectactual-implementation)
5. [ViewModel and UiState](#viewmodel-and-uistate)
6. [QR / Image Analysis](#qr--image-analysis)
7. [Decision Criteria Table](#decision-criteria-table)
8. [Real-time Analysis](#real-time-analysis)
9. [Permission Management](#permission-management)
10. [Best Practices List](#best-practices-list)
11. [Task Breakdown for Agents](#task-breakdown-for-agents)

---

## Principles of Role Distribution

For camera functionality, establish clear Role Distribution between KMP/CMP and OS native.

```
🧠 KMP / CMP = "How to use" (UI, state, logic)
📷 OS Native = "How to capture" (device control)
```

### KMP/CMP Responsibilities

| Item | Description |
|------|-------------|
| Capture button UI | Button placement, pressed state |
| Front/Rear switching | Camera direction state management |
| Flash ON/OFF state | Flash setting state management |
| Capturing/Complete state management | State representation in UiState |
| Capture result processing | Upload, analysis, save |

### Delegate to OS

| Item | Android | iOS |
|------|---------|-----|
| Camera start/stop | CameraX | AVFoundation |
| Preview display | PreviewView | AVCaptureVideoPreviewLayer |
| Focus/Exposure | CameraControl | AVCaptureDevice |
| Sensor rotation | ImageAnalysis | AVCaptureConnection |
| Surface management | SurfaceProvider | CALayer |

---

## Dependency Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CMP UI Layer                                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   CameraScreen (Compose Multiplatform)                        │   │
│  │   - Capture button                                            │   │
│  │   - Settings UI (Flash, Camera switching)                     │   │
│  │   - Preview area (expect/actual)                              │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    KMP ViewModel / UseCase                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │   CameraViewModel                                             │   │
│  │   - CameraUiState management                                  │   │
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

## Directory Structure

```
shared/src/
├── commonMain/kotlin/com/example/shared/
│   ├── camera/
│   │   ├── CameraController.kt        # expect declaration
│   │   ├── CameraResult.kt            # Shared model (capture result)
│   │   ├── CameraConfig.kt            # Configuration model
│   │   └── CameraPermission.kt        # Permission abstraction
│   │
│   ├── analysis/
│   │   ├── ImageAnalyzer.kt           # expect declaration
│   │   └── AnalysisResult.kt          # Analysis result model
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

## expect/actual Implementation

### Shared Models (commonMain)

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraResult.kt

/**
 * Capture result
 */
sealed interface CameraResult {
    /**
     * Capture success
     * @param imageData JPEG byte array
     * @param width Image width
     * @param height Image height
     */
    data class Success(
        val imageData: ByteArray,
        val width: Int,
        val height: Int
    ) : CameraResult

    /**
     * Capture failure
     */
    data class Error(val message: String) : CameraResult

    /**
     * Cancelled
     */
    object Cancelled : CameraResult
}
```

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraConfig.kt

/**
 * Camera configuration
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

### CameraController expect Declaration

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraController.kt

/**
 * Camera control interface (expect declaration)
 *
 * Abstracts platform-specific implementations
 */
expect class CameraController {

    /**
     * Start Preview
     */
    suspend fun startPreview()

    /**
     * Stop Preview
     */
    fun stopPreview()

    /**
     * Take photo
     * @return Capture result
     */
    suspend fun capture(): CameraResult

    /**
     * Camera switching (Front/Rear)
     */
    suspend fun switchCamera()

    /**
     * Flash setting
     * @param mode Flash mode
     */
    fun setFlashMode(mode: FlashMode)

    /**
     * Get current camera direction
     */
    fun getCurrentFacing(): CameraFacing

    /**
     * Release resources
     */
    fun release()
}
```

### Android actual Implementation (CameraX)

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
 * Android CameraX implementation
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
     * Start Preview
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
     * Stop Preview
     */
    actual fun stopPreview() {
        cameraProvider?.unbindAll()
    }

    /**
     * Take photo
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
     * Camera switching
     */
    actual suspend fun switchCamera() {
        currentFacing = when (currentFacing) {
            CameraFacing.BACK -> CameraFacing.FRONT
            CameraFacing.FRONT -> CameraFacing.BACK
        }
        bindCameraUseCases()
    }

    /**
     * Flash setting
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
     * Current camera direction
     */
    actual fun getCurrentFacing(): CameraFacing = currentFacing

    /**
     * Release resources
     */
    actual fun release() {
        cameraProvider?.unbindAll()
        cameraProvider = null
    }

    /**
     * Bind camera use cases
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

### iOS actual Implementation (AVFoundation)

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
 * iOS AVFoundation implementation
 */
actual class CameraController {
    private val captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput? = null
    private var currentDevice: AVCaptureDevice? = null

    private var currentFacing = CameraFacing.BACK
    private var currentFlashMode = FlashMode.OFF

    private var photoContinuation: CancellableContinuation<CameraResult>? = null

    /**
     * Start Preview
     */
    actual suspend fun startPreview() {
        captureSession.beginConfiguration()

        // Get camera device
        val device = getCamera(currentFacing)
        currentDevice = device

        // Configure input
        val input = AVCaptureDeviceInput.deviceInputWithDevice(device, null)
        if (captureSession.canAddInput(input)) {
            captureSession.addInput(input)
        }

        // Configure output
        val output = AVCapturePhotoOutput()
        if (captureSession.canAddOutput(output)) {
            captureSession.addOutput(output)
            photoOutput = output
        }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    /**
     * Stop Preview
     */
    actual fun stopPreview() {
        captureSession.stopRunning()
    }

    /**
     * Take photo
     */
    actual suspend fun capture(): CameraResult = suspendCancellableCoroutine { cont ->
        val output = photoOutput ?: run {
            cont.resume(CameraResult.Error("PhotoOutput not initialized"))
            return@suspendCancellableCoroutine
        }

        photoContinuation = cont

        val settings = AVCapturePhotoSettings()

        // Flash setting
        if (output.supportedFlashModes.contains(currentFlashMode.toAVFlashMode())) {
            settings.flashMode = currentFlashMode.toAVFlashMode()
        }

        output.capturePhotoWithSettings(settings, PhotoCaptureDelegate())
    }

    /**
     * Camera switching
     */
    actual suspend fun switchCamera() {
        currentFacing = when (currentFacing) {
            CameraFacing.BACK -> CameraFacing.FRONT
            CameraFacing.FRONT -> CameraFacing.BACK
        }

        captureSession.beginConfiguration()

        // Remove existing input
        captureSession.inputs.forEach { input ->
            captureSession.removeInput(input as AVCaptureInput)
        }

        // Add input with new camera
        val device = getCamera(currentFacing)
        currentDevice = device
        val input = AVCaptureDeviceInput.deviceInputWithDevice(device, null)
        if (captureSession.canAddInput(input)) {
            captureSession.addInput(input)
        }

        captureSession.commitConfiguration()
    }

    /**
     * Flash setting
     */
    actual fun setFlashMode(mode: FlashMode) {
        currentFlashMode = mode
    }

    /**
     * Current camera direction
     */
    actual fun getCurrentFacing(): CameraFacing = currentFacing

    /**
     * Release resources
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
     * Get camera device
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
     * FlashMode to AVCaptureFlashMode conversion
     */
    private fun FlashMode.toAVFlashMode(): AVCaptureFlashMode {
        return when (this) {
            FlashMode.OFF -> AVCaptureFlashModeOff
            FlashMode.ON -> AVCaptureFlashModeOn
            FlashMode.AUTO -> AVCaptureFlashModeAuto
        }
    }

    /**
     * Photo capture delegate
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
 * NSData to ByteArray conversion
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

## ViewModel and UiState

### CameraUiState

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraUiState.kt

/**
 * Camera screen UI state
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
     * Whether capture is possible
     */
    val canCapture: Boolean
        get() = !isCapturing && permissionState == PermissionState.GRANTED

    /**
     * Whether preview can be displayed
     */
    val showPreview: Boolean
        get() = permissionState == PermissionState.GRANTED
}

/**
 * Camera error
 */
sealed interface CameraError {
    data class CaptureError(val message: String) : CameraError
    object PermissionDenied : CameraError
    object CameraUnavailable : CameraError
}

/**
 * Permission state
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
 * Camera screen events
 */
sealed interface CameraEvent {
    /**
     * Capture complete
     */
    data class CaptureComplete(val imageData: ByteArray) : CameraEvent

    /**
     * Show error
     */
    data class ShowError(val message: String) : CameraEvent

    /**
     * Navigate to settings (when permission denied)
     */
    object NavigateToSettings : CameraEvent
}
```

### CameraViewModel

```kotlin
// commonMain/kotlin/com/example/shared/presentation/camera/CameraViewModel.kt

/**
 * Camera screen ViewModel
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
     * Shutter button pressed
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
     * Toggle Flash
     */
    fun onToggleFlash() {
        val newFlashState = !_uiState.value.isFlashOn
        _uiState.update { it.copy(isFlashOn = newFlashState) }

        val mode = if (newFlashState) FlashMode.ON else FlashMode.OFF
        cameraController.setFlashMode(mode)
    }

    /**
     * Camera switching
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
     * Set permission result
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
     * Dismiss error
     */
    fun onDismissError() {
        _uiState.update { it.copy(error = null) }
    }

    /**
     * ViewModel destroyed
     */
    fun onCleared() {
        cameraController.release()
    }
}
```

---

## QR / Image Analysis

### Analysis Result Model (Shared)

```kotlin
// commonMain/kotlin/com/example/shared/analysis/AnalysisResult.kt

/**
 * Image analysis result
 */
sealed interface AnalysisResult {
    /**
     * QR Code
     */
    data class QrCode(val content: String) : AnalysisResult

    /**
     * Barcode
     */
    data class Barcode(
        val format: BarcodeFormat,
        val value: String
    ) : AnalysisResult

    /**
     * Text (OCR)
     */
    data class Text(val blocks: List<String>) : AnalysisResult

    /**
     * Analysis failed
     */
    data class Error(val message: String) : AnalysisResult

    /**
     * Not found
     */
    object NotFound : AnalysisResult
}

/**
 * Barcode format
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
 * Image analysis (expect declaration)
 */
expect class ImageAnalyzer {
    /**
     * Analyze image
     * @param imageData JPEG/PNG byte array
     * @return Analysis result
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
 * Android ML Kit implementation
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
                /* width = */ 0,  // Auto-detect
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
     * ML Kit barcode format conversion
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
 * iOS Vision Framework implementation
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
     * Vision symbology to BarcodeFormat conversion
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
 * ByteArray to NSData conversion
 */
private fun ByteArray.toNSData(): NSData {
    return usePinned { pinned ->
        NSData.dataWithBytes(pinned.addressOf(0), size.toULong())
    }
}
```

---

## Decision Criteria Table

| Goal | Approach | Notes |
|------|----------|-------|
| Just take photos | Excellent - Basic configuration sufficient | CameraController + ViewModel |
| QR/Barcode reading | Excellent - Analysis on OS side | ImageAnalyzer expect/actual |
| OCR (Text recognition) | Good - Analysis on OS side | ML Kit / Vision Text |
| Video recording | Fair - Minimal sharing | Complex, high OS dependency |
| Burst capture | Fair - High OS dependency | CameraX / AVFoundation individual implementation |
| Real-time Analysis | Fair - Performance consideration | Analysis during camera Preview |
| Advanced control (exposure, ISO) | Not recommended - OS-specific implementation | Platform-specific APIs |
| AR features | Not recommended - OS-specific implementation | ARCore / ARKit |

---

## Real-time Analysis

Implementation pattern for analyzing frames during camera Preview. Used for QR scanners, etc.

### Design Points

1. **Analysis frequency control**
   - Full frame analysis is unnecessary (high CPU/battery consumption)
   - 100-500ms interval is sufficient

2. **Analyze on background thread**
   - Don't block UI thread
   - Return only analysis results to UI thread

3. **Scope of sharing**
   - Analysis logic invocation and result processing in KMP
   - Frame acquisition is OS native

### RealtimeAnalyzer expect/actual

```kotlin
// commonMain/kotlin/com/example/shared/analysis/RealtimeAnalyzer.kt

/**
 * Real-time Analysis (expect declaration)
 */
expect class RealtimeAnalyzer {
    /**
     * Start analysis
     * @param onResult Analysis result callback (called on main thread)
     */
    fun start(onResult: (AnalysisResult) -> Unit)

    /**
     * Stop analysis
     */
    fun stop()

    /**
     * Whether analysis is in progress
     */
    val isAnalyzing: Boolean
}
```

### Android Implementation (CameraX ImageAnalysis)

```kotlin
// androidMain/kotlin/com/example/shared/analysis/RealtimeAnalyzer.android.kt

import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import kotlinx.coroutines.*
import java.util.concurrent.Executors

/**
 * Android Real-time Analysis implementation
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

    // For throttling
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

        // Bind to CameraProvider
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

        // Throttling: analyze only at certain intervals
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
                    // Callback on main thread
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

### iOS Implementation (AVCaptureVideoDataOutput)

```kotlin
// iosMain/kotlin/com/example/shared/analysis/RealtimeAnalyzer.ios.kt

import kotlinx.cinterop.*
import platform.AVFoundation.*
import platform.CoreMedia.*
import platform.Vision.*
import platform.darwin.*

/**
 * iOS Real-time Analysis implementation
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

    // For throttling
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

            // Throttling
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

                // Callback on main thread
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

### ViewModel Usage Example

```kotlin
// commonMain/kotlin/com/example/shared/presentation/scanner/ScannerViewModel.kt

/**
 * QR Scanner ViewModel
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
     * Start scanning
     */
    fun startScanning() {
        if (realtimeAnalyzer.isAnalyzing) return

        _uiState.update { it.copy(isScanning = true) }

        realtimeAnalyzer.start { result ->
            when (result) {
                is AnalysisResult.QrCode -> {
                    // Auto-stop on QR detection
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
                else -> { /* Not detected, continue */ }
            }
        }
    }

    /**
     * Stop scanning
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

### Performance Notes

| Item | Recommended Value | Reason |
|------|-------------------|--------|
| Analysis interval | 100-500ms | CPU/Battery savings |
| Backpressure | KEEP_ONLY_LATEST | Memory savings |
| Analysis thread | Dedicated thread | Prevent UI blocking |
| Stop analysis | On successful detection | Prevent duplicate detection |

---

## Permission Management

### CameraPermission expect/actual

```kotlin
// commonMain/kotlin/com/example/shared/camera/CameraPermission.kt

/**
 * Camera Permission management (expect declaration)
 */
expect class CameraPermission {
    /**
     * Check permission state
     */
    fun checkPermission(): PermissionState

    /**
     * Request permission
     * @param onResult Result callback
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
 * Android Permission implementation
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
     * Receive permission result (called from Activity)
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
 * iOS Permission implementation
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

## Best Practices List

### Role Distribution

- [ ] Share UI and state management with KMP/CMP
- [ ] Delegate camera device control to OS native
- [ ] Use OS ML libraries for image analysis

### expect/actual

- [ ] Abstract CameraController with expect declaration
- [ ] Use CameraX for Android
- [ ] Use AVFoundation for iOS
- [ ] Place shared models (CameraResult, etc.) in commonMain

### ViewModel

- [ ] Manage capture state with CameraUiState
- [ ] Include permission state in UiState
- [ ] One-time notifications via events (CameraEvent)

### Permission

- [ ] Execute permission check at startup
- [ ] Provide navigation to settings when denied
- [ ] Manage state with UiState

### Image Analysis

- [ ] Define AnalysisResult as shared model
- [ ] Use ML Kit for Android, Vision for iOS
- [ ] Consider performance for Real-time Analysis

---

## Reference Links

### Official Documentation

- [CameraX (Android)](https://developer.android.com/training/camerax)
- [AVFoundation (iOS)](https://developer.apple.com/av-foundation/)
- [ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)
- [Vision Framework (iOS)](https://developer.apple.com/documentation/vision)

### KMP Related

- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
- [expect/actual declarations](https://kotlinlang.org/docs/multiplatform-expect-actual.html)

---

## Task Breakdown for Agents

### Photo Capture Feature Checklist

#### Phase 1: Shared Model Definition

- [ ] Create `CameraResult` sealed interface
  - Success, Error, Cancelled
- [ ] Create `CameraConfig` data class
  - CameraFacing, FlashMode, AspectRatio
- [ ] Create `CameraError` sealed interface
- [ ] Create `PermissionState` enum

#### Phase 2: CameraController expect/actual

- [ ] Create `CameraController` expect declaration
  - startPreview(), stopPreview(), capture(), switchCamera(), setFlashMode(), release()
- [ ] Android actual implementation (CameraX)
  - ProcessCameraProvider, ImageCapture, Preview
- [ ] iOS actual implementation (AVFoundation)
  - AVCaptureSession, AVCapturePhotoOutput, PhotoCaptureDelegate

#### Phase 3: Permission Management

- [ ] Create `CameraPermission` expect declaration
  - checkPermission(), requestPermission()
- [ ] Android actual implementation
  - ContextCompat.checkSelfPermission, ActivityResultLauncher
- [ ] iOS actual implementation
  - AVCaptureDevice.authorizationStatusForMediaType

#### Phase 4: ViewModel

- [ ] Create `CameraUiState` data class
  - isFlashOn, isFrontCamera, isCapturing, permissionState, error
- [ ] Create `CameraEvent` sealed interface
  - CaptureComplete, ShowError, NavigateToSettings
- [ ] Create `CameraViewModel`
  - onShutterClick(), onToggleFlash(), onSwitchCamera(), onPermissionResult()

#### Phase 5: DI Configuration

- [ ] Register camera module with Koin
- [ ] Add platform-specific dependencies to platformModule

---

### QR/Barcode Analysis Feature Checklist

#### Phase 1: Shared Model Definition

- [ ] Create `AnalysisResult` sealed interface
  - QrCode, Barcode, Text, Error, NotFound
- [ ] Create `BarcodeFormat` enum

#### Phase 2: ImageAnalyzer expect/actual

- [ ] Create `ImageAnalyzer` expect declaration
  - analyze(imageData: ByteArray): AnalysisResult
- [ ] Android actual implementation (ML Kit)
  - BarcodeScannerOptions, BarcodeScanning.getClient()
- [ ] iOS actual implementation (Vision)
  - VNDetectBarcodesRequest, VNImageRequestHandler

---

### Real-time Analysis Feature Checklist

#### Phase 1: RealtimeAnalyzer expect/actual

- [ ] Create `RealtimeAnalyzer` expect declaration
  - start(onResult), stop(), isAnalyzing
- [ ] Android actual implementation (CameraX ImageAnalysis)
  - ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST
  - Throttling implementation (200ms interval)
- [ ] iOS actual implementation (AVCaptureVideoDataOutput)
  - AVCaptureVideoDataOutputSampleBufferDelegateProtocol
  - Dedicated queue with dispatch_queue_create

#### Phase 2: ScannerViewModel

- [ ] Create `ScannerUiState` data class
- [ ] Create `ScannerEvent` sealed interface
- [ ] Create `ScannerViewModel`
  - startScanning(), stopScanning()
  - Auto-stop on successful detection

#### Phase 3: Performance Optimization

- [ ] Adjust throttling interval (100-500ms)
- [ ] Verify backpressure strategy
- [ ] Check for memory leaks (callback release)

---

### Implementation Notes

1. **expect/actual correspondence verification**
   - Consider Factory pattern when constructor arguments differ between platforms
   - Common interface + DI for dependency injection is also viable

2. **Lifecycle management**
   - Android: Integration with LifecycleOwner
   - iOS: Explicit resource release in deinit

3. **Testing strategy**
   - ViewModel tests in commonTest (using FakeCameraController)
   - Verify platform-specific code with integration tests

---

## Related Documents

- [kmp-architecture.md](kmp-architecture.md) - Overall KMP architecture
- [kmp-auth.md](kmp-auth.md) - Authentication implementation Best Practices
