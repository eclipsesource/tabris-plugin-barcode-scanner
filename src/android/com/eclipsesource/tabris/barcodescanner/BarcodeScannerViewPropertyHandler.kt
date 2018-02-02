package com.eclipsesource.tabris.barcodescanner

import android.app.Activity
import com.eclipsesource.tabris.android.Properties
import com.eclipsesource.tabris.android.TabrisContext
import com.eclipsesource.tabris.android.ViewPropertyHandler

class BarcodeScannerViewPropertyHandler(activity: Activity, tabrisContext: TabrisContext)
  : ViewPropertyHandler<BarcodeScannerView>(activity, tabrisContext) {

  override fun set(barcodeScannerView: BarcodeScannerView, properties: Properties) {
    super.set(barcodeScannerView, properties)
  }

}
