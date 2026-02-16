import test from "node:test"
import assert from "node:assert/strict"

import OpeningAnimationController, {
  OPENING_CONFIG,
  explosionPhase,
  reformPhase,
  fadeOverlayAlpha
} from "../../../app/javascript/controllers/opening_animation_controller.js"

// --- Config ---
test("opening config exports duration and phase boundaries", () => {
  assert.equal(OPENING_CONFIG.DURATION, 5000)
  assert.ok(OPENING_CONFIG.EXPLOSION_END > 0)
  assert.ok(OPENING_CONFIG.REFORM_START <= OPENING_CONFIG.EXPLOSION_END)
  assert.ok(OPENING_CONFIG.ROTATION_START > OPENING_CONFIG.REFORM_START)
  assert.ok(OPENING_CONFIG.FADE_DURATION > 0)
})

// --- Explosion Phase ---
test("explosionPhase assigns velocity to particles", () => {
  const particles = [
    { x: 50, y: 0, z: 0, vx: 0, vy: 0, vz: 0, targetX: 50, targetY: 0, targetZ: 0 }
  ]

  explosionPhase(particles)

  assert.ok(particles[0].vx !== 0 || particles[0].vy !== 0 || particles[0].vz !== 0)
})

// --- Reform Phase ---
test("reformPhase moves particles toward targets", () => {
  const particles = [
    { x: 100, y: 100, z: 100, vx: 0, vy: 0, vz: 0, targetX: 0, targetY: 0, targetZ: 0 }
  ]

  reformPhase(particles, 0.5)

  // Particle should be closer to target after reform
  assert.ok(Math.abs(particles[0].x) < 100)
  assert.ok(Math.abs(particles[0].y) < 100)
})

test("reformPhase at progress=0 leaves particles in place", () => {
  const particles = [
    { x: 100, y: 100, z: 100, vx: 0, vy: 0, vz: 0, targetX: 0, targetY: 0, targetZ: 0 }
  ]

  reformPhase(particles, 0)

  // Minimal movement at progress 0
  assert.ok(Math.abs(particles[0].x - 100) < 1)
})

// --- Fade Overlay ---
test("fadeOverlayAlpha returns 0 before fade starts", () => {
  const alpha = fadeOverlayAlpha(3000, 5000, 500)
  assert.equal(alpha, 0)
})

test("fadeOverlayAlpha returns positive during fade", () => {
  const alpha = fadeOverlayAlpha(4800, 5000, 500)
  assert.ok(alpha > 0)
})

test("fadeOverlayAlpha returns 1 at completion", () => {
  const alpha = fadeOverlayAlpha(5000, 5000, 500)
  assert.ok(alpha >= 0.99)
})

// --- Controller ---
test("opening animation controller connect handles missing canvas", () => {
  const controller = new OpeningAnimationController()
  controller.hasCanvasTarget = false
  controller.element = {}

  // Should not throw
  controller.connect()
  assert.ok(true)
})
