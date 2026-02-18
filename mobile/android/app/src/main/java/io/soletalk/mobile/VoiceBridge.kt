package io.soletalk.mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import android.webkit.JavascriptInterface
import androidx.core.content.ContextCompat
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.Locale

class VoiceBridge(private val activity: android.app.Activity) {
  companion object {
    private const val TAG = "VoiceBridge"
    private val JSON = "application/json; charset=utf-8".toMediaType()
    private const val API_URL = "https://soletalk-rails-production.up.railway.app/api/voice/events"
    private const val WEATHER_API_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=weather_code"
    private const val RUNTIME_PERMISSION_REQUEST_CODE = 2001
  }

  private val client = OkHttpClient()
  private val appContext = activity.applicationContext
  private val mainHandler = Handler(Looper.getMainLooper())
  private val recognitionIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
    putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.KOREAN.toLanguageTag())
    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
  }
  private var sessionId: String = ""
  private var googleSub: String = ""
  private var bridgeToken: String = ""
  private var textToSpeech: TextToSpeech? = null
  private var speechRecognizer: SpeechRecognizer? = null
  private var ttsReady: Boolean = false
  private var isListening: Boolean = false

  init {
    Log.i(TAG, "initializing VoiceBridge")
    textToSpeech = TextToSpeech(appContext) { status ->
      if (status == TextToSpeech.SUCCESS) {
        ttsReady = true
        textToSpeech?.language = Locale.KOREAN
        Log.i(TAG, "TTS initialized successfully")
      } else {
        Log.e(TAG, "TTS initialization failed: status=$status")
      }
    }
  }

  @JavascriptInterface
  fun setSession(sessionId: String, googleSub: String) {
    this.sessionId = sessionId
    this.googleSub = googleSub
  }

  @JavascriptInterface
  fun setSession(sessionId: String, googleSub: String, bridgeToken: String) {
    this.sessionId = sessionId
    this.googleSub = googleSub
    this.bridgeToken = bridgeToken
  }

  @JavascriptInterface
  fun startRecording() {
    Log.i(TAG, "startRecording requested")
    postVoiceEvent("start_recording", JSONObject())
    mainHandler.post {
      if (!hasAudioPermission() || isListening || !SpeechRecognizer.isRecognitionAvailable(appContext)) {
        Log.w(TAG, "startRecording skipped: audio_permission=${hasAudioPermission()} isListening=$isListening available=${SpeechRecognizer.isRecognitionAvailable(appContext)}")
        return@post
      }
      ensureSpeechRecognizer()
      speechRecognizer?.startListening(recognitionIntent)
      isListening = true
    }
  }

  @JavascriptInterface
  fun stopRecording() {
    Log.i(TAG, "stopRecording requested")
    mainHandler.post {
      if (isListening) {
        speechRecognizer?.stopListening()
      }
      isListening = false
    }
    postVoiceEvent("stop_recording", JSONObject())
  }

  @JavascriptInterface
  fun onTranscription(text: String) {
    Log.d(TAG, "onTranscription length=${text.length}")
    val payload = JSONObject().put("text", text)
    postVoiceEvent("transcription", payload)
  }

  @JavascriptInterface
  fun onLocation(latitude: Double, longitude: Double, weather: String) {
    Log.d(TAG, "onLocation lat=$latitude lon=$longitude weather=$weather")
    val payload = JSONObject()
      .put("latitude", latitude)
      .put("longitude", longitude)
      .put("weather", weather)
    postVoiceEvent("location_update", payload)
  }

  @JavascriptInterface
  fun requestCurrentLocation() {
    if (!hasLocationPermission()) return

    val locationManager = appContext.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return
    val providers = locationManager.getProviders(true)
    var bestLocation: Location? = null

    providers.forEach { provider ->
      val location = runCatching { locationManager.getLastKnownLocation(provider) }.getOrNull() ?: return@forEach
      if (bestLocation == null || location.accuracy < bestLocation!!.accuracy) {
        bestLocation = location
      }
    }

    bestLocation?.let { location ->
      Thread {
        val weather = fetchWeatherSummary(location.latitude, location.longitude)
        onLocation(location.latitude, location.longitude, weather)
      }.start()
    } ?: Log.w(TAG, "requestCurrentLocation: no location available")
  }

  @JavascriptInterface
  fun playAudio(text: String) {
    if (text.isBlank() || !ttsReady) return
    Log.d(TAG, "playAudio length=${text.length}")
    textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "soletalk_tts")
  }

  @JavascriptInterface
  fun requestPermissions() {
    val requiredPermissions = listOf(
      Manifest.permission.RECORD_AUDIO,
      Manifest.permission.ACCESS_FINE_LOCATION
    )
    val missingPermissions = requiredPermissions.filter {
      ContextCompat.checkSelfPermission(appContext, it) != PackageManager.PERMISSION_GRANTED
    }
    if (missingPermissions.isNotEmpty()) {
      Log.i(TAG, "requesting runtime permissions: ${missingPermissions.joinToString()}")
      activity.runOnUiThread {
        androidx.core.app.ActivityCompat.requestPermissions(
          activity,
          missingPermissions.toTypedArray(),
          RUNTIME_PERMISSION_REQUEST_CODE
        )
      }
    } else {
      Log.i(TAG, "runtime permissions already granted")
    }
  }

  fun release() {
    speechRecognizer?.destroy()
    speechRecognizer = null
    isListening = false
    textToSpeech?.stop()
    textToSpeech?.shutdown()
    textToSpeech = null
    ttsReady = false
  }

  private fun ensureSpeechRecognizer() {
    if (speechRecognizer != null) return
    Log.i(TAG, "creating SpeechRecognizer")
    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(appContext).apply {
      setRecognitionListener(object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {
          isListening = false
        }

        override fun onError(error: Int) {
          Log.e(TAG, "SpeechRecognizer error=$error")
          isListening = false
        }

        override fun onResults(results: Bundle?) {
          emitTranscription(results)
          isListening = false
        }

        override fun onPartialResults(partialResults: Bundle?) {
          emitTranscription(partialResults)
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
      })
    }
  }

  private fun emitTranscription(results: Bundle?) {
    val texts = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION) ?: return
    val best = texts.firstOrNull()?.trim().orEmpty()
    if (best.isNotEmpty()) {
      onTranscription(best)
    }
  }

  private fun hasAudioPermission(): Boolean {
    return ContextCompat.checkSelfPermission(
      appContext,
      Manifest.permission.RECORD_AUDIO
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun hasLocationPermission(): Boolean {
    return ContextCompat.checkSelfPermission(
      appContext,
      Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun fetchWeatherSummary(latitude: Double, longitude: Double): String {
    val url = WEATHER_API_URL.format(Locale.US, latitude, longitude)
    val request = Request.Builder().url(url).build()
    return runCatching {
      client.newCall(request).execute().use { response ->
        if (!response.isSuccessful) return@use "unknown"
        val body = response.body?.string().orEmpty()
        val weatherCode = JSONObject(body).optJSONObject("current")?.optInt("weather_code", -1) ?: -1
        mapWeatherCode(weatherCode)
      }
    }.onFailure {
      Log.w(TAG, "weather lookup failed: ${it.message}")
    }.getOrDefault("unknown")
  }

  private fun mapWeatherCode(code: Int): String {
    return when (code) {
      0 -> "clear"
      1, 2, 3 -> "cloudy"
      45, 48 -> "fog"
      51, 53, 55, 56, 57 -> "drizzle"
      61, 63, 65, 66, 67, 80, 81, 82 -> "rain"
      71, 73, 75, 77, 85, 86 -> "snow"
      95, 96, 99 -> "thunder"
      else -> "unknown"
    }
  }

  private fun postVoiceEvent(action: String, payload: JSONObject) {
    if (sessionId.isBlank() || googleSub.isBlank()) {
      Log.w(TAG, "postVoiceEvent skipped($action): session/subject missing")
      return
    }

    val bodyJson = JSONObject()
      .put("event_action", action)
      .put("session_id", sessionId)
      .put("google_sub", googleSub)
      .put("payload", payload)
    if (bridgeToken.isNotBlank()) {
      bodyJson.put("bridge_token", bridgeToken)
    }

    val request = Request.Builder()
      .url(API_URL)
      .post(bodyJson.toString().toRequestBody(JSON))
      .build()

    Thread {
      runCatching {
        client.newCall(request).execute().use { response ->
          val responseBody = response.body?.string().orEmpty()
          Log.i(TAG, "postVoiceEvent action=$action code=${response.code} body=$responseBody")
        }
      }.onFailure {
        Log.e(TAG, "postVoiceEvent failed action=$action error=${it.message}")
      }
    }.start()
  }
}
