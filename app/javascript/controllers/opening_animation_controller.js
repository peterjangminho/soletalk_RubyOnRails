import { Controller } from "@hotwired/stimulus"
import {
  SPHERE_CONFIG,
  buildGoldenSpiralParticles,
  projectParticle3D,
  sortByDepth
} from "lib/particle_sphere_engine"
import { easeInOutCubic, easeInCubic } from "lib/easing"

export const OPENING_CONFIG = Object.freeze({
  DURATION: 5000,
  EXPLOSION_END: 0.4,
  REFORM_START: 0.4,
  ROTATION_START: 0.7,
  FADE_DURATION: 500,
  EXPLOSION_STRENGTH: 15,
  DAMPING: 0.98,
  REFORM_SPEED: 0.2,
  BG_COLOR: "33, 32, 58"
})

export function explosionPhase(particles) {
  for (const p of particles) {
    const strength = (Math.random() * 0.5 + 0.5) * OPENING_CONFIG.EXPLOSION_STRENGTH
    p.vx = (Math.random() - 0.5) * strength
    p.vy = (Math.random() - 0.5) * strength
    p.vz = (Math.random() - 0.5) * strength
  }
}

export function reformPhase(particles, progress) {
  const eased = easeInOutCubic(progress)
  const factor = eased * OPENING_CONFIG.REFORM_SPEED

  for (const p of particles) {
    p.x = p.x + (p.targetX - p.x) * factor
    p.y = p.y + (p.targetY - p.y) * factor
    p.z = p.z + (p.targetZ - p.z) * factor
  }
}

export function fadeOverlayAlpha(elapsed, duration, fadeDuration) {
  const fadeStart = duration - fadeDuration
  if (elapsed <= fadeStart) return 0

  const fadeProgress = (elapsed - fadeStart) / fadeDuration
  return Math.min(easeInCubic(fadeProgress), 1.0)
}

export default class extends Controller {
  static targets = ["canvas", "overlay", "skip"]

  connect() {
    if (!this.hasCanvasTarget) return

    this.canvasContext = this.canvasTarget.getContext("2d")
    if (!this.canvasContext) return

    this.completed = false
    this.startTime = 0
    this.rotationY = 0
    this.exploded = false

    const dpr = (typeof window !== "undefined" && window.devicePixelRatio) || 1
    const bounds = this.canvasTarget.getBoundingClientRect()
    this.width = bounds.width
    this.height = bounds.height
    this.canvasTarget.width = Math.round(this.width * dpr)
    this.canvasTarget.height = Math.round(this.height * dpr)
    if (this.canvasContext.scale) {
      this.canvasContext.scale(dpr, dpr)
    }

    const radius = Math.min(this.width, this.height) * SPHERE_CONFIG.RADIUS_RATIO
    this.sphereRadius = radius

    const base = buildGoldenSpiralParticles(SPHERE_CONFIG.PARTICLE_COUNT, radius)
    this.particles = base.map(p => ({
      x: 0, y: 0, z: 0,
      vx: 0, vy: 0, vz: 0,
      targetX: p.x, targetY: p.y, targetZ: p.z,
      color: `rgba(${SPHERE_CONFIG.PARTICLE_COLOR}, ${Math.random() * 0.5 + 0.5})`,
      size: Math.random() * 1.5 + 0.5
    }))

    this.completionTimer = setTimeout(() => this.finish(), OPENING_CONFIG.DURATION)
    this.frameRequest = requestAnimationFrame(this.render.bind(this))
  }

  disconnect() {
    if (this.frameRequest) cancelAnimationFrame(this.frameRequest)
    if (this.completionTimer) clearTimeout(this.completionTimer)
  }

  skip() {
    this.finish()
  }

  finish() {
    if (this.completed) return
    this.completed = true

    if (this.frameRequest) cancelAnimationFrame(this.frameRequest)
    if (this.completionTimer) clearTimeout(this.completionTimer)

    if (this.hasOverlayTarget) {
      this.overlayTarget.style.opacity = "0"
      this.overlayTarget.style.pointerEvents = "none"
      setTimeout(() => {
        if (this.hasOverlayTarget) this.overlayTarget.remove()
      }, 600)
    } else if (this.element) {
      this.element.style.opacity = "0"
      this.element.style.pointerEvents = "none"
    }
  }

  render(timestamp) {
    if (this.completed) return

    if (!this.startTime) this.startTime = timestamp
    const elapsed = timestamp - this.startTime
    const progress = Math.min(elapsed / OPENING_CONFIG.DURATION, 1.0)
    const ctx = this.canvasContext
    const centerX = this.width / 2
    const centerY = this.height / 2

    ctx.clearRect(0, 0, this.width, this.height)

    if (progress < OPENING_CONFIG.EXPLOSION_END) {
      if (progress > 0.1 && !this.exploded) {
        explosionPhase(this.particles)
        this.exploded = true
      }
      for (const p of this.particles) {
        p.x += p.vx
        p.y += p.vy
        p.z += p.vz
        p.vx *= OPENING_CONFIG.DAMPING
        p.vy *= OPENING_CONFIG.DAMPING
        p.vz *= OPENING_CONFIG.DAMPING
      }
    } else {
      const reformProgress = (progress - OPENING_CONFIG.REFORM_START) / (1 - OPENING_CONFIG.REFORM_START)
      reformPhase(this.particles, reformProgress)
    }

    if (progress > OPENING_CONFIG.ROTATION_START) {
      const rotProgress = (progress - OPENING_CONFIG.ROTATION_START) / (1 - OPENING_CONFIG.ROTATION_START)
      this.rotationY += 0.002 * easeInOutCubic(rotProgress)
    }

    const fov = SPHERE_CONFIG.FOV
    const sorted = [...this.particles].sort((a, b) => b.z - a.z)

    for (const p of sorted) {
      const projected = projectParticle3D(
        { x: p.x, y: p.y, z: p.z },
        fov, centerX, centerY, this.rotationY
      )

      if (projected.scale <= 0) continue

      const px = projected.px
      const py = projected.py
      const particleRadius = p.size * projected.scale

      if (px > 0 && px < this.width && py > 0 && py < this.height) {
        ctx.fillStyle = p.color
        ctx.beginPath()
        ctx.arc(px, py, particleRadius, 0, Math.PI * 2)
        ctx.fill()
      }
    }

    const alpha = fadeOverlayAlpha(elapsed, OPENING_CONFIG.DURATION, OPENING_CONFIG.FADE_DURATION)
    if (alpha > 0) {
      ctx.fillStyle = `rgba(${OPENING_CONFIG.BG_COLOR}, ${alpha})`
      ctx.fillRect(0, 0, this.width, this.height)
    }

    if (progress < 1.0) {
      this.frameRequest = requestAnimationFrame(this.render.bind(this))
    }
  }
}
