import { Controller } from "@hotwired/stimulus"
import {
  SPHERE_CONFIG,
  buildGoldenSpiralParticles,
  projectParticle3D,
  sortByDepth,
  rotationSpeed,
  particleAlpha
} from "lib/particle_sphere_engine"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    status: { type: String, default: "idle" },
    volume: { type: Number, default: 0 }
  }

  connect() {
    if (!this.hasCanvasTarget) return

    this.canvasContext = this.canvasTarget.getContext("2d")
    if (!this.canvasContext) return

    this.rotationY = 0
    this.lastFrameAt = 0

    this.resize()

    const radius = Math.min(this.width, this.height) * SPHERE_CONFIG.RADIUS_RATIO
    this.sphereRadius = radius
    this.particles = buildGoldenSpiralParticles(SPHERE_CONFIG.PARTICLE_COUNT, radius)

    this.resizeHandler = this.resize.bind(this)
    if (typeof window !== "undefined") {
      window.addEventListener("resize", this.resizeHandler)
    }

    if (this.prefersReducedMotion()) {
      this.draw(0)
    } else {
      this.frameRequest = requestAnimationFrame(this.render.bind(this))
    }
  }

  disconnect() {
    if (this.frameRequest) cancelAnimationFrame(this.frameRequest)
    if (this.resizeHandler && typeof window !== "undefined") {
      window.removeEventListener("resize", this.resizeHandler)
    }
  }

  resize() {
    const dpr = (typeof window !== "undefined" && window.devicePixelRatio) || 1
    const bounds = this.canvasTarget.getBoundingClientRect()
    this.width = Math.max(bounds.width, 1)
    this.height = Math.max(bounds.height, 1)
    this.canvasTarget.width = Math.round(this.width * dpr)
    this.canvasTarget.height = Math.round(this.height * dpr)
    if (this.canvasContext.setTransform) {
      this.canvasContext.setTransform(dpr, 0, 0, dpr, 0, 0)
    } else if (this.canvasContext.scale) {
      this.canvasContext.scale(dpr, dpr)
    }
  }

  render(timestamp) {
    if (!this.canvasContext) return

    this.renderFrame(timestamp)
    this.frameRequest = requestAnimationFrame(this.render.bind(this))
  }

  renderFrame(timestamp) {
    const status = this.hasStatusValue ? this.statusValue : "idle"
    const volume = this.hasVolumeValue ? this.volumeValue : 0
    const speed = rotationSpeed(status, timestamp)

    this.rotationY += speed
    this.draw(timestamp, status, volume)
  }

  draw(timestamp, status = "idle", volume = 0) {
    const ctx = this.canvasContext
    const centerX = this.width / 2
    const centerY = this.height / 2
    const fov = SPHERE_CONFIG.FOV

    ctx.clearRect(0, 0, this.width, this.height)

    const sorted = sortByDepth(this.particles)

    for (const particle of sorted) {
      const projected = projectParticle3D(particle, fov, centerX, centerY, this.rotationY)

      if (projected.scale <= 0) continue

      const alpha = particleAlpha(projected.scale, status, volume)
      const radius = projected.scale * 1.5

      ctx.fillStyle = `rgba(${SPHERE_CONFIG.PARTICLE_COLOR}, ${alpha})`
      ctx.beginPath()
      ctx.arc(projected.px, projected.py, radius, 0, Math.PI * 2)
      ctx.fill()
    }
  }

  prefersReducedMotion() {
    if (typeof window === "undefined" || !window.matchMedia) return false
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
