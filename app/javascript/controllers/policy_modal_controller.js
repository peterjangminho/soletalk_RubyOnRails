import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "overlay"]

  open(event) {
    event.preventDefault()
    this._previousFocus = document.activeElement
    if (this.hasDialogTarget) this.dialogTarget.hidden = false
    if (this.hasOverlayTarget) this.overlayTarget.hidden = false
    if (this.hasDialogTarget) {
      const focusable = this.dialogTarget.querySelector("button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])")
      if (focusable) focusable.focus()
    }
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    if (this.hasOverlayTarget) this.overlayTarget.hidden = true
    if (this._previousFocus) this._previousFocus.focus()
  }
}
