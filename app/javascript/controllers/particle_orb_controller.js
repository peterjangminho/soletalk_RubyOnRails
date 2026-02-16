import { Controller } from "@hotwired/stimulus"

export const PARTICLE_COUNT = 1800
const LOW_POWER_PARTICLE_COUNT = 780
const REDUCED_MOTION_PARTICLE_COUNT = 220
const MIN_PARTICLE_COUNT = 120
const MAX_PARTICLE_COUNT = 3200
const MIN_DENSITY = 0.35
const MAX_DENSITY = 2.2
const DENSITY_TUNE_COOLDOWN_MS = 1800
const DENSITY_TUNE_WINDOW = 18
const PHASES = [ "gather", "spread", "orb" ]
const PHASE_DURATIONS = {
  gather: 2400,
  spread: 2100,
  orb: 3400
}

export function nextPhase(currentPhase) {
  const index = PHASES.indexOf(currentPhase)
  if (index === -1) return PHASES[0]

  return PHASES[(index + 1) % PHASES.length]
}

export function phaseDuration(phase) {
  return PHASE_DURATIONS[phase] || PHASE_DURATIONS.gather
}

export function shouldAdvancePhase(mode, phase) {
  if (mode === "hero" && phase === "orb") return false

  return true
}

export function voicePhaseToMotionPhase(voicePhase) {
  if (voicePhase === "calm") return "orb"
  if (voicePhase === "emotion_expansion" || voicePhase === "free_speech" || voicePhase === "re_stimulus") {
    return "spread"
  }

  return "gather"
}

export function phaseMultiplier(voicePhase, emotionLevel = 0) {
  const emotion = Math.max(0, Math.min(emotionLevel, 1))
  const phaseBase = {
    opener: 1.0,
    emotion_expansion: 1.12,
    free_speech: 1.2,
    calm: 0.82,
    re_stimulus: 1.1
  }[voicePhase] || 1.0

  return Math.max(0.6, Math.min(1.6, phaseBase + emotion * 0.25))
}

export function readPhaseBadge(phaseBadge) {
  if (!phaseBadge) return { voicePhase: "opener", emotionLevel: 0 }

  const voicePhase = phaseBadge.dataset?.phase || "opener"
  const nodes = Array.from(phaseBadge.querySelectorAll("span"))
  const emotionText = nodes[1]?.textContent?.trim() || "0"
  const parsedEmotion = extractFirstNumber(emotionText)

  return {
    voicePhase,
    emotionLevel: Number.isFinite(parsedEmotion) ? parsedEmotion : 0
  }
}

export function extractFirstNumber(text) {
  if (typeof text !== "string") return null
  const match = text.match(/-?\d+(?:\.\d+)?/)
  if (!match) return null

  const parsed = Number.parseFloat(match[0])
  return Number.isFinite(parsed) ? parsed : null
}

export function phaseVisualStyle(phase) {
  if (phase === "spread") {
    return {
      bgColor: "32, 48, 90",
      bgAlpha: 0.12,
      haloColor: "146, 123, 255",
      haloAlpha: 0.28,
      coreColor: "130, 181, 252",
      coreAlpha: 0.94
    }
  }

  if (phase === "orb") {
    return {
      bgColor: "28, 42, 84",
      bgAlpha: 0.16,
      haloColor: "186, 222, 255",
      haloAlpha: 0.24,
      coreColor: "245, 251, 255",
      coreAlpha: 0.97
    }
  }

  return {
    bgColor: "23, 37, 72",
    bgAlpha: 0.09,
    haloColor: "100, 181, 246",
    haloAlpha: 0.22,
    coreColor: "102, 195, 255",
    coreAlpha: 0.91
  }
}

export function motionProfile({ reducedMotion, saveData, hardwareConcurrency, density = 1 }) {
  const clampedDensity = clampDensity(density)

  if (reducedMotion) {
    return {
      animate: false,
      particleCount: clampParticleCount(REDUCED_MOTION_PARTICLE_COUNT * clampedDensity),
      frameInterval: 1000
    }
  }

  if (saveData || hardwareConcurrency <= 4) {
    return {
      animate: true,
      particleCount: clampParticleCount(LOW_POWER_PARTICLE_COUNT * clampedDensity),
      frameInterval: 1000 / 24
    }
  }

  const highCoreBonus = hardwareConcurrency >= 10 ? 320 : 0

  return {
    animate: true,
    particleCount: clampParticleCount((PARTICLE_COUNT + highCoreBonus) * clampedDensity),
    frameInterval: 1000 / 36
  }
}

function clampParticleCount(count) {
  return Math.max(MIN_PARTICLE_COUNT, Math.min(MAX_PARTICLE_COUNT, Math.round(count)))
}

