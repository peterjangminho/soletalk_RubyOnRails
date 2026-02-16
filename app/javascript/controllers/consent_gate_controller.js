import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["agree", "submit", "status"]

  connect() {
    this.policyReviewed = false
    this.applyGateState()
  }

  markPolicyReviewed() {
    this.policyReviewed = true
    this.applyGateState()
    this.updateStatus("Policy reviewed. You can now agree and continue.")
  }

  toggleAgree() {
    this.applyGateState()
  }

  applyGateState() {
    const allowAgreement = this.policyReviewed
    this.agreeTarget.disabled = !allowAgreement
    this.submitTarget.disabled = !allowAgreement || !this.agreeTarget.checked
    this.submitTarget.classList.toggle("btn-link-disabled", this.submitTarget.disabled)
  }

  updateStatus(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
  }
}
