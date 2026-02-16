import test from "node:test"
import assert from "node:assert/strict"

import MicButtonController, {
  MIC_BUTTON_CONFIG,
  stateStyle,
  ariaLabelForState
} from "../../../app/javascript/controllers/mic_button_controller.js"

// --- Config ---
test("mic button config exports state list and long-press duration", () => {
  assert.ok(Array.isArray(MIC_BUTTON_CONFIG.STATES))
  assert.ok(MIC_BUTTON_CONFIG.STATES.includes("idle"))
  assert.ok(MIC_BUTTON_CONFIG.STATES.includes("active"))
  assert.ok(MIC_BUTTON_CONFIG.STATES.includes("muted"))
  assert.ok(MIC_BUTTON_CONFIG.STATES.includes("disabled"))
  assert.equal(MIC_BUTTON_CONFIG.LONG_PRESS_MS, 1000)
})

// --- State Style ---
test("stateStyle returns distinct styles for each state", () => {
  const idle = stateStyle("idle")
  const active = stateStyle("active")
  const muted = stateStyle("muted")
  const disabled = stateStyle("disabled")

  assert.ok(idle.cssClass)
  assert.ok(active.cssClass)
  assert.ok(muted.cssClass)
  assert.ok(disabled.cssClass)
  assert.notEqual(idle.cssClass, active.cssClass)
  assert.notEqual(active.cssClass, muted.cssClass)
})

test("stateStyle returns icon name for each state", () => {
  assert.equal(stateStyle("idle").icon, "mic")
  assert.equal(stateStyle("active").icon, "mic")
  assert.equal(stateStyle("muted").icon, "mic-off")
  assert.equal(stateStyle("disabled").icon, "mic")
})

// --- ARIA Labels ---
test("ariaLabelForState returns descriptive label per state", () => {
  assert.equal(ariaLabelForState("idle"), "Start Conversation")
  assert.equal(ariaLabelForState("active"), "Pause Conversation")
  assert.equal(ariaLabelForState("muted"), "Resume Conversation")
  assert.equal(ariaLabelForState("disabled"), "Processing...")
})

test("ariaLabelForState defaults to idle for unknown state", () => {
  assert.equal(ariaLabelForState("unknown"), "Start Conversation")
})

// --- Controller ---
test("mic button controller has correct static values", () => {
  const controller = new MicButtonController()
  assert.ok(MicButtonController.values)
  assert.ok("state" in MicButtonController.values)
})

// --- Long-Press / Tap ---
test("pressStart sets timer and pressEnd before timeout dispatches tap", () => {
  const controller = new MicButtonController()
  controller.element = { classList: { add() {}, remove() {} }, setAttribute() {} }
  controller.stateValue = "idle"
  controller.hasIconTarget = false
  controller.dispatch = () => {}
  controller.connect()

  let dispatched = null
  controller.dispatch = (name) => { dispatched = name }

  const fakeEvent = { preventDefault() {} }
  controller.pressStart(fakeEvent)
  assert.ok(controller.pressTimer !== null, "timer should be set")

  controller.pressEnd(fakeEvent)
  assert.equal(dispatched, "tap", "short press should dispatch tap")
  assert.equal(controller.pressTimer, null, "timer should be cleared")
})

test("pressStart on disabled state is a no-op", () => {
  const controller = new MicButtonController()
  controller.element = { classList: { add() {}, remove() {} }, setAttribute() {} }
  controller.stateValue = "disabled"
  controller.hasIconTarget = false
  controller.dispatch = () => {}
  controller.connect()

  const fakeEvent = { preventDefault() {} }
  controller.pressStart(fakeEvent)
  assert.equal(controller.pressTimer, null, "no timer for disabled state")
})

test("cancelPress clears timer", () => {
  const controller = new MicButtonController()
  controller.element = { classList: { add() {}, remove() {} }, setAttribute() {} }
  controller.stateValue = "idle"
  controller.hasIconTarget = false
  controller.dispatch = () => {}
  controller.connect()

  const fakeEvent = { preventDefault() {} }
  controller.pressStart(fakeEvent)
  assert.ok(controller.pressTimer !== null)

  controller.cancelPress()
  assert.equal(controller.pressTimer, null, "timer cleared after cancel")
  assert.equal(controller.isLongPress, false)
})