function clampDensity(value) {
  return Math.max(MIN_DENSITY, Math.min(MAX_DENSITY, value))
}

export function adaptDensity({
  currentDensity,
  desiredDensity,
  measuredFps,
  targetFps,
  saveData,
  reducedMotion
}) {
  const current = clampDensity(currentDensity)
  const desired = clampDensity(desiredDensity)
  if (reducedMotion) return MIN_DENSITY

  if (saveData) {
    return Math.min(current, Math.min(desired, 0.72))
  }

  if (!Number.isFinite(measuredFps) || measuredFps <= 0 || !Number.isFinite(targetFps) || targetFps <= 0) {
    return current
  }

  const weakThreshold = targetFps * 0.72
  const cautionThreshold = targetFps * 0.84
  const recoverThreshold = targetFps * 0.97

  if (measuredFps < weakThreshold) {
    return clampDensity(current * 0.82)
  }

  if (measuredFps < cautionThreshold) {
    return clampDensity(current * 0.9)
  }

  if (measuredFps > recoverThreshold && current < desired) {
    return clampDensity(Math.min(desired, current * 1.06))
  }

  return current
}

export default class extends Controller {
  static targets = [ "canvas" ]
  static values = {
    phase: String,
    emotion: Number,
    density: Number,
    mode: String
  }

  connect() {
    if (!this.hasCanvasTarget) return

    this.canvasContext = this.canvasTarget.getContext("2d")
    if (!this.canvasContext) return

    this.profile = motionProfile({
      reducedMotion: this.prefersReducedMotion(),
      saveData: this.saveDataEnabled(),
      hardwareConcurrency: this.hardwareConcurrency(),
      density: this.currentDensityValue()
    })
    this.desiredDensity = this.currentDensityValue()
    this.dynamicDensity = this.desiredDensity
    this.frameDeltas = []
    const now = this.now()
    this.lastDensityTuneAt = now
    const sessionMotionPhase = this.hasPhaseValue ? voicePhaseToMotionPhase(this.phaseValue) : "gather"
    this.phase = this.currentMode() === "hero" ? "gather" : sessionMotionPhase
    this.phaseStartedAt = now
    this.lastFrameAt = 0
    const intensityMultiplier = phaseMultiplier(this.hasPhaseValue ? this.phaseValue : "opener", this.currentEmotionValue())
    this.sparkSprite = this.buildSparkSprite()
    this.particles = this.buildParticles(this.targetParticleCount(intensityMultiplier))
    this.resizeHandler = this.resize.bind(this)
    this.resize()
    this.setupPhaseObserver()

    window.addEventListener("resize", this.resizeHandler)
    if (this.profile.animate) {
      this.frameRequest = requestAnimationFrame(this.render.bind(this))
    } else {
      this.phase = "orb"
      const now = this.now()
      this.updateParticles(now)
      this.draw(now)
      this.markRender(now)
    }
  }

  disconnect() {
    if (this.frameRequest) cancelAnimationFrame(this.frameRequest)
    if (this.resizeHandler) window.removeEventListener("resize", this.resizeHandler)
    if (this.phaseObserver) this.phaseObserver.disconnect()
  }

  resize() {
    const ratio = window.devicePixelRatio || 1
    const bounds = this.canvasTarget.getBoundingClientRect()
    this.width = Math.max(bounds.width, 1)
    this.height = Math.max(bounds.height, 1)
    this.canvasTarget.width = Math.round(this.width * ratio)
    this.canvasTarget.height = Math.round(this.height * ratio)
    this.canvasContext.setTransform(ratio, 0, 0, ratio, 0, 0)
  }

  render(timestamp) {
    if (!this.canvasContext) return
    const frameDelta = timestamp - this.lastFrameAt
    if (frameDelta < this.profile.frameInterval) {
      this.frameRequest = requestAnimationFrame(this.render.bind(this))
      return
    }
    this.lastFrameAt = timestamp

    if (timestamp - this.phaseStartedAt >= phaseDuration(this.phase) && shouldAdvancePhase(this.currentMode(), this.phase)) {
      this.phase = nextPhase(this.phase)
      this.phaseStartedAt = timestamp
    }

    this.updateParticles(timestamp)
    this.draw(timestamp)
    this.markRender(timestamp)
    this.tuneDensityByFps(frameDelta, timestamp)
    this.frameRequest = requestAnimationFrame(this.render.bind(this))
  }

