package io.soletalk.mobile

import android.annotation.SuppressLint
import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
  companion object {
    private const val BASE_URL = "https://soletalk-rails-production.up.railway.app/"
    private const val RUNTIME_PERMISSION_REQUEST_CODE = 2001
  }

  private lateinit var webView: WebView
  private lateinit var voiceBridge: VoiceBridge

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    requestRuntimePermissionsIfNeeded()

    webView = findViewById(R.id.webview)
    webView.settings.javaScriptEnabled = true
    webView.settings.domStorageEnabled = true
    webView.webViewClient = WebViewClient()
    voiceBridge = VoiceBridge(this)
    webView.addJavascriptInterface(voiceBridge, "SoleTalkBridge")
    webView.loadUrl(BASE_URL)
  }

  override fun onDestroy() {
    if (::voiceBridge.isInitialized) {
      voiceBridge.release()
    }
    super.onDestroy()
  }

  private fun requestRuntimePermissionsIfNeeded() {
    val requiredPermissions = listOf(
      Manifest.permission.RECORD_AUDIO,
      Manifest.permission.ACCESS_FINE_LOCATION
    )
    val missingPermissions = requiredPermissions.filter {
      ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
    }
    if (missingPermissions.isNotEmpty()) {
      ActivityCompat.requestPermissions(
        this,
        missingPermissions.toTypedArray(),
        RUNTIME_PERMISSION_REQUEST_CODE
      )
    }
  }
}
