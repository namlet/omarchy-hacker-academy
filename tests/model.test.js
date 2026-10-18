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

test("key labels match what is printed on the keys", () => {
  assert.equal(Model.keyLabel(KEY_A), "A")
  assert.equal(Model.keyLabel(0x37), "7")
  assert.equal(Model.keyLabel(0x01000003), "Backspace")
  assert.equal(Model.keyLabel(0x01000004), "Enter")
  assert.equal(Model.keyLabel(Model.KEY_SUPER_L), "Win")
  assert.equal(Model.keyLabel(Model.KEY_META), "Win")
  assert.equal(Model.keyLabel(0x01000030), "")
})

test("pressed keys are lifted by physical key, even when the release reports another code", () => {
  let state = Model.keyDown(Model.initialPressedState(), Model.KEY_SHIFT, 50)
  state = Model.keyDown(state, KEY_A, 38)
  assert.deepEqual(Model.pressedLabels(state).sort(), ["A", "Shift"])
  state = Model.keyUp(state, KEY_CAPSLOCK, 50)
  assert.deepEqual(Model.pressedLabels(state), ["A"])
  state = Model.keyUp(state, KEY_A, 38)
  assert.deepEqual(Model.pressedLabels(state), [])
})

test("keys the keyboard doesn't show are ignored", () => {
  const state = Model.keyDown(Model.initialPressedState(), 0x01000030, 67)
  assert.deepEqual(Model.pressedLabels(state), [])
})

test("opening and closing windows are read from Hyprland's events", () => {
  assert.deepEqual(Model.windowEvent({ name: "openwindow", data: "5d28,2,foot,Hello, world" }), { action: "open", address: "5d28", app: "terminal" })
  assert.deepEqual(Model.windowEvent({ name: "openwindow", data: "5d29,1,chromium,New Tab" }), { action: "open", address: "5d29", app: "browser" })
  assert.deepEqual(Model.windowEvent({ name: "closewindow", data: "5d28" }), { action: "close", address: "5d28", app: "" })
  assert.equal(Model.windowEvent({ name: "closewindow", data: "0x5d28" }).address, "5d28")
})

test("the Academy needs its own workspace when anyone else's window is there", () => {
  assert.equal(Model.needsOwnWorkspace([], []), false)
  assert.equal(Model.needsOwnWorkspace(["0x5d28"], ["5d28"]), false)
  assert.equal(Model.needsOwnWorkspace(["5d28", "0x77aa"], ["5d28"]), true)
})

test("other events and malformed data are ignored", () => {
  assert.equal(Model.windowEvent({ name: "activewindow", data: "foot,Hello" }), null)
  assert.equal(Model.windowEvent({ name: "openwindow", data: "5d28,2" }), null)
  assert.equal(Model.windowEvent({ name: "closewindow", data: "" }), null)
  assert.equal(Model.windowEvent(null), null)
})

test("terminals and browsers are recognised like Omarchy tags them", () => {
  for (const c of ["Alacritty", "kitty", "com.mitchellh.ghostty", "foot", "org.omarchy.terminal", "TUI.float"])
    assert.equal(Model.appKind(c), "terminal", c)
  for (const c of ["chromium", "google-chrome", "brave-browser", "firefox", "zen", "librewolf"])
    assert.equal(Model.appKind(c), "browser", c)
  assert.equal(Model.appKind("org.omarchy.screensaver"), "screensaver")
  for (const c of ["org.gnome.Nautilus", "footclient-ish", "chromium-app", ""])
    assert.equal(Model.appKind(c), "", c)
})

test("focus and full screen come from Hyprland's raw events", () => {
  assert.deepEqual(Model.windowEvent({ name: "activewindowv2", data: "5cdbbf578f00" }), { action: "focus", address: "5cdbbf578f00", app: "" })
  assert.deepEqual(Model.windowEvent({ name: "activewindowv2", data: "" }), { action: "focus", address: "", app: "" })
  assert.equal(Model.windowEvent({ name: "fullscreen", data: "1" }).on, true)
  assert.equal(Model.windowEvent({ name: "fullscreen", data: "0" }).on, false)
  assert.equal(Model.windowEvent({ name: "activewindow", data: "foot,~" }), null, "the older event is ignored")
})

test("floating comes from Hyprland's raw events", () => {
  assert.deepEqual(Model.windowEvent({ name: "changefloatingmode", data: "5cdbbfaf53c0,1" }), { action: "float", address: "5cdbbfaf53c0", on: true, app: "" })
  assert.equal(Model.windowEvent({ name: "changefloatingmode", data: "5cdbbfaf53c0,0" }).on, false)
})

test("switching workspaces and carrying windows come from Hyprland's raw events", () => {
  assert.deepEqual(Model.windowEvent({ name: "workspacev2", data: "8,8" }), { action: "workspace", workspace: 8, address: "", app: "" })
  assert.deepEqual(Model.windowEvent({ name: "movewindowv2", data: "5cdbbfae7dc0,8,8" }), { action: "carry", address: "5cdbbfae7dc0", workspace: 8, app: "" })
})

test("Omarchy's menus opening and closing come from layer events", () => {
  assert.deepEqual(Model.windowEvent({ name: "openlayer", data: "omarchy-menu" }), { action: "menu", on: true, address: "", app: "" })
  assert.equal(Model.windowEvent({ name: "closelayer", data: "omarchy-menu" }).on, false)
  assert.equal(Model.windowEvent({ name: "openlayer", data: "hacker-academy" }), null, "the Academy's own window isn't a menu")
})
