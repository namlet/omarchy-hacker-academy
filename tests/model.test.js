const { test } = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

const KEY_A = 0x41
const KEY_CAPSLOCK = 0x01000024

test("hold keys are recognised and named; letters are not", () => {
  assert.equal(Model.holdName(Model.KEY_SHIFT), "shift")
  assert.equal(Model.holdName(Model.KEY_CONTROL), "ctrl")
  assert.equal(Model.holdName(Model.KEY_ALT), "alt")
  assert.equal(Model.holdName(Model.KEY_SUPER_L), "super")
  assert.equal(Model.holdName(Model.KEY_META), "super")
  assert.equal(Model.isHoldKey(KEY_A), false)
})

test("shift is held only between press and release", () => {
  let state = Model.pressKey(Model.initialKeyState(), Model.KEY_SHIFT, false, 50)
  assert.equal(Model.isHeld(state, "shift"), true)
  state = Model.releaseKey(state, Model.KEY_SHIFT, 50)
  assert.equal(Model.isHeld(state, "shift"), false)
})

test("shift released as caps lock (Omarchy's default kb_options) still lets go", () => {
  // Captured on Omarchy defaults: Left Shift (scan code 50) is pressed as Shift
  // but its release is reported as Caps Lock.
  let state = Model.pressKey(Model.initialKeyState(), Model.KEY_SHIFT, false, 50)
  state = Model.releaseKey(state, KEY_CAPSLOCK, 50)
  assert.equal(Model.isHeld(state, "shift"), false)
})

test("every hold key is released by its physical key, whatever code the release reports", () => {
  for (const key of [Model.KEY_CONTROL, Model.KEY_ALT, Model.KEY_SUPER_L]) {
    const name = Model.holdName(key)
    let state = Model.pressKey(Model.initialKeyState(), key, false, 37)
    assert.equal(Model.isHeld(state, name), true)
    state = Model.releaseKey(state, KEY_CAPSLOCK, 37)
    assert.equal(Model.isHeld(state, name), false)
  }
})

test("with both shift keys down, letting go of one keeps shift held", () => {
  let state = Model.initialKeyState()
  state = Model.pressKey(state, Model.KEY_SHIFT, false, 50)
  state = Model.pressKey(state, Model.KEY_SHIFT, false, 62)
  state = Model.releaseKey(state, Model.KEY_SHIFT, 50)
  assert.equal(Model.isHeld(state, "shift"), true)
  state = Model.releaseKey(state, Model.KEY_SHIFT, 62)
  assert.equal(Model.isHeld(state, "shift"), false)
})

test("without scan codes, the key code pairs press and release", () => {
  let state = Model.pressKey(Model.initialKeyState(), Model.KEY_SHIFT, false)
  state = Model.releaseKey(state, Model.KEY_SHIFT)
  assert.equal(Model.isHeld(state, "shift"), false)
})

test("releasing everything lets go of all hold keys and keeps the tap count", () => {
  let state = Model.initialKeyState()
  state = Model.pressKey(state, KEY_A, false, 38)
  state = Model.pressKey(state, Model.KEY_SHIFT, false, 50)
  state = Model.pressKey(state, Model.KEY_CONTROL, false, 37)
  state = Model.releaseAll(state)
  assert.equal(Model.isHeld(state, "shift"), false)
  assert.equal(Model.isHeld(state, "ctrl"), false)
  assert.equal(state.taps, 1)
})

test("each letter press is one tap; auto-repeat and hold keys are not", () => {
  let state = Model.initialKeyState()
  state = Model.pressKey(state, KEY_A, false, 38)
  state = Model.pressKey(state, KEY_A, true, 38)
  state = Model.pressKey(state, Model.KEY_CONTROL, false, 37)
  assert.equal(state.taps, 1)
})

test("tapping a letter while holding shift keeps shift held", () => {
  let state = Model.pressKey(Model.initialKeyState(), Model.KEY_SHIFT, false, 50)
  state = Model.pressKey(state, KEY_A, false, 38)
  assert.equal(Model.isHeld(state, "shift"), true)
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
