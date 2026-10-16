// Lesson logic, kept free of Quickshell so it runs under Node tests and qmltestrunner alike.

// Qt key codes (Qt::Key) for the keys a learner holds rather than taps.
var KEY_SHIFT = 0x01000020
var KEY_CONTROL = 0x01000021
var KEY_META = 0x01000022
var KEY_ALT = 0x01000023
var KEY_SUPER_L = 0x01000053
var KEY_SUPER_R = 0x01000054

// Which hold key a Qt key code is: "shift", "ctrl", "alt", "super", or "" for tap keys.
function holdName(key) {
  if (key === KEY_SHIFT) return "shift"
  if (key === KEY_CONTROL) return "ctrl"
  if (key === KEY_ALT) return "alt"
  if (key === KEY_META || key === KEY_SUPER_L || key === KEY_SUPER_R) return "super"
  return ""
}

function isHoldKey(key) {
  return holdName(key) !== ""
}

// held maps a physical key to the hold key it pressed. Releases are matched by
// physical key (scan code) because layouts and options can report a release
// under a different key code -- Omarchy's default shift:both_capslock_cancel
// reports Shift's release as Caps Lock. Without a scan code, the key code stands in.
function initialKeyState() {
  return { held: {}, taps: 0 }
}

function physicalKey(key, scanCode) {
  return scanCode ? "scan:" + scanCode : "key:" + key
}

function withHeld(held, id, name) {
  var next = {}
  for (var k in held) if (k !== id) next[k] = held[k]
  if (name) next[id] = name
  return next
}

// A tap is one press of a non-hold key; holding a key down (auto-repeat) is still one tap.
function pressKey(state, key, isAutoRepeat, scanCode) {
  var name = holdName(key)
  if (name) return { held: withHeld(state.held, physicalKey(key, scanCode), name), taps: state.taps }
  if (isAutoRepeat) return state
  return { held: state.held, taps: state.taps + 1 }
}

function releaseKey(state, key, scanCode) {
  var id = physicalKey(key, scanCode)
  if (!(id in state.held)) return state
  return { held: withHeld(state.held, id, ""), taps: state.taps }
}

// When the panel loses the keyboard, releases go elsewhere; let go of everything.
function releaseAll(state) {
  return { held: {}, taps: state.taps }
}

function isHeld(state, name) {
  for (var k in state.held) if (state.held[k] === name) return true
  return false
}

// The label printed on a key, as the on-screen keyboard shows it; "" for keys it doesn't show.
var KEY_LABELS = {}
KEY_LABELS[0x01000000] = "Esc"
KEY_LABELS[0x01000001] = "Tab"
KEY_LABELS[0x01000003] = "Backspace"
KEY_LABELS[0x01000004] = "Enter"
KEY_LABELS[0x01000005] = "Enter"
KEY_LABELS[0x01000024] = "Caps"
KEY_LABELS[0x20] = "Space"
KEY_LABELS[KEY_SHIFT] = "Shift"
KEY_LABELS[KEY_CONTROL] = "Ctrl"
KEY_LABELS[KEY_ALT] = "Alt"
KEY_LABELS[KEY_META] = "Win"
KEY_LABELS[KEY_SUPER_L] = "Win"
KEY_LABELS[KEY_SUPER_R] = "Win"

function keyLabel(key) {
  if ((key >= 0x41 && key <= 0x5a) || (key >= 0x30 && key <= 0x39)) return String.fromCharCode(key)
  return KEY_LABELS[key] || ""
}

// Keys currently down, by physical key, so a release reported under another code
// still lifts the right key: { down: { physicalKey: label } }.
function initialPressedState() {
  return { down: {} }
}

function keyDown(state, key, scanCode) {
  var label = keyLabel(key)
  if (!label) return state
  return { down: withHeld(state.down, physicalKey(key, scanCode), label) }
}

function keyUp(state, key, scanCode) {
  var id = physicalKey(key, scanCode)
  if (!(id in state.down)) return state
  return { down: withHeld(state.down, id, "") }
}

function pressedLabels(state) {
  var out = []
  for (var k in state.down) if (out.indexOf(state.down[k]) === -1) out.push(state.down[k])
  return out
}

// Hyprland's openwindow event data is "address,workspace,class,title"; the title may contain commas.
function parseOpenWindow(event) {
  if (!event || String(event.name) !== "openwindow") return null
  var parts = String(event.data || "").split(",")
  if (parts.length < 4) return null
  return { address: parts[0], workspace: parts[1], appClass: parts[2], title: parts.slice(3).join(",") }
}

function appLabel(windowInfo) {
  return windowInfo.title || windowInfo.appClass || "a window"
}

if (typeof module !== "undefined") {
  module.exports = {
    KEY_SHIFT: KEY_SHIFT,
    KEY_CONTROL: KEY_CONTROL,
    KEY_ALT: KEY_ALT,
    KEY_SUPER_L: KEY_SUPER_L,
    KEY_META: KEY_META,
    holdName: holdName,
    isHoldKey: isHoldKey,
    initialKeyState: initialKeyState,
    pressKey: pressKey,
    releaseKey: releaseKey,
    releaseAll: releaseAll,
    isHeld: isHeld,
    keyLabel: keyLabel,
    initialPressedState: initialPressedState,
    keyDown: keyDown,
    keyUp: keyUp,
    pressedLabels: pressedLabels,
    parseOpenWindow: parseOpenWindow,
    appLabel: appLabel
  }
}
