import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "preferences", "status" ]

  normalizeJson() {
    if (!this.hasPreferencesTarget) return

    const raw = this.preferencesTarget.value.trim()
    if (raw.length === 0) {
      this.updateStatus("")
      return
    }

    try {
      this.preferencesTarget.value = JSON.stringify(JSON.parse(raw))
      this.updateStatus("Preferences JSON normalized.")
    } catch (_error) {
      // Keep user input as-is when it's not valid JSON.
      this.updateStatus("Invalid JSON format. Please check brackets and quotes.")
    }
  }

  updateStatus(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
  }
}
