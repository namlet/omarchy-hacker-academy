const { test } = require("node:test")
const assert = require("node:assert/strict")
const Engine = require("../Engine.js")
const { MISSIONS } = require("../Missions.js")

// ---------------------------------------------------------------- progress

test("saved progress round-trips", () => {
  const p = Engine.completeMission(Engine.newProgress(), 0, "Zero Cool")
  assert.deepEqual(Engine.parseProgress(Engine.serializeProgress(p)), p)
})

test("a remembered step resumes the mission there", () => {
  const missions = [{ steps: [{}, {}, {}] }, { steps: [{}] }]
  let p = Engine.rememberStep(Engine.newProgress(), { mission: 0, step: 2, codename: "Zero" })
  p = Engine.parseProgress(Engine.serializeProgress(p))
  const s = Engine.resume(missions, p)
  assert.deepEqual([s.mission, s.step, s.codename], [0, 2, "Zero"])
})

test("a remembered step is ignored once its mission is finished or out of range", () => {
  const missions = [{ steps: [{}, {}, {}] }, { steps: [{}] }]
  let p = Engine.rememberStep(Engine.newProgress(), { mission: 0, step: 2, codename: "Zero" })
  p = Engine.completeMission(p, 0)
  assert.equal(p.current, null)
  assert.deepEqual([Engine.resume(missions, p).mission, Engine.resume(missions, p).step], [1, 0])
  const stale = { version: 1, codename: "", completed: [], current: { mission: 0, step: 9, codename: "" } }
  assert.equal(Engine.resume(missions, stale).step, 0)
})

test("missing, broken, or foreign progress starts fresh", () => {
  for (const text of ["", "not json", "null", '{"version": 99, "completed": [0]}']) {
    assert.deepEqual(Engine.parseProgress(text), Engine.newProgress())
  }
})

test("progress drops invalid entries instead of failing", () => {
  const p = Engine.parseProgress('{"version": 1, "codename": "<script>", "completed": [0, -1, "x", 2]}')
  assert.deepEqual(p, { version: 1, codename: "", completed: [0, 2], current: null })
})

test("the next mission is the first one not completed", () => {
  const missions = [{}, {}, {}]
  assert.equal(Engine.nextMission(missions, Engine.newProgress()), 0)
  assert.equal(Engine.nextMission(missions, { version: 1, codename: "", completed: [0, 2], current: null }), 1)
  assert.equal(Engine.nextMission(missions, { version: 1, codename: "", completed: [0, 1, 2], current: null }), 3)
})

test("completing a mission twice records it once", () => {
  let p = Engine.completeMission(Engine.newProgress(), 0)
  p = Engine.completeMission(p, 0)
  assert.deepEqual(p.completed, [0])
})

test("codenames: 1 to 16 letters, digits, spaces, dashes, underscores", () => {
  for (const ok of ["Bolt", "Zero Cool", "x", "hack_3r-1", "  padded  "]) assert.equal(Engine.isValidCodename(ok), true, ok)
  for (const bad of ["", "   ", "a".repeat(17), "<script>", "emoji😀"]) assert.equal(Engine.isValidCodename(bad), false, bad)
})

// ---------------------------------------------------------------- steps

const SCRIPT = [
  { speaker: "mentor", lines: ["a"], expect: { type: "button", id: "go", key: "Enter" }, hint: {} },
  { speaker: "bolt", lines: ["b"], expect: { type: "key", key: "Backspace", times: 3 }, hint: {} },
  { speaker: "mentor", lines: ["c"], expect: { type: "codename" }, hint: {} }
]
const TEST_MISSIONS = [{ steps: SCRIPT }]

// Finish a step: it celebrates first, then advances when the view says so.
function complete(s, event) {
  s = Engine.handle(TEST_MISSIONS, s, event)
  assert.equal(s.celebrating, true)
  return Engine.finishCelebration(TEST_MISSIONS, s)
}

test("the right button celebrates, then advances; others do nothing", () => {
  let s = Engine.startMission(0)
  s = Engine.handle(TEST_MISSIONS, s, { type: "button", id: "other" })
  assert.deepEqual([s.step, s.celebrating], [0, false])
  s = Engine.handle(TEST_MISSIONS, s, { type: "button", id: "go" })
  assert.deepEqual([s.step, s.celebrating], [0, true])
  s = Engine.finishCelebration(TEST_MISSIONS, s)
  assert.deepEqual([s.step, s.celebrating], [1, false])
})

test("a button step also accepts its key, so Enter works before the mouse is taught", () => {
  const s = Engine.handle(TEST_MISSIONS, Engine.startMission(0), { type: "key", key: "Enter" })
  assert.equal(s.celebrating, true)
})

