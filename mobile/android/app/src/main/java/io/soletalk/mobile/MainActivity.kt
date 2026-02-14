package io.soletalk.mobile

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
  companion object {
    private const val BASE_URL = "https://soletalk-rails-production.up.railway.app/"
  }

  private lateinit var webView: WebView

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    webView = findViewById(R.id.webview)
    webView.settings.javaScriptEnabled = true
    webView.settings.domStorageEnabled = true
    webView.webViewClient = WebViewClient()
    webView.addJavascriptInterface(VoiceBridge(), "SoleTalkBridge")
    webView.loadUrl(BASE_URL)
  }
}
