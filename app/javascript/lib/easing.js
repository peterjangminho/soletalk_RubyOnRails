// Easing functions for animations
// Reference: Project_B OpeningAnimation.tsx

export function easeInOutCubic(t) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
}

export function easeInCubic(t) {
  return t * t * t
}

export function lerp(a, b, t) {
  return a + (b - a) * t
}