test("input is ignored and help pauses while celebrating", () => {
  let s = Engine.handle(TEST_MISSIONS, Engine.startMission(0), { type: "button", id: "go" })
  assert.equal(Engine.handle(TEST_MISSIONS, s, { type: "button", id: "go" }), s)
  assert.equal(Engine.tick(s, 60000).hint, 0)
})

test("finishing a celebration that isn't happening changes nothing", () => {
  const s = Engine.startMission(0)
  assert.equal(Engine.finishCelebration(TEST_MISSIONS, s), s)
})

test("a key step counts presses, and celebrates with the final count showing", () => {
  let s = { ...Engine.startMission(0), step: 1 }
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "Backspace" })
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "A" })
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "Backspace" })
  assert.deepEqual([s.step, s.count, s.celebrating], [1, 2, false])
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "Backspace" })
  assert.deepEqual([s.step, s.count, s.celebrating], [1, 3, true])
  s = Engine.finishCelebration(TEST_MISSIONS, s)
  assert.deepEqual([s.step, s.count], [2, 0])
})

test("a codename step needs a valid name and finishes the mission when last", () => {
  let s = { ...Engine.startMission(0), step: 2 }
  s = Engine.handle(TEST_MISSIONS, s, { type: "submit", value: "  " })
  assert.equal(s.done, false)
  s = complete(s, { type: "submit", value: " Zero Cool " })
  assert.equal(s.done, true)
  assert.equal(s.codename, "Zero Cool")
})

test("a pointer step needs every target, once each, with the right action", () => {
  const missions = [{ steps: [{ expect: { type: "pointer", action: "click", ids: ["a", "b"] } }] }]
  let s = Engine.startMission(0)
  s = Engine.handle(missions, s, { type: "pointer", action: "rightclick", id: "a" })
  s = Engine.handle(missions, s, { type: "pointer", action: "click", id: "zzz" })
  assert.deepEqual(s.hits, [])
  s = Engine.handle(missions, s, { type: "pointer", action: "click", id: "a" })
  s = Engine.handle(missions, s, { type: "pointer", action: "click", id: "a" })
  assert.deepEqual([s.hits, s.count, s.celebrating], [["a"], 1, false])
  s = Engine.handle(missions, s, { type: "pointer", action: "click", id: "b" })
  assert.deepEqual([s.count, s.celebrating], [2, true])
})

test("a drop only counts on the right target", () => {
  const missions = [{ steps: [{ expect: { type: "pointer", action: "drop", ids: ["big"], target: "jar" } }] }]
  let s = Engine.handle(missions, Engine.startMission(0), { type: "pointer", action: "drop", id: "big", target: "floor" })
  assert.equal(s.celebrating, false)
  s = Engine.handle(missions, s, { type: "pointer", action: "drop", id: "big", target: "jar" })
  assert.equal(s.celebrating, true)
})

test("hits reset when the next step starts", () => {
  const missions = [{ steps: [{ expect: { type: "pointer", action: "hover", ids: ["bolt"] } }, { expect: { type: "button", id: "x" } }] }]
  let s = Engine.handle(missions, Engine.startMission(0), { type: "pointer", action: "hover", id: "bolt" })
  s = Engine.finishCelebration(missions, s)
  assert.deepEqual([s.step, s.hits, s.count], [1, [], 0])
})

test("anykey counts letter and digit taps, ignoring other keys, and keeps what was typed", () => {
  const missions = [{ steps: [{ expect: { type: "anykey", times: 3 } }] }]
  let s = Engine.startMission(0)
  s = Engine.handle(missions, s, { type: "key", key: "A", text: "a" })
  s = Engine.handle(missions, s, { type: "key", key: "Shift" })
  s = Engine.handle(missions, s, { type: "key", key: "Space", text: " " })
  s = Engine.handle(missions, s, { type: "key", key: "7", text: "7" })
  assert.deepEqual([s.count, s.typed, s.celebrating], [2, "a7", false])
  s = Engine.handle(missions, s, { type: "key", key: "B", text: "b" })
  assert.deepEqual([s.typed, s.celebrating], ["a7b", true])
})

test("hold needs the right key for long enough", () => {
  const missions = [{ steps: [{ expect: { type: "hold", key: "Shift", ms: 3000 } }] }]
  let s = Engine.startMission(0)
  s = Engine.handle(missions, s, { type: "held", key: "Ctrl", ms: 5000 })
  s = Engine.handle(missions, s, { type: "held", key: "Shift", ms: 2900 })
  assert.equal(s.celebrating, false)
  s = Engine.handle(missions, s, { type: "held", key: "Shift", ms: 3000 })
  assert.equal(s.celebrating, true)
})

