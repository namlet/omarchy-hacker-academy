const { test } = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

const KEY_A = 0x41

test("hold keys are recognised and letters are not", () => {
  for (const key of [Model.KEY_SHIFT, Model.KEY_CONTROL, Model.KEY_ALT, Model.KEY_SUPER_L]) {
    assert.equal(Model.isHoldKey(key), true)
  }
  assert.equal(Model.isHoldKey(KEY_A), false)
})

test("shift is held only between press and release", () => {
  let state = Model.initialKeyState()
  state = Model.pressKey(state, Model.KEY_SHIFT, false)
  assert.equal(state.shiftHeld, true)
  state = Model.releaseKey(state, Model.KEY_SHIFT)
  assert.equal(state.shiftHeld, false)
})

test("shift released as a different key code but the same physical key still lets go", () => {
  // Captured on a real keyboard: Left Shift (scan code 50) is pressed as Shift
  // but its release is reported as Caps Lock (0x01000024).
  const KEY_CAPSLOCK = 0x01000024
  let state = Model.pressKey(Model.initialKeyState(), Model.KEY_SHIFT, false, 50)
  assert.equal(state.shiftHeld, true)
  state = Model.releaseKey(state, KEY_CAPSLOCK, 50)
  assert.equal(state.shiftHeld, false)
})

test("each letter press is one tap; auto-repeat and hold keys are not", () => {
  let state = Model.initialKeyState()
  state = Model.pressKey(state, KEY_A, false)
  state = Model.pressKey(state, KEY_A, true)
  state = Model.pressKey(state, Model.KEY_CONTROL, false)
  assert.equal(state.taps, 1)
})

test("tapping a letter while holding shift keeps shift held", () => {
  let state = Model.pressKey(Model.initialKeyState(), Model.KEY_SHIFT, false)
  state = Model.pressKey(state, KEY_A, false)
  assert.equal(state.shiftHeld, true)
  assert.equal(state.taps, 1)
})

test("openwindow events parse, keeping commas in the title", () => {
  const info = Model.parseOpenWindow({ name: "openwindow", data: "5d28,2,foot,Hello, world" })
  assert.deepEqual(info, { address: "5d28", workspace: "2", appClass: "foot", title: "Hello, world" })
})

test("other events and malformed data are ignored", () => {
  assert.equal(Model.parseOpenWindow({ name: "closewindow", data: "5d28" }), null)
  assert.equal(Model.parseOpenWindow({ name: "openwindow", data: "5d28,2" }), null)
  assert.equal(Model.parseOpenWindow(null), null)
})

test("app label prefers the title, then the class", () => {
  assert.equal(Model.appLabel({ appClass: "foot", title: "Terminal" }), "Terminal")
  assert.equal(Model.appLabel({ appClass: "foot", title: "" }), "foot")
})
