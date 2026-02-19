import test from "node:test"
import assert from "node:assert/strict"

import VoiceStageController, { micToSphereStatus } from "../../../app/javascript/controllers/voice_stage_controller.js"

// --- State Mapping ---
test("micToSphereStatus maps mic idle to sphere idle", () => {
  assert.equal(micToSphereStatus("idle"), "idle")
})

test("micToSphereStatus maps mic active to sphere listening", () => {
  assert.equal(micToSphereStatus("active"), "listening")
})

test("micToSphereStatus maps mic muted to sphere idle", () => {
  assert.equal(micToSphereStatus("muted"), "idle")
})

test("micToSphereStatus maps mic disabled to sphere idle", () => {
  assert.equal(micToSphereStatus("disabled"), "idle")
})

test("micToSphereStatus defaults to idle for unknown state", () => {
  assert.equal(micToSphereStatus("bogus"), "idle")
})

// --- Controller targets ---
test("controller declares sphere and bridgeFallback targets", () => {
  assert.ok(VoiceStageController.targets)
  assert.ok(VoiceStageController.targets.includes("sphere"))
  assert.ok(VoiceStageController.targets.includes("bridgeFallback"))
})