test("a capital needs a letter typed while Shift is held", () => {
  const missions = [{ steps: [{ expect: { type: "capital" } }] }]
  let s = Engine.startMission(0)
  s = Engine.handle(missions, s, { type: "key", key: "A", text: "a", shift: false })
  s = Engine.handle(missions, s, { type: "key", key: "7", text: "&", shift: true })
  assert.equal(s.celebrating, false)
  s = Engine.handle(missions, s, { type: "key", key: "Q", text: "Q", shift: true })
  assert.deepEqual([s.celebrating, s.typed], [true, "Q"])
})

test("a tap step needs a tap of that key, not a hold or a press", () => {
  const missions = [{ steps: [{ expect: { type: "tap", key: "Shift" } }] }]
  let s = Engine.startMission(0)
  s = Engine.handle(missions, s, { type: "key", key: "Shift" })
  s = Engine.handle(missions, s, { type: "held", key: "Shift", ms: 5000 })
  s = Engine.handle(missions, s, { type: "tap", key: "Ctrl" })
  assert.equal(s.celebrating, false)
  s = Engine.handle(missions, s, { type: "tap", key: "Shift" })
  assert.equal(s.celebrating, true)
})

test("a window step needs the right action, and the right app when it names one", () => {
  const missions = [{ steps: [
    { expect: { type: "window", action: "open", app: "terminal" } },
    { expect: { type: "window", action: "close" } }
  ] }]
  let s = Engine.startMission(0)
  s = Engine.handle(missions, s, { type: "window", action: "open", app: "browser" })
  s = Engine.handle(missions, s, { type: "window", action: "close", app: "" })
  s = Engine.handle(missions, s, { type: "key", key: "Enter" })
  assert.equal(s.celebrating, false)
  s = Engine.handle(missions, s, { type: "window", action: "open", app: "terminal" })
  assert.equal(s.celebrating, true)
  s = Engine.finishCelebration(missions, s)
  s = Engine.handle(missions, s, { type: "window", action: "close", app: "" })
  assert.equal(s.celebrating, true)
})

// ---------------------------------------------------------------- help

test("help grows with idle time: hint, keys, demo", () => {
  const [a, b, c] = Engine.HINT_DELAYS_MS
  let s = Engine.startMission(0)
  assert.equal(Engine.tick(s, a - 1).hint, 0)
  assert.equal(Engine.tick(s, a).hint, 1)
  assert.equal(Engine.tick(s, b).hint, 2)
  assert.equal(Engine.tick(s, c).hint, 3)
})

test("progress resets help; wrong input does not", () => {
  let s = Engine.tick(Engine.startMission(0), Engine.HINT_DELAYS_MS[1])
  s = Engine.handle(TEST_MISSIONS, s, { type: "button", id: "wrong" })
  assert.equal(s.hint, 2)
  s = complete(s, { type: "button", id: "go" })
  assert.deepEqual([s.hint, s.idleMs], [0, 0])
})

test("lines fill in the codename", () => {
  assert.equal(Engine.render("Welcome, {codename}.", "Zero Cool"), "Welcome, Zero Cool.")
  assert.equal(Engine.render("Welcome, {codename}.", ""), "Welcome, Recruit.")
})

// ---------------------------------------------------------------- mission 0 end to end

test("mission 0 can be completed with the real script, keyboard only", () => {
  const play = (s, event) => Engine.finishCelebration(MISSIONS, Engine.handle(MISSIONS, s, event))
  let s = Engine.startMission(0)
  s = play(s, { type: "key", key: "Enter" })
  s = Engine.handle(MISSIONS, s, { type: "key", key: "Backspace" })
  s = Engine.handle(MISSIONS, s, { type: "key", key: "Backspace" })
  s = play(s, { type: "key", key: "Backspace" })
  s = play(s, { type: "submit", value: "Zero Cool" })
  assert.equal(s.done, false)
  s = play(s, { type: "key", key: "Enter" })
  assert.equal(s.done, true)
  assert.equal(s.codename, "Zero Cool")
})

test("every step has a speaker, 1-2 lines, a known expectation, and full help", () => {
  for (const mission of MISSIONS) {
    for (const step of mission.steps) {
      assert.ok(["mentor", "bolt"].includes(step.speaker))
      assert.ok(step.lines.length >= 1 && step.lines.length <= 2)
      assert.ok(["button", "key", "codename", "pointer", "anykey", "hold", "capital", "tap", "window"].includes(step.expect.type))
      assert.ok(step.hint.bolt && step.hint.demo && Array.isArray(step.hint.keys))
      assert.ok(["mentor", "bolt"].includes(step.success.speaker) && step.success.line)
      if (step.expect.type === "window") assert.ok(step.combo && step.combo.length >= 2, "a window step shows its keys")
    }
  }
})
