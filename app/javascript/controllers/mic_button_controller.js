import { Controller } from "@hotwired/stimulus"

export const MIC_BUTTON_CONFIG = Object.freeze({
  STATES: ["idle", "active", "muted", "disabled"],
  LONG_PRESS_MS: 1000,
  SIZE: 80
})

const STATE_STYLES = Object.freeze({
  idle:     { cssClass: "mic-btn-idle",     icon: "mic" },
  active:   { cssClass: "mic-btn-active",   icon: "mic" },
  muted:    { cssClass: "mic-btn-muted",    icon: "mic-off" },
  disabled: { cssClass: "mic-btn-disabled", icon: "mic" }
})

const ARIA_LABELS = Object.freeze({
  idle: "Start Conversation",
  active: "Pause Conversation",
  muted: "Resume Conversation",
  disabled: "Processing..."
})

export function stateStyle(state) {
  return STATE_STYLES[state] || STATE_STYLES.idle
}

export function ariaLabelForState(state) {
  return ARIA_LABELS[state] || ARIA_LABELS.idle
}

export default class extends Controller {
  static values = { state: { type: String, default: "idle" } }
  static targets = ["icon"]

  connect() {
    this.pressTimer = null
    this.isLongPress = false
    this.applyState()
  }

  disconnect() {
    this.cancelPress()
  }

  stateValueChanged() {
    this.applyState()
  }

  applyState() {
    const style = stateStyle(this.stateValue)

    for (const s of MIC_BUTTON_CONFIG.STATES) {
      this.element.classList.remove(`mic-btn-${s}`)
    }
    this.element.classList.add(style.cssClass)

    this.element.setAttribute("aria-label", ariaLabelForState(this.stateValue))

    if (this.stateValue === "active") {
      this.element.classList.add("mic-btn-pulse")
    } else {
      this.element.classList.remove("mic-btn-pulse")
    }

    if (this.hasIconTarget) {
      this.iconTarget.setAttribute("data-icon", style.icon)
    }
  }

  pressStart(event) {
    if (this.stateValue === "disabled") return
    event.preventDefault()

    this.isLongPress = false
    this.pressTimer = setTimeout(() => {
      this.isLongPress = true
      this.dispatch("longpress")
    }, MIC_BUTTON_CONFIG.LONG_PRESS_MS)
  }

  pressEnd(event) {
    if (this.stateValue === "disabled") return
    event.preventDefault()

    if (this.pressTimer) {
      clearTimeout(this.pressTimer)
      this.pressTimer = null
    }

    if (!this.isLongPress) {
      this.dispatch("tap")
    }
    this.isLongPress = false
  }

  cancelPress() {
    if (this.pressTimer) {
      clearTimeout(this.pressTimer)
      this.pressTimer = null
    }
    this.isLongPress = false
  }
}
