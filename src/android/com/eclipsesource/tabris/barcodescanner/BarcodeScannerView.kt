package com.eclipsesource.tabris.barcodescanner

import android.Manifest.permission.CAMERA
import android.annotation.SuppressLint
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.FrameLayout
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.view.LifecycleCameraController
import androidx.camera.view.PreviewView
import androidx.camera.view.PreviewView.ScaleType
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.checkSelfPermission
import androidx.core.content.PermissionChecker.PERMISSION_GRANTED
import com.eclipsesource.tabris.android.ActivityScope
import com.eclipsesource.tabris.android.Events.RequestPermissionsResultListener
import com.eclipsesource.tabris.android.RemoteObject
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

val BARCODE_NAMES = mapOf(
    Barcode.FORMAT_CODE_128 to "code128",
    Barcode.FORMAT_CODE_39 to "code39",
    Barcode.FORMAT_CODE_93 to "code93",
    Barcode.FORMAT_CODABAR to "codabar",
    Barcode.FORMAT_DATA_MATRIX to "dataMatrix",
    Barcode.FORMAT_EAN_13 to "ean13",
    Barcode.FORMAT_EAN_8 to "ean8",
    Barcode.FORMAT_ITF to "itf",
    Barcode.FORMAT_QR_CODE to "qr",
    Barcode.FORMAT_UPC_A to "upcA",
    Barcode.FORMAT_UPC_E to "upcE",
    Barcode.FORMAT_PDF417 to "pdf417",
    Barcode.FORMAT_AZTEC to "aztec"
)

enum class ScaleMode(val id: String, val scaleType: ScaleType) {

    FIT("fit", ScaleType.FIT_CENTER), FILL("fill", ScaleType.FILL_CENTER);

    companion object {
        fun find(id: String?) = values().find { it.id == id }
    }
}

@SuppressLint("ViewConstructor")
class BarcodeScannerView(private val scope: ActivityScope, private val selector: CameraSelector) :
    FrameLayout(scope.activity) {

    var scaleMode: ScaleMode = ScaleMode.FIT
        set(value) {
            field = value
            previewView.scaleType = field.scaleType
        }
    private val rcPermissionCamera = 20001
    private var cameraController: LifecycleCameraController? = null
    private val previewView = PreviewView(scope.activity).also {
        it.scaleType = scaleMode.scaleType
        this.addView(it, MATCH_PARENT, MATCH_PARENT)
    }

    private class BarcodeAnalyzer(
        private val scanner: BarcodeScanner, val remoteObject: RemoteObject?
    ) : ImageAnalysis.Analyzer {

        @ExperimentalGetImage
        override fun analyze(imageProxy: ImageProxy) {
            imageProxy.image?.let { mediaImage ->
                val rotationDegrees = imageProxy.imageInfo.rotationDegrees
                val image = InputImage.fromMediaImage(mediaImage, rotationDegrees)
                scanner.process(image)
                    .addOnSuccessListener { barcodes ->
                        handleSuccess(barcodes, remoteObject)
                        imageProxy.close()
                    }
                    .addOnFailureListener {
                        remoteObject?.notify("error", "error", it.message)
                        imageProxy.close()
                    }
            }
        }

        fun handleSuccess(barcodes: List<Barcode>, remoteObject: RemoteObject?) {
            for (barcode in barcodes) {
                remoteObject?.notify(
                    "detect", mapOf(
                        "format" to BARCODE_NAMES[barcode.format],
                        "data" to barcode.rawValue
                    )
                )
            }
        }
    }

    fun start(formats: Int) {
        withCameraPermission(
            successCallback = { startCamera(formats) },
            errorCallback = {
                scope.remoteObject(this)
                    ?.notify("error", "error", "Camera permission not granted")
            }
        )
    }

    private fun withCameraPermission(successCallback: () -> Unit, errorCallback: () -> Unit) {
        if (checkSelfPermission(scope.activity, CAMERA) == PERMISSION_GRANTED) {
            successCallback.invoke()
        } else {
            scope.events.addRequestPermissionResultListener(object :
                RequestPermissionsResultListener {
                override fun onRequestPermissionsResult(
                    requestCode: Int,
                    permissions: Array<String>,
                    grantResults: IntArray
                ) {
                    if (requestCode == rcPermissionCamera) {
                        scope.events.removeRequestPermissionResultListener(this)
                        if (grantResults.elementAtOrNull(0) == PERMISSION_GRANTED) {
                            successCallback()
                        } else {
                            errorCallback()
                        }
                    }
                }

            })
            ActivityCompat.requestPermissions(scope.activity, arrayOf(CAMERA), rcPermissionCamera)
        }
    }

    private fun startCamera(formats: Int) {
        val scanner = BarcodeScanning.getClient(
            BarcodeScannerOptions.Builder().setBarcodeFormats(formats).build()
        )
        val remoteObject = scope.remoteObject(this@BarcodeScannerView)
        val barcodeAnalyzer = BarcodeAnalyzer(scanner, remoteObject)
        val executor = ContextCompat.getMainExecutor(scope.activity)
        cameraController = LifecycleCameraController(scope.activity).apply {
            cameraSelector = selector
            setImageAnalysisAnalyzer(executor, barcodeAnalyzer)
            bindToLifecycle(scope.activity)
        }
        previewView.controller = cameraController
    }

    fun stop() {
        cameraController?.unbind()
    }

}
