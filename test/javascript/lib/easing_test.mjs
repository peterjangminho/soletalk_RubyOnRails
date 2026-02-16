import test from "node:test"
import assert from "node:assert/strict"

import { easeInOutCubic, easeInCubic, lerp } from "../../../app/javascript/lib/easing.js"

test("easeInOutCubic returns 0 at t=0", () => {
  assert.equal(easeInOutCubic(0), 0)
})

test("easeInOutCubic returns 1 at t=1", () => {
  assert.equal(easeInOutCubic(1), 1)
})

test("easeInOutCubic returns 0.5 at t=0.5", () => {
  assert.equal(easeInOutCubic(0.5), 0.5)
})

test("easeInOutCubic starts slow (first half < linear)", () => {
  assert.ok(easeInOutCubic(0.25) < 0.25)
})

test("easeInOutCubic ends slow (second half > linear)", () => {
  assert.ok(easeInOutCubic(0.75) > 0.75)
})

test("easeInCubic returns 0 at t=0", () => {
  assert.equal(easeInCubic(0), 0)
})

test("easeInCubic returns 1 at t=1", () => {
  assert.equal(easeInCubic(1), 1)
})

test("easeInCubic is slower than linear at midpoint", () => {
  assert.ok(easeInCubic(0.5) < 0.5)
})

test("lerp interpolates between two values", () => {
  assert.equal(lerp(0, 100, 0.5), 50)
  assert.equal(lerp(0, 100, 0), 0)
  assert.equal(lerp(0, 100, 1), 100)
})
