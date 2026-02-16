// 3D Particle Sphere Engine
// Golden Spiral distribution + FOV-based perspective projection
// Reference: Project_B ParticleSphere.tsx

export const SPHERE_CONFIG = Object.freeze({
  FOV: 250,
  PARTICLE_COUNT: 1000,
  RADIUS_RATIO: 0.35,
  BASE_ROTATION_SPEED: 0.002,
  PARTICLE_COLOR: "137, 207, 240",
  SPARKLE_COLOR: "180, 255, 255"
})

const GOLDEN_ANGLE = Math.PI * (3 - Math.sqrt(5))

export function buildGoldenSpiralParticles(count, radius) {
  const particles = []
  for (let i = 0; i < count; i++) {
    const y = 1 - (i / (count - 1)) * 2
    const r = Math.sqrt(1 - y * y)
    const theta = GOLDEN_ANGLE * i
    const x = Math.cos(theta) * r
    const z = Math.sin(theta) * r

    particles.push({
      x: x * radius,
      y: y * radius,
      z: z * radius,
      ox: x * radius,
      oy: y * radius,
      oz: z * radius
    })
  }
  return particles
}

export function projectParticle3D(particle, fov, centerX, centerY, rotationY) {
  const sinY = Math.sin(rotationY)
  const cosY = Math.cos(rotationY)

  const rx = particle.x * cosY - particle.z * sinY
  const rz = particle.x * sinY + particle.z * cosY

  const scale = fov / (fov + rz)

  return {
    px: rx * scale + centerX,
    py: particle.y * scale + centerY,
    scale
  }
}

export function sortByDepth(particles) {
  return [...particles].sort((a, b) => a.z - b.z)
}

export function rotationSpeed(status, time) {
  if (status === "thinking" || status === "analyzing") {
    return 0.001 + Math.sin(time * 0.001) * 0.003
  }
  if (status === "speaking") {
    return 0.003 + Math.cos(time * 0.002) * 0.002
  }
  return SPHERE_CONFIG.BASE_ROTATION_SPEED
}

export function particleAlpha(scale, status, volume) {
  let alpha = scale * 0.8
  if (status === "listening" && volume > 0) {
    alpha *= Math.min(1, volume * 5)
  }
  return Math.max(0, Math.min(1, alpha))
}

const DISPLACEMENT_FACTOR = 20

export function displaceParticle(particle, volume, time) {
  if (volume <= 0) {
    return { x: particle.ox, y: particle.oy, z: particle.oz }
  }

  const dist = Math.sqrt(particle.ox ** 2 + particle.oy ** 2 + particle.oz ** 2)
  if (dist === 0) {
    return { x: particle.ox, y: particle.oy, z: particle.oz }
  }

  const nx = particle.ox / dist
  const ny = particle.oy / dist
  const nz = particle.oz / dist

  const phi = Math.atan2(particle.oz, particle.ox)
  const wave = 0.5 + Math.sin(phi * 3 + time * 0.005) * 0.5
  const displacement = volume * DISPLACEMENT_FACTOR * wave

  return {
    x: particle.ox + nx * displacement,
    y: particle.oy + ny * displacement,
    z: particle.oz + nz * displacement
  }
}
