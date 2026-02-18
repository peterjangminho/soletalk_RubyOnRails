import test from "node:test"
import assert from "node:assert/strict"
import SettingsFormController from "../../../app/javascript/controllers/settings_form_controller.js"

test("settings_form normalizeJson serializes valid JSON", () => {
  const controller = new SettingsFormController()
  controller.hasPreferencesTarget = true
  controller.preferencesTarget = { value: '{ "focus" : "commute" }' }
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "" }

  controller.normalizeJson()

  assert.equal(controller.preferencesTarget.value, '{"focus":"commute"}')
  assert.equal(controller.statusTarget.textContent, "Preferences JSON normalized.")
})

test("settings_form normalizeJson preserves invalid input and reports error", () => {
  const controller = new SettingsFormController()
  controller.hasPreferencesTarget = true
  controller.preferencesTarget = { value: '{"focus":}' }
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "" }

  controller.normalizeJson()

  assert.equal(controller.preferencesTarget.value, '{"focus":}')
  assert.equal(controller.statusTarget.textContent, "Invalid JSON format. Please check brackets and quotes.")
})

test("settings_form normalizeJson clears status for blank input", () => {
  const controller = new SettingsFormController()
  controller.hasPreferencesTarget = true
  controller.preferencesTarget = { value: "   " }
  controller.hasStatusTarget = true
  controller.statusTarget = { textContent: "previous" }

  controller.normalizeJson()

  assert.equal(controller.statusTarget.textContent, "")
})
