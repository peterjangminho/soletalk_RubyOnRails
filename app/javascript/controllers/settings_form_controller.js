import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "preferences" ]

  normalizeJson() {
    if (!this.hasPreferencesTarget) return

    const raw = this.preferencesTarget.value.trim()
    if (raw.length === 0) return

    try {
      this.preferencesTarget.value = JSON.stringify(JSON.parse(raw))
    } catch (_error) {
      // Keep user input as-is when it's not valid JSON.
    }
  }
}
