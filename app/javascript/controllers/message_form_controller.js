import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content" ]

  clearAfterSubmit(event) {
    if (!event.detail.success) return
    if (!this.hasContentTarget) return

    this.contentTarget.value = ""
  }
}