  buildParticles(count) {
    return Array.from({ length: count }).map(() => ({
      theta: Math.random() * Math.PI * 2,
      phi: Math.acos(2 * Math.random() - 1),
      distance: 16 + Math.random() * 140,
      spreadX: (Math.random() - 0.5) * 1.9,
      spreadY: (Math.random() - 0.5) * 1.5,
      orbitDrift: 0.72 + Math.random() * 0.9,
      twinkleOffset: Math.random() * Math.PI * 2,
      twinkleSpeed: 0.0014 + Math.random() * 0.0038,
      haloBoost: 0.75 + Math.random() * 0.9,
      x: 0,
      y: 0,
      radius: 0.35 + Math.random() * 1.5
    }))
  }

  updateParticles(timestamp) {
    const centerX = this.width / 2
    const centerY = this.height / 2
    const progress = Math.min((timestamp - this.phaseStartedAt) / phaseDuration(this.phase), 1)

    this.particles.forEach((particle, index) => {
      if (this.phase === "gather") {
        const gatherRadius = 12 + (index % 20) * 1.2 + particle.distance * 0.035
        const swirlTheta = particle.theta + timestamp * 0.00026 + progress * 5.4
        const easing = 1 - progress * 0.84
        particle.x = centerX + Math.cos(swirlTheta) * gatherRadius * easing
        particle.y = centerY + Math.sin(swirlTheta) * gatherRadius * easing * 0.82
        return
      }

      if (this.phase === "spread") {
        const spreadDistance = Math.min(this.width, this.height) * (0.2 + progress * 0.7)
        const drift = 5 + Math.sin(timestamp * 0.0012 + particle.twinkleOffset) * 7
        particle.x = centerX + particle.spreadX * spreadDistance + Math.cos(particle.theta) * drift
        particle.y = centerY + particle.spreadY * spreadDistance + Math.sin(particle.theta) * drift * 0.76
        return
      }

      const radius = Math.min(this.width, this.height) * 0.35
      const orbitSpeed = 0.00026 * particle.orbitDrift
      const orbitalTheta = particle.theta + timestamp * orbitSpeed
      const depth = Math.cos(particle.phi + timestamp * 0.00008) * radius
      const projectedRadius = radius * Math.sin(particle.phi)
      particle.x = centerX + Math.cos(orbitalTheta) * projectedRadius
      particle.y = centerY + Math.sin(orbitalTheta) * projectedRadius * 0.64 - depth * 0.1
    })
  }

  draw(timestamp = 0) {
    const visual = phaseVisualStyle(this.phase)

    this.canvasContext.clearRect(0, 0, this.width, this.height)
    this.canvasContext.fillStyle = `rgba(${visual.bgColor}, ${visual.bgAlpha})`
    this.canvasContext.fillRect(0, 0, this.width, this.height)

    const hasSparkSprite = this.sparkSprite && typeof this.canvasContext.drawImage === "function"
    if (hasSparkSprite) this.canvasContext.globalCompositeOperation = "lighter"

    this.particles.forEach((particle, index) => {
      const pulse = 0.62 + 0.38 * Math.sin(timestamp * particle.twinkleSpeed + particle.twinkleOffset + index * 0.003)
      const coreRadius = particle.radius * pulse

      if (hasSparkSprite) {
        const size = 2.2 + coreRadius * 9
        this.canvasContext.globalAlpha = Math.min(1, (visual.coreAlpha * 0.4 + pulse * 0.36) * particle.haloBoost)
        this.canvasContext.drawImage(
          this.sparkSprite,
          particle.x - size / 2,
          particle.y - size / 2,
          size,
          size
        )
        return
      }

      this.canvasContext.beginPath()
      this.canvasContext.arc(particle.x, particle.y, coreRadius * 2.4, 0, Math.PI * 2)
      this.canvasContext.fillStyle = `rgba(${visual.haloColor}, ${visual.haloAlpha})`
      this.canvasContext.fill()

      this.canvasContext.beginPath()
      this.canvasContext.arc(particle.x, particle.y, coreRadius, 0, Math.PI * 2)
      this.canvasContext.fillStyle = `rgba(${visual.coreColor}, ${visual.coreAlpha})`
      this.canvasContext.fill()
    })

    this.canvasContext.globalCompositeOperation = "source-over"
    this.canvasContext.globalAlpha = 1
  }

  now() {
    if (globalThis.performance && typeof globalThis.performance.now === "function") {
      return globalThis.performance.now()
    }

    return Date.now()
  }

