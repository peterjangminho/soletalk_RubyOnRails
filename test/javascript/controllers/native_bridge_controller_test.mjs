import test from "node:test"
import assert from "node:assert/strict"
import NativeBridgeController from "../../../app/javascript/controllers/native_bridge_controller.js"

test("native_bridge connect reports unavailable when bridge is missing", () => {
  global.window = {}
  const controller = new NativeBridgeController()
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "", dataset: {} }

  controller.connect()

  assert.equal(controller.statusTarget.textContent, "bridge-unavailable")
  assert.equal(controller.statusTarget.dataset.state, "error")
})

test("native_bridge sendTranscription rejects empty text", () => {
  global.window = { SoleTalkBridge: { onTranscription() {} } }
  const controller = new NativeBridgeController()
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "", dataset: {} }
  controller.transcriptionTarget = { value: "   " }

  controller.sendTranscription()

  assert.equal(controller.statusTarget.textContent, "transcription text is empty")
  assert.equal(controller.statusTarget.dataset.state, "error")
})

test("native_bridge sendLocation rejects invalid coordinates", () => {
  global.window = { SoleTalkBridge: { onLocation() {} } }
  const controller = new NativeBridgeController()
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "", dataset: {} }
  controller.latitudeTarget = { value: "NaN" }
  controller.longitudeTarget = { value: "126.978" }
  controller.weatherTarget = { value: "clear" }

  controller.sendLocation()

  assert.equal(controller.statusTarget.textContent, "invalid location values")
  assert.equal(controller.statusTarget.dataset.state, "error")
})

test("native_bridge playAudio dispatches to bridge and marks ok", () => {
  let spoken = null
  global.window = {
    SoleTalkBridge: {
      playAudio(text) {
        spoken = text
      }
    }
  }

  const controller = new NativeBridgeController()
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "", dataset: {} }
  controller.ttsTarget = { value: "hello world" }

  controller.playAudio()

  assert.equal(spoken, "hello world")
  assert.equal(controller.statusTarget.textContent, "play_audio requested")
  assert.equal(controller.statusTarget.dataset.state, "ok")
})

test("P87-T3 native_bridge connect auto-starts recording when requested and bridge is available", () => {
  let started = 0
  global.window = {
    SoleTalkBridge: {
      startRecording() {
        started += 1
      }
    }
  }

  const controller = new NativeBridgeController()
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "", dataset: {} }
  controller.autoStartValue = true

  controller.connect()

  assert.equal(started, 1)
  assert.equal(controller.statusTarget.textContent, "auto start recording sent")
  assert.equal(controller.statusTarget.dataset.state, "ok")
})
