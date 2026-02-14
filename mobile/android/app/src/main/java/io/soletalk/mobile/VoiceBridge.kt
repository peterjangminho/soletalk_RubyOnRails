package io.soletalk.mobile

import android.content.Context
import android.speech.tts.TextToSpeech
import android.webkit.JavascriptInterface
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
  private var sessionId: String = ""
  private var googleSub: String = ""
  private var bridgeToken: String = ""
  private var textToSpeech: TextToSpeech? = null
  private var ttsReady: Boolean = false

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
  }

  @JavascriptInterface
  fun stopRecording() {
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
  fun playAudio(text: String) {
    if (text.isBlank() || !ttsReady) return
    textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "soletalk_tts")
  }

  fun release() {
    textToSpeech?.stop()
    textToSpeech?.shutdown()
    textToSpeech = null
    ttsReady = false
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
