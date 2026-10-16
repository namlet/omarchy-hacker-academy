const { test } = require("node:test")
const assert = require("node:assert/strict")
const Engine = require("../Engine.js")
const { MISSIONS } = require("../Missions.js")

// ---------------------------------------------------------------- progress

test("saved progress round-trips", () => {
  const p = Engine.completeMission(Engine.newProgress(), 0, "Zero Cool")
  assert.deepEqual(Engine.parseProgress(Engine.serializeProgress(p)), p)
})

test("missing, broken, or foreign progress starts fresh", () => {
  for (const text of ["", "not json", "null", '{"version": 99, "completed": [0]}']) {
    assert.deepEqual(Engine.parseProgress(text), Engine.newProgress())
  }
})

test("progress drops invalid entries instead of failing", () => {
  const p = Engine.parseProgress('{"version": 1, "codename": "<script>", "completed": [0, -1, "x", 2]}')
  assert.deepEqual(p, { version: 1, codename: "", completed: [0, 2] })
})

test("the next mission is the first one not completed", () => {
  const missions = [{}, {}, {}]
  assert.equal(Engine.nextMission(missions, Engine.newProgress()), 0)
  assert.equal(Engine.nextMission(missions, { version: 1, codename: "", completed: [0, 2] }), 1)
  assert.equal(Engine.nextMission(missions, { version: 1, codename: "", completed: [0, 1, 2] }), 3)
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
  { speaker: "mentor", lines: ["a"], expect: { type: "button", id: "go" }, hint: {} },
  { speaker: "bolt", lines: ["b"], expect: { type: "key", key: "Backspace", times: 3 }, hint: {} },
  { speaker: "mentor", lines: ["c"], expect: { type: "codename" }, hint: {} }
]
const TEST_MISSIONS = [{ steps: SCRIPT }]

test("the right button advances; others do nothing", () => {
  let s = Engine.startMission(0)
  s = Engine.handle(TEST_MISSIONS, s, { type: "button", id: "other" })
  assert.equal(s.step, 0)
  s = Engine.handle(TEST_MISSIONS, s, { type: "button", id: "go" })
  assert.equal(s.step, 1)
})

test("a key step counts presses until it has enough", () => {
  let s = { ...Engine.startMission(0), step: 1 }
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "Backspace" })
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "A" })
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "Backspace" })
  assert.deepEqual([s.step, s.count], [1, 2])
  s = Engine.handle(TEST_MISSIONS, s, { type: "key", key: "Backspace" })
  assert.deepEqual([s.step, s.count], [2, 0])
})

test("a codename step needs a valid name and finishes the mission when last", () => {
  let s = { ...Engine.startMission(0), step: 2 }
  s = Engine.handle(TEST_MISSIONS, s, { type: "submit", value: "  " })
  assert.equal(s.done, false)
  s = Engine.handle(TEST_MISSIONS, s, { type: "submit", value: " Zero Cool " })
  assert.equal(s.done, true)
  assert.equal(s.codename, "Zero Cool")
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
  s = Engine.handle(TEST_MISSIONS, s, { type: "button", id: "go" })
  assert.deepEqual([s.hint, s.idleMs], [0, 0])
})

test("lines fill in the codename", () => {
  assert.equal(Engine.render("Welcome, {codename}.", "Zero Cool"), "Welcome, Zero Cool.")
  assert.equal(Engine.render("Welcome, {codename}.", ""), "Welcome, Recruit.")
})

// ---------------------------------------------------------------- mission 0 end to end

test("mission 0 can be completed with the real script", () => {
  let s = Engine.startMission(0)
  s = Engine.handle(MISSIONS, s, { type: "button", id: "accept" })
  for (let i = 0; i < 3; i++) s = Engine.handle(MISSIONS, s, { type: "key", key: "Backspace" })
  s = Engine.handle(MISSIONS, s, { type: "submit", value: "Zero Cool" })
  assert.equal(s.done, false)
  s = Engine.handle(MISSIONS, s, { type: "button", id: "finish" })
  assert.equal(s.done, true)
  assert.equal(s.codename, "Zero Cool")
})

test("every step has a speaker, 1-2 lines, a known expectation, and full help", () => {
  for (const mission of MISSIONS) {
    for (const step of mission.steps) {
      assert.ok(["mentor", "bolt"].includes(step.speaker))
      assert.ok(step.lines.length >= 1 && step.lines.length <= 2)
      assert.ok(["button", "key", "codename"].includes(step.expect.type))
      assert.ok(step.hint.bolt && step.hint.demo && Array.isArray(step.hint.keys))
    }
  }
})
