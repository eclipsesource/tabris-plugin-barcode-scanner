package com.eclipsesource.tabris.barcodescanner

import android.Manifest.permission.CAMERA
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.support.v4.app.ActivityCompat
import android.support.v4.content.ContextCompat.checkSelfPermission
import android.support.v4.content.PermissionChecker.PERMISSION_GRANTED
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.ViewGroup
import com.eclipsesource.tabris.android.RemoteObject
import com.eclipsesource.tabris.android.TabrisContext
import com.eclipsesource.tabris.android.internal.toolkit.AppState
import com.eclipsesource.tabris.android.internal.toolkit.IAppStateListener
import com.eclipsesource.tabris.android.internal.toolkit.IRequestPermissionResultListener
import com.google.android.gms.vision.CameraSource
import com.google.android.gms.vision.MultiProcessor
import com.google.android.gms.vision.Tracker
import com.google.android.gms.vision.barcode.Barcode
import com.google.android.gms.vision.barcode.BarcodeDetector

val BARCODE_NAMES = mapOf(
    Barcode.CODE_128 to "code128",
    Barcode.CODE_39 to "code39",
    Barcode.CODE_93 to "code93",
    Barcode.CODABAR to "codabar",
    Barcode.DATA_MATRIX to "dataMatrix",
    Barcode.EAN_13 to "ean13",
    Barcode.EAN_8 to "ean8",
    Barcode.ITF to "itf",
    Barcode.QR_CODE to "qr",
    Barcode.UPC_A to "upcA",
    Barcode.UPC_E to "upcE",
    Barcode.PDF417 to "pdf417",
    Barcode.AZTEC to "aztec"
)

enum class ScaleMode {
  FIT, FILL
}

@SuppressLint("ViewConstructor", "MissingPermission")
class BarcodeScannerView(private val activity: Activity, private val tabrisContext: TabrisContext)
  : ViewGroup(activity), IAppStateListener {

  val remoteObject: RemoteObject? get() = tabrisContext.objectRegistry.getRemoteObjectForObject(this)
  var camera = CameraSource.CAMERA_FACING_BACK
  var scaleMode: ScaleMode = ScaleMode.FIT
    set(value) {
      field = value
      requestLayout()
    }

  private val rcPermissionCamera = 20001
  private val multiProcessor = MultiProcessor.Builder<Barcode>(MultiProcessor.Factory {
    object : Tracker<Barcode>() {
      override fun onNewItem(id: Int, barcode: Barcode) {
        tabrisContext.widgetToolkit.executeInUiThread({
          remoteObject?.notify("detect",
              mapOf("format" to BARCODE_NAMES[barcode.format], "data" to barcode.rawValue))
        })
      }
    }
  }).build()
  private val cameraView: SurfaceView = SurfaceView(activity)
  private var cameraSource: CameraSource? = null
  private var surfaceAvailable = false
  private var startRequested = false
  private var formats = Barcode.ALL_FORMATS

  init {
    addView(cameraView)
    cameraView.holder.addCallback(object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder?) {
        surfaceAvailable = true
        startWhenReady()
      }

      override fun surfaceDestroyed(holder: SurfaceHolder?) {
        surfaceAvailable = false
      }

      override fun surfaceChanged(holder: SurfaceHolder?, format: Int, width: Int, height: Int) {
      }
    })
    addOnLayoutChangeListener { _, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
      if (left != oldLeft || top != oldTop || right != oldRight || bottom != oldBottom) {
        if (startRequested) {
          stop()
          start(formats)
        }
      }
    }
  }

  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    val layoutWidth = right - left
    val layoutHeight = bottom - top
    val layoutRatio = layoutWidth.toFloat() / layoutHeight.toFloat()
    var childWidth = layoutWidth
    var childHeight = layoutHeight
    cameraSource?.previewSize?.let {
      val frameRatio = if (resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT) {
        it.height.toFloat() / it.width.toFloat()
      } else {
        it.width.toFloat() / it.height.toFloat()
      }
      if (scaleMode == ScaleMode.FIT && frameRatio > layoutRatio
          || scaleMode == ScaleMode.FILL && frameRatio < layoutRatio) {
        childHeight = (childWidth * (1f / frameRatio)).toInt()
      } else {
        childWidth = (childHeight * frameRatio).toInt()
      }
    }
    val xOffset = layoutWidth / 2 - childWidth / 2
    val yOffset = layoutHeight / 2 - childHeight / 2
    for (i in 0 until childCount) {
      getChildAt(i).layout(xOffset, yOffset, childWidth + xOffset, childHeight + yOffset)
    }
  }

  override fun stateChanged(appState: AppState, intent: Intent?) {
    when (appState) {
      AppState.RESUME -> startWhenReady()
      AppState.PAUSE -> cameraSource?.stop()
    }
  }

  fun start(formats: Int) {
    withCameraPermission({
      startCamera(formats)
    }, {
      remoteObject?.notify("error", "error", "Camera permission not granted")
    })
  }

  private fun withCameraPermission(successCallback: () -> Unit, errorCallback: () -> Unit) {
    if (checkSelfPermission(activity, CAMERA) == PERMISSION_GRANTED) {
      successCallback.invoke()
    } else {
      tabrisContext.widgetToolkit.addRequestPermissionResult(object : IRequestPermissionResultListener {
        override fun permissionsResultReceived(code: Int, permissions: Array<out String>, results: IntArray) {
          if (code == rcPermissionCamera) {
            tabrisContext.widgetToolkit.removeRequestPermissionResult(this)
            if (results.elementAtOrNull(0) == PERMISSION_GRANTED) {
              successCallback.invoke()
            } else {
              errorCallback.invoke()
            }
          }
        }

      })
      ActivityCompat.requestPermissions(activity, arrayOf(CAMERA), rcPermissionCamera)
    }
  }

  private fun startCamera(formats: Int) {
    this.formats = formats
    val detector = BarcodeDetector.Builder(activity).setBarcodeFormats(formats).build().apply {
      setProcessor(multiProcessor)
    }
    cameraSource = CameraSource.Builder(activity, detector)
        .setRequestedPreviewSize(1024, 768)
        .setFacing(camera)
        .setAutoFocusEnabled(true)
        .setRequestedFps(30.0f)
        .build()
    startRequested = true
    startWhenReady()
  }

  private fun startWhenReady() {
    if (surfaceAvailable && startRequested) {
      try {
        cameraSource?.start(cameraView.holder)
        requestLayout()
      } catch (exception: Exception) {
        remoteObject?.notify("error", "error", exception.message)
      }
    }
  }

  fun stop() {
    cameraSource?.stop()
    cameraSource?.release()
    startRequested = false
    cameraSource = null
    formats = Barcode.ALL_FORMATS
  }

}
