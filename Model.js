// Lesson logic, kept free of Quickshell so it runs under Node tests and qmltestrunner alike.

// Qt key codes (Qt::Key) for the keys a learner holds rather than taps.
var KEY_SHIFT = 0x01000020
var KEY_CONTROL = 0x01000021
var KEY_META = 0x01000022
var KEY_ALT = 0x01000023
var KEY_SUPER_L = 0x01000053
var KEY_SUPER_R = 0x01000054

var HOLD_KEYS = [KEY_SHIFT, KEY_CONTROL, KEY_META, KEY_ALT, KEY_SUPER_L, KEY_SUPER_R]

function isHoldKey(key) {
  return HOLD_KEYS.indexOf(key) !== -1
}

function initialKeyState() {
  return { shiftHeld: false, taps: 0 }
}

// A tap is one press of a non-hold key; holding a key down (auto-repeat) is still one tap.
function pressKey(state, key, isAutoRepeat) {
  if (key === KEY_SHIFT) return { shiftHeld: true, taps: state.taps }
  if (isHoldKey(key) || isAutoRepeat) return state
  return { shiftHeld: state.shiftHeld, taps: state.taps + 1 }
}

function releaseKey(state, key) {
  if (key === KEY_SHIFT) return { shiftHeld: false, taps: state.taps }
  return state
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
    isHoldKey: isHoldKey,
    initialKeyState: initialKeyState,
    pressKey: pressKey,
    releaseKey: releaseKey,
    parseOpenWindow: parseOpenWindow,
    appLabel: appLabel
  }
}
