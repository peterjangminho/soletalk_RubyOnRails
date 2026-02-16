import test from "node:test"
import assert from "node:assert/strict"

import ParticleSphereController from "../../../app/javascript/controllers/particle_sphere_controller.js"
import { SPHERE_CONFIG } from "../../../app/javascript/lib/particle_sphere_engine.js"

function mockCanvas(width = 320, height = 320) {
  const context = {
    clearRect() {},
    beginPath() {},
    arc() {},
    fill() {},
    fillRect() {},
    fillStyle: "",
    globalAlpha: 1,
    setTransform() {},
    scale() {}
  }
  return {
    width: 0,
    height: 0,
    getContext() { return context },
    getBoundingClientRect() { return { width, height } }
  }
}

function setupGlobals() {
  global.window = {
    devicePixelRatio: 1,
    addEventListener() {},
    removeEventListener() {},
    matchMedia() { return { matches: false } }
  }
  global.requestAnimationFrame = () => 1
  global.cancelAnimationFrame = () => {}
}

function teardownGlobals() {
  delete global.window
  delete global.requestAnimationFrame
  delete global.cancelAnimationFrame
}

test("particle_sphere connect creates golden spiral particles", () => {
  setupGlobals()
  const canvas = mockCanvas()
  const controller = new ParticleSphereController()
  controller.hasCanvasTarget = true
  controller.canvasTarget = canvas

  controller.connect()

  assert.equal(controller.particles.length, SPHERE_CONFIG.PARTICLE_COUNT)
  // Verify first particle has 3D coordinates
  const p = controller.particles[0]
  assert.ok("x" in p)
  assert.ok("y" in p)
  assert.ok("z" in p)
  assert.ok("ox" in p)

  controller.disconnect()
  teardownGlobals()
})

test("particle_sphere connect handles missing canvas target", () => {
  const controller = new ParticleSphereController()
  controller.hasCanvasTarget = false

  // Should not throw
  controller.connect()
  assert.ok(true)
})

test("particle_sphere particles lie on sphere surface", () => {
  setupGlobals()
  const canvas = mockCanvas(400, 400)
  const controller = new ParticleSphereController()
  controller.hasCanvasTarget = true
  controller.canvasTarget = canvas

  controller.connect()

  const expectedRadius = Math.min(400, 400) * SPHERE_CONFIG.RADIUS_RATIO
  for (const p of controller.particles.slice(0, 20)) {
    const dist = Math.sqrt(p.ox * p.ox + p.oy * p.oy + p.oz * p.oz)
    assert.ok(
      Math.abs(dist - expectedRadius) < 0.1,
      `particle distance ${dist} should be near ${expectedRadius}`
    )
  }

  controller.disconnect()
  teardownGlobals()
})

test("particle_sphere resize sets canvas dimensions with DPR", () => {
  setupGlobals()
  global.window.devicePixelRatio = 2
  const canvas = mockCanvas(300, 200)
  const controller = new ParticleSphereController()
  controller.hasCanvasTarget = true
  controller.canvasTarget = canvas
  controller.canvasContext = canvas.getContext("2d")

  controller.resize()

  assert.equal(canvas.width, 600) // 300 * 2
  assert.equal(canvas.height, 400) // 200 * 2
  assert.equal(controller.width, 300)
  assert.equal(controller.height, 200)

  teardownGlobals()
})

test("particle_sphere rotationY increments in render loop", () => {
  setupGlobals()
  const canvas = mockCanvas()
  const controller = new ParticleSphereController()
  controller.hasCanvasTarget = true
  controller.canvasTarget = canvas

  controller.connect()

  const initialRotation = controller.rotationY
  // Simulate one render frame at 33ms
  controller.renderFrame(33)

  assert.ok(controller.rotationY > initialRotation)

  controller.disconnect()
  teardownGlobals()
})

test("particle_sphere disconnect cleans up animation frame", () => {
  setupGlobals()
  let cancelCalled = false
  global.cancelAnimationFrame = () => { cancelCalled = true }

  const canvas = mockCanvas()
  const controller = new ParticleSphereController()
  controller.hasCanvasTarget = true
  controller.canvasTarget = canvas

  controller.connect()
  controller.disconnect()

  assert.ok(cancelCalled)
  teardownGlobals()
})
