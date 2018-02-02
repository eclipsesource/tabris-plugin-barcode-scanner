package com.eclipsesource.tabris.barcodescanner

import android.app.Activity
import com.eclipsesource.tabris.android.AbstractViewOperator
import com.eclipsesource.tabris.android.Properties
import com.eclipsesource.tabris.android.TabrisContext

class BarcodeScannerViewOperator(activity: Activity, tabrisContext: TabrisContext)
  : AbstractViewOperator<BarcodeScannerView>(activity, tabrisContext) {

  private val propertyHandler by lazy { BarcodeScannerViewPropertyHandler(activity, tabrisContext) }

  override fun getType() = "com.eclipsesource.barcodescanner.BarcodeScannerView"

  override fun getPropertyHandler(view: BarcodeScannerView) = propertyHandler

  override fun createView(properties: Properties) = BarcodeScannerView(activity, tabrisContext)

  override fun call(scannerView: BarcodeScannerView, method: String, properties: Properties): Any? {
    return when (method) {
      "start" -> scannerView.start();
      "stop" -> scannerView.stop();
      else -> super.call(scannerView, method, properties)
    }
  }

}
