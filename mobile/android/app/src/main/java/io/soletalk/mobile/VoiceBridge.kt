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
import android.webkit.JavascriptInterface
import androidx.core.content.ContextCompat
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.Locale

class VoiceBridge(context: Context) {
  companion object {
    private val JSON = "application/json; charset=utf-8".toMediaType()
    private const val API_URL = "https://soletalk-rails-production.up.railway.app/api/voice/events"
  }

  private val client = OkHttpClient()
  private val appContext = context.applicationContext
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
    textToSpeech = TextToSpeech(context) { status ->
      if (status == TextToSpeech.SUCCESS) {
        ttsReady = true
        textToSpeech?.language = Locale.KOREAN
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
    postVoiceEvent("start_recording", JSONObject())
    mainHandler.post {
      if (!hasAudioPermission() || isListening || !SpeechRecognizer.isRecognitionAvailable(appContext)) {
        return@post
      }
      ensureSpeechRecognizer()
      speechRecognizer?.startListening(recognitionIntent)
      isListening = true
    }
  }

  @JavascriptInterface
  fun stopRecording() {
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
    val payload = JSONObject().put("text", text)
    postVoiceEvent("transcription", payload)
  }

  @JavascriptInterface
  fun onLocation(latitude: Double, longitude: Double, weather: String) {
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

    bestLocation?.let { onLocation(it.latitude, it.longitude, "unknown") }
  }

  @JavascriptInterface
  fun playAudio(text: String) {
    if (text.isBlank() || !ttsReady) return
    textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "soletalk_tts")
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

  private fun postVoiceEvent(action: String, payload: JSONObject) {
    if (sessionId.isBlank() || googleSub.isBlank()) return

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
      client.newCall(request).execute().close()
    }.start()
  }
}
