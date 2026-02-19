import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content", "submit" ]

  submitStart() {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = true
    this.submitTarget.value = this.submitTarget.dataset.sendingLabel || "Sending..."
  }

  clearAfterSubmit(event) {
    this.resetSubmit()
    if (!event.detail.success || !this.hasContentTarget) return

    this.contentTarget.value = ""
  }

  resetSubmit() {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = false
    this.submitTarget.value = this.submitTarget.dataset.defaultLabel || "Send"
  }
}
