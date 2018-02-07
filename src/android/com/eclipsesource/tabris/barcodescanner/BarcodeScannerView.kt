package com.eclipsesource.tabris.barcodescanner

import android.Manifest.permission.CAMERA
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.support.v4.app.ActivityCompat
import android.support.v4.content.ContextCompat.checkSelfPermission
import android.support.v4.content.PermissionChecker.PERMISSION_GRANTED
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.eclipsesource.tabris.android.TabrisContext
import com.eclipsesource.tabris.android.internal.toolkit.AppState
import com.eclipsesource.tabris.android.internal.toolkit.IAppStateListener
import com.google.android.gms.vision.CameraSource
import com.google.android.gms.vision.Detector
import com.google.android.gms.vision.MultiProcessor
import com.google.android.gms.vision.Tracker
import com.google.android.gms.vision.barcode.Barcode
import com.google.android.gms.vision.barcode.BarcodeDetector

private const val PERMISSION_RC_CAMERA = 20001

@SuppressLint("ViewConstructor", "MissingPermission")
class BarcodeScannerView(private val activity: Activity, private val tabrisContext: TabrisContext)
  : SurfaceView(activity), IAppStateListener {

  val barcodeNames = mapOf(
      Barcode.CODE_128 to "code128",
      Barcode.CODE_39 to "code39",
      Barcode.CODE_93 to "code93",
      Barcode.CODABAR to "codabar",
      Barcode.DATA_MATRIX to "dataMatrix",
      Barcode.EAN_13 to "ean13",
      Barcode.EAN_8 to "ean8",
      Barcode.ITF to "itf",
      Barcode.QR_CODE to "qrCode",
      Barcode.UPC_A to "upcA",
      Barcode.UPC_E to "upcE",
      Barcode.PDF417 to "pdf417",
      Barcode.AZTEC to "aztec"
  )

  var camera = CameraSource.CAMERA_FACING_BACK

  private var cameraSource: CameraSource? = null
  private var surfaceCreated = false
  private var startRequested = false

  init {
    holder.addCallback(object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder?) {
        surfaceCreated = true
        startWhenReady()
      }

      override fun surfaceChanged(holder: SurfaceHolder?, format: Int, width: Int, height: Int) {
      }

      override fun surfaceDestroyed(holder: SurfaceHolder?) {
      }
    })
  }

  override fun stateChanged(appState: AppState, intent: Intent?) {
    when (appState) {
      AppState.RESUME -> startWhenReady()
      AppState.PAUSE -> cameraSource?.stop()
    }
  }

  fun start(formats: Int) {
    if (checkSelfPermission(activity, CAMERA) == PERMISSION_GRANTED) {
      startCamera(formats)
    } else {
      ActivityCompat.requestPermissions(activity, arrayOf(CAMERA), PERMISSION_RC_CAMERA)
      tabrisContext.widgetToolkit.addRequestPermissionResult { requestCode, _, results ->
        if (requestCode == PERMISSION_RC_CAMERA && results.elementAtOrNull(0) == PERMISSION_GRANTED) {
          startCamera(formats)
        }
      }
    }
  }

  private fun startCamera(formats: Int) {
    val detector = BarcodeDetector.Builder(activity).setBarcodeFormats(formats).build()
    detector.setProcessor(MultiProcessor.Builder<Barcode>(MultiProcessor.Factory {
      BarcodeTracker(tabrisContext, this)
    }).build())

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
    if (surfaceCreated && startRequested) {
      cameraSource?.start(holder)
    }
  }

  fun stop() {
    cameraSource?.stop()
  }

  fun destroy() {
    surfaceCreated = false
    startRequested = false
    cameraSource?.release()
    cameraSource = null
  }

}

private class BarcodeTracker(
    private val tabrisContext: TabrisContext,
    private val barcodeScannerView: BarcodeScannerView)
  : Tracker<Barcode>() {

  /**
   * Start tracking the detected face instance within the face overlay.
   */
  override fun onNewItem(barcodeId: Int, barcode: Barcode) {
    tabrisContext.widgetToolkit.executeInUiThread({
      tabrisContext.objectRegistry.getRemoteObjectForObject(barcodeScannerView)
          ?.notify("detect", mapOf(
              "format" to barcodeScannerView.barcodeNames[barcode.format],
              "data" to barcode.rawValue))
    })
  }

  /**
   * Update the position/characteristics of the face within the overlay.
   */
  override fun onUpdate(detectionResults: Detector.Detections<Barcode>, barcode: Barcode) {
//    println("onUpdate $barcode")
  }

  /**
   * Hide the graphic when the corresponding face was not detected.  This can happen for
   * intermediate frames temporarily (e.g., if the face was momentarily blocked from
   * view).
   */
  override fun onMissing(detectionResults: Detector.Detections<Barcode>) {
//    println("onMissing $detectionResults.")
  }

  /**
   * Called when the face is assumed to be gone for good. Remove the graphic annotation from
   * the overlay.
   */
  override fun onDone() {
//    println("onDone")
  }
}