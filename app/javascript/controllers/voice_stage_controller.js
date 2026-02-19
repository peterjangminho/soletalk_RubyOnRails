import { Controller } from "@hotwired/stimulus"

const MIC_TO_SPHERE = Object.freeze({
  idle: "idle",
  active: "listening",
  muted: "idle",
  disabled: "idle"
})

export function micToSphereStatus(micState) {
  return MIC_TO_SPHERE[micState] || "idle"
}

export default class extends Controller {
  static targets = ["sphere", "bridgeFallback"]

  micStateChanged({ detail: { state } }) {
    if (!this.hasSphereTarget) return
    this.sphereTarget.dataset.particleSphereStatusValue = micToSphereStatus(state)
  }
}
