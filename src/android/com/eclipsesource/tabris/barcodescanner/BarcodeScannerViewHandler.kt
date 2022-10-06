package com.eclipsesource.tabris.barcodescanner

import androidx.camera.core.CameraSelector.DEFAULT_BACK_CAMERA
import androidx.camera.core.CameraSelector.DEFAULT_FRONT_CAMERA
import com.eclipsesource.tabris.android.ActivityScope
import com.eclipsesource.tabris.android.Property
import com.eclipsesource.tabris.android.StringProperty
import com.eclipsesource.tabris.android.internal.ktx.asSequence
import com.eclipsesource.tabris.android.internal.ktx.getArrayOrNull
import com.eclipsesource.tabris.android.internal.ktx.getStringOrNull
import com.eclipsesource.tabris.android.internal.nativeobject.view.ViewHandler
import com.eclipsesource.v8.V8Object
import com.google.mlkit.vision.barcode.common.Barcode.FORMAT_ALL_FORMATS

@Suppress("PARAMETER_NAME_CHANGED_ON_OVERRIDE")
class BarcodeScannerViewHandler(private val scope: ActivityScope) :
    ViewHandler<BarcodeScannerView>(scope) {

    override val type = "com.eclipsesource.barcodescanner.BarcodeScannerView"

    override val properties: List<Property<*, *>> by lazy {
        super.properties + listOf<Property<BarcodeScannerView, *>>(
            StringProperty("scaleMode", { scaleMode = ScaleMode.find(it) ?: ScaleMode.FIT })
        )
    }

    override fun create(id: String, properties: V8Object): BarcodeScannerView {
        val isFrontFacing = properties.getStringOrNull("camera") == "front"
        val camera = if (isFrontFacing) DEFAULT_FRONT_CAMERA else DEFAULT_BACK_CAMERA
        return BarcodeScannerView(scope, camera)
    }

    override fun call(scannerView: BarcodeScannerView, method: String, properties: V8Object): Any? {
        return when (method) {
            "start" -> scannerView.start(getFormats(properties))
            "stop" -> scannerView.stop()
            else -> super.call(scannerView, method, properties)
        }
    }

    private fun getFormats(properties: V8Object): Int {
        val formatIds = properties.getArrayOrNull("formats")?.asSequence<String>()?.map { format ->
            BARCODE_NAMES.entries.firstOrNull { it.value == format }?.key ?: FORMAT_ALL_FORMATS
        } ?: sequenceOf(FORMAT_ALL_FORMATS)
        return formatIds.fold(FORMAT_ALL_FORMATS, Int::or)
    }

    override fun destroy(scannerView: BarcodeScannerView) {
        scannerView.stop()
        super.destroy(scannerView)
    }

}
