import test from "node:test"
import assert from "node:assert/strict"
import ParticleOrbController, {
  PARTICLE_COUNT,
  extractFirstNumber,
  motionProfile,
  nextPhase,
  phaseVisualStyle,
  phaseDuration,
  phaseMultiplier,
  readPhaseBadge,
  voicePhaseToMotionPhase
} from "../../../app/javascript/controllers/particle_orb_controller.js"

test("particle_orb nextPhase cycles gather -> spread -> orb -> gather", () => {
  assert.equal(nextPhase("gather"), "spread")
  assert.equal(nextPhase("spread"), "orb")
  assert.equal(nextPhase("orb"), "gather")
})

test("particle_orb phaseDuration returns positive durations", () => {
  assert.ok(phaseDuration("gather") > 0)
  assert.ok(phaseDuration("spread") > 0)
  assert.ok(phaseDuration("orb") > 0)
})

test("particle_orb motionProfile disables animation on reduced motion", () => {
  const profile = motionProfile({
    reducedMotion: true,
    saveData: false,
    hardwareConcurrency: 8
  })

  assert.equal(profile.animate, false)
  assert.ok(profile.particleCount < PARTICLE_COUNT)
})

test("particle_orb motionProfile lowers particle count on data saver", () => {
  const profile = motionProfile({
    reducedMotion: false,
    saveData: true,
    hardwareConcurrency: 8,
    density: 1
  })

  assert.equal(profile.animate, true)
  assert.ok(profile.particleCount < PARTICLE_COUNT)
  assert.ok(profile.frameInterval > 30)
})

test("particle_orb motionProfile uses thousand-plus particles on capable devices", () => {
  const profile = motionProfile({
    reducedMotion: false,
    saveData: false,
    hardwareConcurrency: 8,
    density: 1
  })

  assert.ok(profile.particleCount >= 1000)
})

test("particle_orb motionProfile scales particle count by density", () => {
  const lowDensity = motionProfile({
    reducedMotion: false,
    saveData: false,
    hardwareConcurrency: 8,
    density: 0.6
  })
  const highDensity = motionProfile({
    reducedMotion: false,
    saveData: false,
    hardwareConcurrency: 8,
    density: 1.8
  })

  assert.ok(highDensity.particleCount > lowDensity.particleCount)
})

test("particle_orb voicePhaseToMotionPhase maps opener and calm safely", () => {
  assert.equal(voicePhaseToMotionPhase("opener"), "gather")
  assert.equal(voicePhaseToMotionPhase("calm"), "orb")
  assert.equal(voicePhaseToMotionPhase("unknown"), "gather")
})

test("particle_orb phaseMultiplier increases free_speech intensity and dampens calm", () => {
  const active = phaseMultiplier("free_speech", 0.8)
  const calm = phaseMultiplier("calm", 0.2)

  assert.ok(active > 1)
  assert.ok(calm < 1)
})

test("particle_orb readPhaseBadge parses phase and emotion text", () => {
  const badge = {
    dataset: { phase: "calm" },
    querySelectorAll() {
      return [
        { textContent: "calm" },
        { textContent: "0.42" }
      ]
    }
  }

  const state = readPhaseBadge(badge)
  assert.equal(state.voicePhase, "calm")
  assert.equal(state.emotionLevel, 0.42)
})

test("particle_orb extractFirstNumber parses localized labels safely", () => {
  assert.equal(extractFirstNumber("Emotion Level: 0.42"), 0.42)
  assert.equal(extractFirstNumber("감정 강도 0.67"), 0.67)
  assert.equal(extractFirstNumber("no numeric value"), null)
})

test("particle_orb readPhaseBadge parses labeled emotion text", () => {
  const badge = {
    dataset: { phase: "free_speech" },
    querySelectorAll() {
      return [
        { textContent: "free_speech" },
        { textContent: "Emotion Level: 0.58" }
      ]
    }
  }

  const state = readPhaseBadge(badge)
  assert.equal(state.voicePhase, "free_speech")
  assert.equal(state.emotionLevel, 0.58)
})

test("particle_orb phaseVisualStyle returns visible palette by phase", () => {
  const gather = phaseVisualStyle("gather")
  const spread = phaseVisualStyle("spread")
  const orb = phaseVisualStyle("orb")

  assert.ok(gather.coreAlpha >= 0.85)
  assert.ok(spread.haloAlpha >= 0.2)
  assert.ok(orb.bgAlpha >= gather.bgAlpha)
  assert.notEqual(gather.coreColor, spread.coreColor)
})

test("particle_orb syncFromBadge updates motion phase and particle count", () => {
  const controller = new ParticleOrbController()
  controller.profile = { particleCount: PARTICLE_COUNT, animate: true, frameInterval: 33 }
  controller.phase = "gather"
  controller.particles = Array.from({ length: PARTICLE_COUNT }).map(() => ({}))
  controller.buildParticles = (count) => Array.from({ length: count }).map(() => ({}))

  controller.syncFromBadge({
    dataset: { phase: "calm" },
    querySelectorAll() {
      return [
        { textContent: "calm" },
        { textContent: "0.1" }
      ]
    }
  })

  assert.equal(controller.phase, "orb")
  assert.ok(controller.particles.length < PARTICLE_COUNT)
})

test("particle_orb connect initializes particle collection", () => {
  const context = {
    setTransform() {},
    clearRect() {},
    fillRect() {},
    beginPath() {},
    arc() {},
    fill() {}
  }
  const canvas = {
    width: 0,
    height: 0,
    getContext() {
      return context
    },
    getBoundingClientRect() {
      return { width: 320, height: 220 }
    }
  }

  global.window = {
    devicePixelRatio: 1,
    addEventListener() {},
    removeEventListener() {}
  }
  global.requestAnimationFrame = () => 1
  global.cancelAnimationFrame = () => {}

  const controller = new ParticleOrbController()
  controller.hasCanvasTarget = true
  controller.canvasTarget = canvas

  controller.connect()

  assert.equal(controller.phase, "gather")
  assert.equal(controller.particles.length, controller.profile.particleCount)
  assert.equal(canvas.width, 320)
  assert.equal(canvas.height, 220)

  controller.disconnect()
})