  prefersReducedMotion() {
    if (!window.matchMedia) return false

    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  saveDataEnabled() {
    if (!globalThis.navigator || !globalThis.navigator.connection) return false

    return globalThis.navigator.connection.saveData === true
  }

  hardwareConcurrency() {
    if (!globalThis.navigator || !globalThis.navigator.hardwareConcurrency) return 8

    return globalThis.navigator.hardwareConcurrency
  }

  currentEmotionValue() {
    return this.hasEmotionValue ? this.emotionValue : 0
  }

  currentDensityValue() {
    if (!this.hasDensityValue) return 1

    return Number.isFinite(this.densityValue) ? this.densityValue : 1
  }

  currentMode() {
    if (!this.hasModeValue) return "loop"

    return this.modeValue === "hero" ? "hero" : "loop"
  }

  targetParticleCount(intensity = 1) {
    return clampParticleCount(this.profile.particleCount * intensity)
  }

  tuneDensityByFps(frameDelta, timestamp) {
    if (!this.profile.animate || frameDelta <= 0) return

    this.frameDeltas.push(frameDelta)
    if (this.frameDeltas.length > DENSITY_TUNE_WINDOW) this.frameDeltas.shift()
    if (timestamp - this.lastDensityTuneAt < DENSITY_TUNE_COOLDOWN_MS) return
    if (this.frameDeltas.length < 6) return

    const averageFrameDelta = this.frameDeltas.reduce((sum, delta) => sum + delta, 0) / this.frameDeltas.length
    const measuredFps = 1000 / averageFrameDelta
    const targetFps = 1000 / this.profile.frameInterval
    const nextDensity = adaptDensity({
      currentDensity: this.dynamicDensity,
      desiredDensity: this.desiredDensity,
      measuredFps,
      targetFps,
      saveData: this.saveDataEnabled(),
      reducedMotion: this.prefersReducedMotion()
    })
    this.lastDensityTuneAt = timestamp

    if (Math.abs(nextDensity - this.dynamicDensity) < 0.04) return

    this.dynamicDensity = nextDensity
    this.profile = motionProfile({
      reducedMotion: this.prefersReducedMotion(),
      saveData: this.saveDataEnabled(),
      hardwareConcurrency: this.hardwareConcurrency(),
      density: this.dynamicDensity
    })

    const intensity = this.currentIntensityFromState()
    const targetCount = this.targetParticleCount(intensity)
    if (this.particles.length !== targetCount) {
      this.particles = this.buildParticles(targetCount)
    }
  }

  currentIntensityFromState() {
    if (this.phaseBadgeElement) {
      const { voicePhase, emotionLevel } = readPhaseBadge(this.phaseBadgeElement)
      return phaseMultiplier(voicePhase, emotionLevel)
    }

    return phaseMultiplier(this.hasPhaseValue ? this.phaseValue : "opener", this.currentEmotionValue())
  }

  markRender(timestamp) {
    if (!this.element || !this.element.dataset) return

    this.element.dataset.orbLastRenderAt = String(Math.round(timestamp))
    this.element.dataset.orbParticleCount = String(this.particles.length)
    this.element.dataset.orbDensity = Number(this.dynamicDensity || this.desiredDensity || 1).toFixed(2)
  }

  buildSparkSprite() {
    if (typeof document === "undefined") return null

    const sprite = document.createElement("canvas")
    const size = 20
    sprite.width = size
    sprite.height = size
    const ctx = sprite.getContext("2d")
    if (!ctx) return null

    const center = size / 2
    const gradient = ctx.createRadialGradient(center, center, 0, center, center, center)
    gradient.addColorStop(0, "rgba(248, 252, 255, 0.95)")
    gradient.addColorStop(0.35, "rgba(137, 201, 255, 0.88)")
    gradient.addColorStop(0.7, "rgba(129, 170, 255, 0.35)")
    gradient.addColorStop(1, "rgba(120, 160, 255, 0)")

    ctx.fillStyle = gradient
    ctx.beginPath()
    ctx.arc(center, center, center, 0, Math.PI * 2)
    ctx.fill()

    return sprite
  }

  setupPhaseObserver() {
    if (!this.element || typeof MutationObserver === "undefined") return

    this.phaseBadgeElement = this.element.querySelector("#voice_chat_phase_badge")
    if (!this.phaseBadgeElement) return

    this.syncFromBadge(this.phaseBadgeElement)
    this.phaseObserver = new MutationObserver(() => this.syncFromBadge(this.phaseBadgeElement))
    this.phaseObserver.observe(this.phaseBadgeElement, {
      attributes: true,
      childList: true,
      subtree: true
    })
  }

  syncFromBadge(phaseBadge) {
    const { voicePhase, emotionLevel } = readPhaseBadge(phaseBadge)
    this.phase = voicePhaseToMotionPhase(voicePhase)

    const intensity = phaseMultiplier(voicePhase, emotionLevel)
    const targetCount = this.targetParticleCount(intensity)
    if (this.particles.length !== targetCount) {
      this.particles = this.buildParticles(targetCount)
    }
  }
}
