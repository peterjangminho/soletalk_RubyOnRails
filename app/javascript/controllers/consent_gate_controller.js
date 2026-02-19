import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "gated"]

  connect() {
    this.toggle()
  }

  toggle() {
    const agreed = this.checkboxTarget.checked
    this.gatedTargets.forEach(el => {
      el.classList.toggle("btn-link-disabled", !agreed)
      if (el.tagName === "BUTTON" || el.tagName === "INPUT") {
        el.disabled = !agreed
      }
      el.setAttribute("aria-disabled", String(!agreed))
    })
  }
}
