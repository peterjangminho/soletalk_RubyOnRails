import test from "node:test"
import assert from "node:assert/strict"

import PolicyModalController from "../../../app/javascript/controllers/policy_modal_controller.js"

test("controller declares dialog and overlay targets", () => {
  assert.ok(PolicyModalController.targets)
  assert.ok(PolicyModalController.targets.includes("dialog"))
  assert.ok(PolicyModalController.targets.includes("overlay"))
})
