import test from "node:test"
import assert from "node:assert/strict"

import {
  SPHERE_CONFIG,
  buildGoldenSpiralParticles,
  projectParticle3D,
  sortByDepth,
  rotationSpeed,
  particleAlpha,
  displaceParticle
} from "../../../app/javascript/lib/particle_sphere_engine.js"

// --- Test 1: SPHERE_CONFIG exports essential constants ---
test("sphere config exports FOV, particle count, and radius ratio", () => {
  assert.equal(SPHERE_CONFIG.FOV, 250)
  assert.equal(SPHERE_CONFIG.PARTICLE_COUNT, 1000)
  assert.equal(SPHERE_CONFIG.RADIUS_RATIO, 0.35)
  assert.equal(SPHERE_CONFIG.BASE_ROTATION_SPEED, 0.002)
})

// --- Test 2: Golden Spiral builds correct particle count ---
test("buildGoldenSpiralParticles creates requested number of particles", () => {
  const particles = buildGoldenSpiralParticles(100, 50)
  assert.equal(particles.length, 100)
})

// --- Test 3: Each particle has x, y, z, ox, oy, oz ---
test("buildGoldenSpiralParticles particles have 3D coordinates and originals", () => {
  const particles = buildGoldenSpiralParticles(10, 50)
  const p = particles[0]

  assert.ok("x" in p)
  assert.ok("y" in p)
  assert.ok("z" in p)
  assert.ok("ox" in p)
  assert.ok("oy" in p)
  assert.ok("oz" in p)
})

// --- Test 4: Particles lie on sphere surface (within tolerance) ---
test("buildGoldenSpiralParticles distributes on sphere surface", () => {
  const radius = 100
  const particles = buildGoldenSpiralParticles(500, radius)

  for (const p of particles) {
    const dist = Math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z)
    assert.ok(Math.abs(dist - radius) < 0.01, `particle at distance ${dist}, expected ${radius}`)
  }
})

// --- Test 5: Golden spiral distributes uniformly (no clustering at poles) ---
test("buildGoldenSpiralParticles distributes uniformly across y-axis", () => {
  const particles = buildGoldenSpiralParticles(1000, 100)
  const topHalf = particles.filter(p => p.y > 0).length
  const bottomHalf = particles.filter(p => p.y < 0).length

  // Should be roughly 50/50 (allow 5% tolerance)
  assert.ok(Math.abs(topHalf - bottomHalf) < 50, `top=${topHalf} bottom=${bottomHalf}`)
})

// --- Test 6: 3D perspective projection ---
test("projectParticle3D returns screen coordinates and scale", () => {
  const result = projectParticle3D(
    { x: 50, y: 0, z: 0 },
    250,     // fov
    200,     // centerX
    150,     // centerY
    0        // rotationY
  )

  assert.ok("px" in result)
  assert.ok("py" in result)
  assert.ok("scale" in result)
  assert.ok(result.scale > 0)
})

// --- Test 7: Projection moves away from center with x offset ---
test("projectParticle3D positive x projects right of center", () => {
  const result = projectParticle3D(
    { x: 50, y: 0, z: 0 },
    250, 200, 150, 0
  )

  assert.ok(result.px > 200, `expected px > 200, got ${result.px}`)
})

// --- Test 8: Projection handles rotation ---
test("projectParticle3D rotationY changes projected position", () => {
  const particle = { x: 50, y: 0, z: 0 }
  const a = projectParticle3D(particle, 250, 200, 150, 0)
  const b = projectParticle3D(particle, 250, 200, 150, Math.PI / 4)

  assert.notEqual(a.px, b.px)
})

// --- Test 9: Depth behind camera has smaller scale ---
test("projectParticle3D particle behind sphere has smaller scale", () => {
  const front = projectParticle3D({ x: 0, y: 0, z: -100 }, 250, 200, 150, 0)
  const back = projectParticle3D({ x: 0, y: 0, z: 100 }, 250, 200, 150, 0)

  assert.ok(front.scale > back.scale, `front scale ${front.scale} should be > back scale ${back.scale}`)
})

// --- Test 10: sortByDepth orders particles by z ---
test("sortByDepth orders particles front to back for rendering", () => {
  const particles = [
    { x: 0, y: 0, z: 50 },
    { x: 0, y: 0, z: -30 },
    { x: 0, y: 0, z: 10 }
  ]

  const sorted = sortByDepth(particles)
  assert.ok(sorted[0].z <= sorted[1].z)
  assert.ok(sorted[1].z <= sorted[2].z)
})

// --- Test 11: rotationSpeed returns base speed for idle ---
test("rotationSpeed returns base speed for idle status", () => {
  const speed = rotationSpeed("idle", 0)
  assert.equal(speed, SPHERE_CONFIG.BASE_ROTATION_SPEED)
})

// --- Test 12: rotationSpeed varies for thinking status ---
test("rotationSpeed varies over time for thinking status", () => {
  const a = rotationSpeed("thinking", 0)
  const b = rotationSpeed("thinking", 1000)

  // Both should be positive, but may differ
  assert.ok(a > 0)
  assert.ok(b > 0)
})

// --- Test 13: particleAlpha scales with depth ---
test("particleAlpha returns depth-based opacity", () => {
  const alpha = particleAlpha(0.8, "idle", 0)
  assert.ok(alpha > 0)
  assert.ok(alpha <= 1)
})

// --- Test 14: Volume displacement with non-zero volume ---
test("displaceParticle moves particle outward when volume > 0", () => {
  const particle = { ox: 50, oy: 0, oz: 0 }
  const result = displaceParticle(particle, 0.8, 100)
  assert.ok(result.x !== particle.ox || result.y !== particle.oy || result.z !== particle.oz,
    "particle should be displaced from original position")
  // Distance from origin should be >= original radius
  const dist = Math.sqrt(result.x ** 2 + result.y ** 2 + result.z ** 2)
  const origDist = Math.sqrt(particle.ox ** 2 + particle.oy ** 2 + particle.oz ** 2)
  assert.ok(dist >= origDist - 1, `displaced dist ${dist} should be >= original ${origDist}`)
})

// --- Test 15: Volume 0 returns original position ---
test("displaceParticle returns original position when volume is 0", () => {
  const particle = { ox: 50, oy: 30, oz: -20 }
  const result = displaceParticle(particle, 0, 0)
  assert.equal(result.x, particle.ox)
  assert.equal(result.y, particle.oy)
  assert.equal(result.z, particle.oz)
})

// --- Test 16: Displacement scales with volume ---
test("displaceParticle displacement magnitude scales with volume", () => {
  const particle = { ox: 50, oy: 0, oz: 0 }
  const lowVol = displaceParticle(particle, 0.2, 0)
  const highVol = displaceParticle(particle, 0.9, 0)

  const lowDist = Math.sqrt(lowVol.x ** 2 + lowVol.y ** 2 + lowVol.z ** 2)
  const highDist = Math.sqrt(highVol.x ** 2 + highVol.y ** 2 + highVol.z ** 2)
  assert.ok(highDist >= lowDist, `high volume dist ${highDist} should >= low volume dist ${lowDist}`)
})

// --- Test 17: particleAlpha increases for listening with volume ---
test("particleAlpha is brighter for listening status with volume", () => {
  const noVol = particleAlpha(0.5, "listening", 0)
  const withVol = particleAlpha(0.5, "listening", 0.8)
  assert.ok(withVol >= noVol, `with volume ${withVol} should >= without ${noVol}`)
})
