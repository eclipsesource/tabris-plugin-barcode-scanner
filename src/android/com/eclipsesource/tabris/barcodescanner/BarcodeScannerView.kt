package com.eclipsesource.tabris.barcodescanner

import android.Manifest.permission.CAMERA
import android.annotation.SuppressLint
import android.app.Activity
import android.support.v4.app.ActivityCompat
import android.support.v4.content.ContextCompat.checkSelfPermission
import android.support.v4.content.PermissionChecker.PERMISSION_GRANTED
import android.view.View
import com.eclipsesource.tabris.android.TabrisContext

private const val PERMISSION_RC_CAMERA = 20001

@SuppressLint("ViewConstructor")
class BarcodeScannerView(private val activity: Activity, private val tabrisContext: TabrisContext)
  : View(activity) {

  fun start() {
    if (checkSelfPermission(activity, CAMERA) == PERMISSION_GRANTED) {
      startCamera()
    } else {
      ActivityCompat.requestPermissions(activity, arrayOf(CAMERA), PERMISSION_RC_CAMERA)
      tabrisContext.widgetToolkit.addRequestPermissionResult { requestCode, _, results ->
        if (requestCode == PERMISSION_RC_CAMERA && results.elementAtOrNull(0) == PERMISSION_GRANTED) {
          startCamera()
        }
      }
    }
  }

  private fun startCamera() {

  }

  fun stop() {

  }

}