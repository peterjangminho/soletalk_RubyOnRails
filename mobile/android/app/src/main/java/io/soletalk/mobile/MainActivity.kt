package io.soletalk.mobile

import android.annotation.SuppressLint
import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.appcompat.app.AppCompatActivity
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.OnBackPressedCallback

class MainActivity : AppCompatActivity() {
  companion object {
    private const val TAG = "MainActivity"
    private const val MOBILE_RETURN_URI = "soletalk://auth"
    private const val RUNTIME_PERMISSION_REQUEST_CODE = 2001
  }

  private lateinit var webView: WebView
  private lateinit var voiceBridge: VoiceBridge
  private var shouldReloadAfterOauth: Boolean = false
  private val baseUrl: String by lazy { normalizeBaseUrl(BuildConfig.WEB_BASE_URL) }
  private val baseUri: Uri by lazy { Uri.parse(baseUrl) }

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    webView = findViewById(R.id.webview)
    webView.settings.javaScriptEnabled = true
    webView.settings.domStorageEnabled = true
    webView.settings.cacheMode = android.webkit.WebSettings.LOAD_NO_CACHE
    webView.webViewClient = object : WebViewClient() {
      override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
        Log.d(TAG, "webview request: ${request.method} ${request.url}")
        return super.shouldInterceptRequest(view, request)
      }

      override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        if (shouldOpenInExternalBrowser(request.url)) {
          val externalUri = resolveExternalBrowserUri(request.url)
          Log.i(TAG, "open external browser for oauth url=$externalUri")
          shouldReloadAfterOauth = true
          openInExternalBrowser(externalUri)
          return true
        }
        Log.d(TAG, "webview navigate: ${request.method} ${request.url}")
        return super.shouldOverrideUrlLoading(view, request)
      }

      override fun onPageFinished(view: WebView, url: String) {
        super.onPageFinished(view, url)
        Log.i(TAG, "webview page finished: $url")
      }

      override fun onReceivedError(
        view: WebView,
        request: WebResourceRequest,
        error: WebResourceError
      ) {
        super.onReceivedError(view, request, error)
        Log.e(TAG, "webview received error: code=${error.errorCode} desc=${error.description} url=${request.url}")
      }

      override fun onReceivedHttpError(
        view: WebView,
        request: WebResourceRequest,
        errorResponse: WebResourceResponse
      ) {
        super.onReceivedHttpError(view, request, errorResponse)
        Log.w(TAG, "webview received http error: status=${errorResponse.statusCode} url=${request.url}")
      }
    }
    webView.webChromeClient = object : WebChromeClient() {
      override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
        Log.d(TAG, "webview console: ${consoleMessage.messageLevel()} ${consoleMessage.message()} @${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
        return super.onConsoleMessage(consoleMessage)
      }
    }
    voiceBridge = VoiceBridge(this)
    webView.addJavascriptInterface(voiceBridge, "SoleTalkBridge")

    onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
      override fun handleOnBackPressed() {
        if (webView.canGoBack()) {
          webView.goBack()
        } else {
          isEnabled = false
          onBackPressedDispatcher.onBackPressed()
        }
      }
    })

    val initialUrl = resolveInitialUrl(intent)
    Log.i(TAG, "loading initial url: $initialUrl (base=$baseUrl)")
    webView.loadUrl(initialUrl)
  }

  override fun onResume() {
    super.onResume()
    if (shouldReloadAfterOauth) {
      shouldReloadAfterOauth = false
      Log.i(TAG, "resume after oauth - reload base url")
      webView.loadUrl(baseUrl)
    }
  }

  override fun onNewIntent(intent: android.content.Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    if (intent.data != null) {
      // Deep-link return means OAuth completion path should drive WebView navigation.
      // Prevent onResume fallback reload from racing and dropping the handoff exchange.
      shouldReloadAfterOauth = false
    }
    val targetUrl = resolveInitialUrl(intent)
    if (targetUrl != baseUrl) {
      Log.i(TAG, "onNewIntent load url: $targetUrl")
      webView.loadUrl(targetUrl)
    }
  }

  override fun onDestroy() {
    if (::voiceBridge.isInitialized) {
      voiceBridge.release()
    }
    super.onDestroy()
  }

  @Deprecated("Deprecated in Java")
  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode != RUNTIME_PERMISSION_REQUEST_CODE) return

    permissions.forEachIndexed { index, permission ->
      val granted = grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
      Log.i(TAG, "permission result: $permission granted=$granted")
    }
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
      Log.i(TAG, "requesting runtime permissions: ${missingPermissions.joinToString()}")
      ActivityCompat.requestPermissions(
        this,
        missingPermissions.toTypedArray(),
        RUNTIME_PERMISSION_REQUEST_CODE
      )
    } else {
      Log.i(TAG, "runtime permissions already granted")
    }
  }

  private fun shouldOpenInExternalBrowser(uri: Uri): Boolean {
    if (baseUri.scheme != "https") return false

    val host = uri.host.orEmpty()
    val path = uri.path.orEmpty()
    if (host == "accounts.google.com") return true
    return host == baseUri.host.orEmpty() && path.startsWith("/auth/google_oauth2")
  }

  private fun resolveExternalBrowserUri(uri: Uri): Uri {
    val host = uri.host.orEmpty()
    val path = uri.path.orEmpty()
    if (host != baseUri.host.orEmpty() || !path.startsWith("/auth/google_oauth2")) {
      return uri
    }
    val builder = uri.buildUpon()
    if (path == "/auth/google_oauth2") {
      builder.path("/auth/google_oauth2/start")
    }
    if (uri.getQueryParameter("mobile_return").isNullOrBlank()) {
      builder.appendQueryParameter("mobile_return", MOBILE_RETURN_URI)
    }
    return builder.build()
  }

  private fun openInExternalBrowser(uri: Uri) {
    val customTabsIntent = CustomTabsIntent.Builder().build()
    customTabsIntent.launchUrl(this, uri)
  }

  private fun resolveInitialUrl(intent: android.content.Intent?): String {
    val dataUri = intent?.data ?: return baseUrl
    if (dataUri.scheme == "soletalk" && dataUri.host == "auth") {
      val handoff = dataUri.getQueryParameter("handoff")
      if (!handoff.isNullOrBlank()) {
        return "${baseUrl}api/auth/google/mobile_handoff?handoff=${Uri.encode(handoff)}"
      }
      return baseUrl
    }
    val data = dataUri.toString()
    return if (data.startsWith(baseUrl.removeSuffix("/"))) data else baseUrl
  }

  private fun normalizeBaseUrl(rawBaseUrl: String): String {
    return if (rawBaseUrl.endsWith("/")) rawBaseUrl else "$rawBaseUrl/"
  }
}
