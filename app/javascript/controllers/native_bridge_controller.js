import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoStart: Boolean
  }

  static targets = ["status", "transcription", "tts", "latitude", "longitude", "weather"]

  connect() {
    this.updateStatus(this.bridge ? "bridge-connected" : "bridge-unavailable")
    this.startRecordingIfRequested()
  }

  startRecording() {
    if (!this.ensureBridge("startRecording")) return
    this.bridge.startRecording()
    this.updateStatus("start_recording sent")
  }

  stopRecording() {
    if (!this.ensureBridge("stopRecording")) return
    this.bridge.stopRecording()
    this.updateStatus("stop_recording sent")
  }

  sendTranscription() {
    if (!this.ensureBridge("onTranscription")) return
    const text = this.transcriptionTarget.value.trim()
    if (text.length === 0) {
      this.updateStatus("transcription text is empty")
      return
    }
    this.bridge.onTranscription(text)
    this.updateStatus("transcription sent")
  }

  sendLocation() {
    if (!this.ensureBridge("onLocation")) return
    const latitude = Number(this.latitudeTarget.value)
    const longitude = Number(this.longitudeTarget.value)
    const weather = this.weatherTarget.value.trim() || "clear"

    if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
      this.updateStatus("invalid location values")
      return
    }

    this.bridge.onLocation(latitude, longitude, weather)
    this.updateStatus("location_update sent")
  }

  requestCurrentLocation() {
    if (!this.ensureBridge("requestCurrentLocation")) return
    this.bridge.requestCurrentLocation()
    this.updateStatus("request_current_location sent")
  }

  playAudio() {
    if (!this.ensureBridge("playAudio")) return
    const text = this.ttsTarget.value.trim()
    if (text.length === 0) {
      this.updateStatus("tts text is empty")
      return
    }
    this.bridge.playAudio(text)
    this.updateStatus("play_audio requested")
  }

  ensureBridge(methodName) {
    if (!this.bridge || typeof this.bridge[methodName] !== "function") {
      this.updateStatus(`bridge method unavailable: ${methodName}`)
      return false
    }
    return true
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.dataset.state = this.statusState(message)
    }
  }

  statusState(message) {
    if (/unavailable|empty|invalid/i.test(message)) return "error"
    if (/sent|requested|connected/i.test(message)) return "ok"
    return "info"
  }

  get bridge() {
    return window.SoleTalkBridge
  }

  startRecordingIfRequested() {
    if (!this.autoStartValue) return
    if (!this.bridge || typeof this.bridge.startRecording !== "function") return

    this.bridge.startRecording()
    this.updateStatus("auto start recording sent")
  }
}
