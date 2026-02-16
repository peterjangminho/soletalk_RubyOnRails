import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["agree", "submit"]

  connect() {
    this.applyGateState()
  }

  toggleAgree() {
    this.applyGateState()
  }

  applyGateState() {
    const checked = this.agreeTarget.checked
    this.submitTarget.disabled = !checked
    this.submitTarget.classList.toggle("btn-link-disabled", !checked)
  }
}
