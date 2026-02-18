import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "overlay"]

  open(event) {
    event.preventDefault()
    if (this.hasDialogTarget) this.dialogTarget.hidden = false
    if (this.hasOverlayTarget) this.overlayTarget.hidden = false
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    if (this.hasOverlayTarget) this.overlayTarget.hidden = true
  }
}
