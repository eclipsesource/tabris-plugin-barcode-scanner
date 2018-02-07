package com.eclipsesource.tabris.barcodescanner

import android.app.Activity
import com.eclipsesource.tabris.android.AbstractViewOperator
import com.eclipsesource.tabris.android.Properties
import com.eclipsesource.tabris.android.TabrisContext
import com.google.android.gms.vision.CameraSource.CAMERA_FACING_BACK
import com.google.android.gms.vision.CameraSource.CAMERA_FACING_FRONT
import com.google.android.gms.vision.barcode.Barcode

class BarcodeScannerViewOperator(activity: Activity, tabrisContext: TabrisContext)
  : AbstractViewOperator<BarcodeScannerView>(activity, tabrisContext) {

  private val propertyHandler by lazy { BarcodeScannerViewPropertyHandler(activity, tabrisContext) }

  override fun getType() = "com.eclipsesource.barcodescanner.BarcodeScannerView"

  override fun getPropertyHandler(view: BarcodeScannerView) = propertyHandler

  override fun createView(properties: Properties): BarcodeScannerView {
    return BarcodeScannerView(activity, tabrisContext).apply {
      camera = if (properties.getString("camera") == "front") CAMERA_FACING_FRONT else CAMERA_FACING_BACK
      tabrisContext.widgetToolkit.addAppStateListener(this)
    }
  }

  override fun call(scannerView: BarcodeScannerView, method: String, properties: Properties): Any? {
    return when (method) {
      "start" -> scannerView.start(getFormats(scannerView, properties));
      "stop" -> scannerView.stop();
      else -> super.call(scannerView, method, properties)
    }
  }

  private fun getFormats(scannerView: BarcodeScannerView, properties: Properties): Int {
    return properties.getListSafe("formats", String::class.java)
        .map { scannerView.barcodeNames.entries.first { entry -> entry.value == it }.key }
        .fold(Barcode.ALL_FORMATS, Int::or)
  }

  override fun destroy(scannerView: BarcodeScannerView) {
    scannerView.stop()
    tabrisContext.widgetToolkit.removeAppStateListener(scannerView)
    super.destroy(scannerView)
  }
}
