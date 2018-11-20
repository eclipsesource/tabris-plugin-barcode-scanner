package com.eclipsesource.tabris.barcodescanner

import com.eclipsesource.tabris.android.ActivityScope
import com.eclipsesource.tabris.android.Property
import com.eclipsesource.tabris.android.StringProperty
import com.eclipsesource.tabris.android.internal.ktx.asSequence
import com.eclipsesource.tabris.android.internal.ktx.getArrayOrNull
import com.eclipsesource.tabris.android.internal.ktx.getStringOrNull
import com.eclipsesource.tabris.android.internal.nativeobject.view.ViewHandler
import com.eclipsesource.v8.V8Object
import com.google.android.gms.vision.CameraSource.CAMERA_FACING_BACK
import com.google.android.gms.vision.CameraSource.CAMERA_FACING_FRONT
import com.google.android.gms.vision.barcode.Barcode.ALL_FORMATS

@Suppress("PARAMETER_NAME_CHANGED_ON_OVERRIDE")
class BarcodeScannerViewHandler(private val scope: ActivityScope) : ViewHandler<BarcodeScannerView>(scope) {

  override val type = "com.eclipsesource.barcodescanner.BarcodeScannerView"

  override val properties: List<Property<*, *>> by lazy {
    super.properties + listOf<Property<BarcodeScannerView, *>>(
        StringProperty("scaleMode", { scaleMode = ScaleMode.find(it) ?: ScaleMode.FIT })
    )
  }

  override fun create(id: String, properties: V8Object): BarcodeScannerView {
    return BarcodeScannerView(scope).apply {
      camera = if (properties.getStringOrNull("camera") == "front") CAMERA_FACING_FRONT else CAMERA_FACING_BACK
      scope.events.addActivityStateListener(this)
    }
  }

  override fun call(scannerView: BarcodeScannerView, method: String, properties: V8Object): Any? {
    return when (method) {
      "start" -> scannerView.start(getFormats(properties))
      "stop" -> scannerView.stop()
      else -> super.call(scannerView, method, properties)
    }
  }

  private fun getFormats(properties: V8Object): Int {
    val formatIds = properties.getArrayOrNull("formats")?.asSequence<String>()?.map {
      BARCODE_NAMES.entries.firstOrNull { entry -> entry.value == it }?.key ?: ALL_FORMATS
    } ?: sequenceOf(ALL_FORMATS)
    return formatIds.fold(ALL_FORMATS, Int::or)
  }

  override fun destroy(scannerView: BarcodeScannerView) {
    scannerView.stop()
    scope.events.removeActivityStateListener(scannerView)
    super.destroy(scannerView)
  }

}
