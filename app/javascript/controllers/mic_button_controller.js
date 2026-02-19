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

const STATUS_LABELS = Object.freeze({
  idle: "",
  active: "Listening...",
  muted: "Paused",
  disabled: "Processing..."
})

export function stateStyle(state) {
  return STATE_STYLES[state] || STATE_STYLES.idle
}

export function ariaLabelForState(state) {
  return ARIA_LABELS[state] || ARIA_LABELS.idle
}

export function statusLabelForState(state) {
  return STATUS_LABELS[state] || STATUS_LABELS.idle
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

    const statusEl = this.element.parentElement?.parentElement?.querySelector(".mic-status-text")
    if (statusEl) {
      statusEl.textContent = statusLabelForState(this.stateValue)
      statusEl.className = "mic-status-text"
      if (this.stateValue === "active") statusEl.classList.add("status-active")
      if (this.stateValue === "muted") statusEl.classList.add("status-muted")
    }
  }

  toggle(event) {
    if (this.stateValue === "disabled") return

    if (this.stateValue === "idle") {
      this.stateValue = "active"
      event.preventDefault()
    } else if (this.stateValue === "active") {
      this.stateValue = "idle"
      // Allow default action (form submit) when stopping
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
