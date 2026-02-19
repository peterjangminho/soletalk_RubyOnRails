import test from "node:test"
import assert from "node:assert/strict"
import MessageFormController from "../../../app/javascript/controllers/message_form_controller.js"

test("message_form submitStart disables submit and applies sending label", () => {
  const controller = new MessageFormController()
  controller.hasSubmitTarget = true
  controller.submitTarget = {
    disabled: false,
    value: "Send",
    dataset: { sendingLabel: "Sending...", defaultLabel: "Send" }
  }

  controller.submitStart()

  assert.equal(controller.submitTarget.disabled, true)
  assert.equal(controller.submitTarget.value, "Sending...")
})

test("message_form clearAfterSubmit resets submit and clears content on success", () => {
  const controller = new MessageFormController()
  controller.hasSubmitTarget = true
  controller.submitTarget = {
    disabled: true,
    value: "Sending...",
    dataset: { sendingLabel: "Sending...", defaultLabel: "Send" }
  }
  controller.hasContentTarget = true
  controller.contentTarget = { value: "hello" }

  controller.clearAfterSubmit({ detail: { success: true } })

  assert.equal(controller.submitTarget.disabled, false)
  assert.equal(controller.submitTarget.value, "Send")
  assert.equal(controller.contentTarget.value, "")
})

test("message_form clearAfterSubmit keeps content when submit failed", () => {
  const controller = new MessageFormController()
  controller.hasSubmitTarget = true
  controller.submitTarget = {
    disabled: true,
    value: "Sending...",
    dataset: { sendingLabel: "Sending...", defaultLabel: "Send" }
  }
  controller.hasContentTarget = true
  controller.contentTarget = { value: "keep me" }

  controller.clearAfterSubmit({ detail: { success: false } })

  assert.equal(controller.submitTarget.disabled, false)
  assert.equal(controller.submitTarget.value, "Send")
  assert.equal(controller.contentTarget.value, "keep me")
})
