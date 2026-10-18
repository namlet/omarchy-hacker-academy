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
  const step = { expect: { type: "button", id: "go" } }
  const missions = [{ steps: [step, step, step] }, { steps: [step] }]
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
  assert.deepEqual(p, { version: 1, codename: "", completed: [0, 2], current: null, settings: { characterColors: "classic" } })
})

test("settings survive saving, finishing missions, and a reset", () => {
  let p = Engine.withSettings(Engine.newProgress(), { characterColors: "theme" })
  p = Engine.parseProgress(Engine.serializeProgress(p))
  p = Engine.completeMission(p, 0, "Zero")
  p = Engine.rememberStep(p, Engine.startMission(1))
  assert.equal(p.settings.characterColors, "theme")
  p = Engine.resetProgress(p)
  assert.deepEqual([p.completed, p.codename, p.settings.characterColors], [[], "", "theme"])
})

test("progress saved before settings existed gets the defaults", () => {
  const p = Engine.parseProgress('{"version": 1, "codename": "Zero", "completed": [0], "current": null}')
  assert.deepEqual(p.settings, { characterColors: "classic" })
  assert.equal(Engine.withSettings(p, { characterColors: "neon" }).settings.characterColors, "classic")
})

// ---------------------------------------------------------------- campaign

const { CAMPAIGN } = require("../Missions.js")

test("ranks are earned by finishing the first mission of their group", () => {
  const done = (completed) => ({ completed })
  assert.equal(Engine.rankIndex(CAMPAIGN, done([])), -1)
  assert.equal(Engine.rankIndex(CAMPAIGN, done([0, 1, 2])), 0)
  assert.equal(Engine.rankIndex(CAMPAIGN, done([0, 1, 2, 3])), 1)
})

test("the campaign shows each mission as done, being played, or locked", () => {
  const view = Engine.campaignView(CAMPAIGN, { completed: [0, 1] }, 2)
  assert.deepEqual(view.map((r) => r.name), ["Recruit", "Agent", "Specialist", "White Hat"])
  assert.deepEqual(view[0].missions.map((m) => m.state), ["done", "done", "now"])
  assert.deepEqual(view[1].missions.map((m) => m.state), ["locked", "locked", "locked"])
  assert.deepEqual(view.map((r) => r.earned), [true, false, false, false])
  assert.equal(view[0].missions[1].title, "Pointer Control")
  assert.equal(view.flatMap((r) => r.missions).length, CAMPAIGN.titles.length)
})

test("step states mark the celebrated step as done", () => {
  assert.deepEqual(Engine.stepStates(4, 1, false), ["done", "now", "todo", "todo"])
  assert.deepEqual(Engine.stepStates(4, 1, true), ["done", "done", "todo", "todo"])
})

test("mission numbers are two digits", () => {
  assert.deepEqual([Engine.missionNumber(3), Engine.missionNumber(10)], ["03", "10"])
})

test("every mission built so far is in the campaign, under its own title", () => {
  const { MISSIONS } = require("../Missions.js")
  MISSIONS.forEach((m, i) => assert.equal(CAMPAIGN.titles[i], m.title))
  const ranked = CAMPAIGN.ranks.flatMap((r) => r.missions)
  assert.deepEqual(ranked, CAMPAIGN.titles.map((_, i) => i))
})

test("each rank's first mission ends on that rank's badge", () => {
  const { MISSIONS } = require("../Missions.js")
  for (const rank of CAMPAIGN.ranks) {
    const mission = MISSIONS[rank.missions[0]]
    if (!mission) continue
    assert.equal(mission.steps[mission.steps.length - 1].badge, rank.name)
  }
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

const WINDOW_MISSIONS = [{ steps: [
  { expect: { type: "window", action: "open", app: "terminal" } },
  { expect: { type: "window", action: "close", app: "terminal" } }
] }]
const opened = (address, app) => ({ type: "window", action: "open", address: address, app: app })
const closed = (address) => ({ type: "window", action: "close", address: address, app: "" })

test("opening a window counts only for the right kind of app", () => {
  let s = Engine.startMission(0)
  s = Engine.handle(WINDOW_MISSIONS, s, opened("b1", "browser"))
  s = Engine.handle(WINDOW_MISSIONS, s, { type: "key", key: "Enter" })
  assert.equal(s.celebrating, false)
  s = Engine.handle(WINDOW_MISSIONS, s, opened("t1", "terminal"))
  assert.equal(s.celebrating, true)
})

test("closing counts only for a window the learner opened, of the right kind", () => {
  let s = Engine.startMission(0)
  s = Engine.handle(WINDOW_MISSIONS, s, opened("b1", "browser"))
  s = Engine.finishCelebration(WINDOW_MISSIONS, Engine.handle(WINDOW_MISSIONS, s, opened("t1", "terminal")))
  s = Engine.handle(WINDOW_MISSIONS, s, closed("grownups"))
  s = Engine.handle(WINDOW_MISSIONS, s, closed("b1"))
  assert.equal(s.celebrating, false)
  s = Engine.handle(WINDOW_MISSIONS, s, closed("t1"))
  assert.equal(s.celebrating, true)
  assert.deepEqual(s.windows, [])
})

test("the learner's windows carry through the mission's steps", () => {
  let s = Engine.handle(WINDOW_MISSIONS, Engine.startMission(0), opened("t1", "terminal"))
  s = Engine.finishCelebration(WINDOW_MISSIONS, s)
  assert.deepEqual([s.step, s.windows], [1, [{ address: "t1", app: "terminal" }]])
})

test("a close step without the learner's window resumes at the step that opens it", () => {
  const p = Engine.rememberStep(Engine.newProgress(), { mission: 0, step: 1, codename: "" })
  assert.equal(Engine.resume(WINDOW_MISSIONS, p).step, 0)
  const before = Object.assign(Engine.startMission(0), { step: 1, windows: [{ address: "t1", app: "terminal" }] })
  const s = Engine.resume(WINDOW_MISSIONS, p, before)
  assert.deepEqual([s.step, s.windows.length], [1, 1])
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
      assert.ok(["mentor", "bolt", "glitch"].includes(step.speaker))
      assert.ok(step.lines.length >= 1 && step.lines.length <= 2)
      assert.ok(["button", "key", "codename", "pointer", "anykey", "hold", "capital", "tap", "window", "focus", "fullscreen", "swap", "float", "move", "resize", "workspace", "carry"].includes(step.expect.type))
      assert.ok(step.hint.bolt && step.hint.demo && Array.isArray(step.hint.keys))
      assert.ok(["mentor", "bolt", "glitch"].includes(step.success.speaker) && step.success.line)
      if (["window", "focus", "fullscreen", "swap", "float", "move", "resize", "workspace", "carry"].includes(step.expect.type)) assert.ok(step.combo && step.combo.length >= 2, "a desktop step shows its keys")
    }
  }
})

// ---------------------------------------------------------------- the spotlight

function spotlight() {
  const step = (expect, extra) => Object.assign({ expect }, extra || {})
  const two = { needs: { app: "terminal", count: 2 } }
  return [{ steps: [
    step({ type: "window", action: "open", app: "terminal", times: 2 }),
    step({ type: "focus" }, two),
    step({ type: "fullscreen", on: true }, two),
    step({ type: "fullscreen", on: false }, two),
    step({ type: "window", action: "close", app: "terminal", times: 2 })
  ] }]
}

// Events arrive together, as from Hyprland; the celebration (and moving on) happens
// after them, as it does on screen two seconds later.
function play(missions, events, session) {
  let s = session || Engine.startMission(0)
  for (const e of events) s = Engine.handle(missions, s, Object.assign({ type: "window" }, e))
  return s.celebrating ? Engine.finishCelebration(missions, s) : s
}

test("a step can ask for two windows, and counts them", () => {
  const m = spotlight()
  let s = play(m, [{ action: "open", address: "a", app: "terminal" }])
  assert.deepEqual([s.step, s.count], [0, 1])
  s = play(m, [{ action: "open", address: "b", app: "browser" }], s)
  assert.equal(s.count, 1, "a browser isn't a terminal")
  s = play(m, [{ action: "open", address: "b", app: "terminal" }], s)
  assert.equal(s.step, 1)
})

test("moving the spotlight counts only onto another of the learner's windows", () => {
  const m = spotlight()
  let s = play(m, [
    { action: "open", address: "a", app: "terminal" }, { action: "focus", address: "a" },
    { action: "open", address: "b", app: "terminal" }, { action: "focus", address: "b" }])
  assert.equal(s.step, 1, "the new terminal taking the spotlight, mid-celebration, doesn't count")
  s = play(m, [{ action: "focus", address: "b" }], s)
  assert.equal(s.step, 1, "the same window again (a title change) isn't a move")
  s = play(m, [{ action: "focus", address: "grownups" }], s)
  assert.equal(s.step, 1, "someone else's window doesn't count")
  s = play(m, [{ action: "focus", address: "a" }], s)
  assert.equal(s.step, 2)
})

test("full screen counts for the learner's window, on and then off", () => {
  const m = spotlight()
  let s = play(m, [{ action: "open", address: "a", app: "terminal" }, { action: "open", address: "b", app: "terminal" }, { action: "focus", address: "b" }])
  s = play(m, [{ action: "focus", address: "a" }], s)
  assert.equal(s.step, 2)
  s = play(m, [{ action: "fullscreen", on: false }], s)
  assert.equal(s.step, 2, "turning it off first isn't the task")
  s = play(m, [{ action: "fullscreen", on: true }], s)
  s = play(m, [{ action: "fullscreen", on: false }], s)
  assert.equal(s.step, 4)
  s = play(m, [{ action: "focus", address: "grownups" }, { action: "fullscreen", on: true }], s)
  assert.equal(s.step, 4)
  s = play(m, [{ action: "close", address: "a" }, { action: "close", address: "grownups" }], s)
  assert.deepEqual([s.step, s.count], [4, 1], "only the learner's windows count as closed")
  s = play(m, [{ action: "close", address: "b" }], s)
  assert.ok(s.done)
})

test("a step that needs the learner's windows resumes where they get opened", () => {
  const m = spotlight()
  const at = (step) => ({ version: 1, codename: "Zero", completed: [], current: { mission: 0, step, codename: "Zero" } })
  assert.equal(Engine.resume(m, at(3)).step, 0, "no terminals left after logging out")
  const previous = Object.assign(Engine.startMission(0), { windows: [{ address: "a", app: "terminal" }, { address: "b", app: "terminal" }], focused: "a" })
  const s = Engine.resume(m, at(3), previous)
  assert.deepEqual([s.step, s.focused], [3, "a"], "both still open: carry on")
})

// ---------------------------------------------------------------- rearranging HQ

function arranging() {
  const two = { needs: { app: "terminal", count: 2 } }
  return [{ steps: [
    { expect: { type: "window", action: "open", app: "terminal", times: 2 } },
    Object.assign({ expect: { type: "swap" } }, two),
    Object.assign({ expect: { type: "float", on: true } }, two),
    Object.assign({ expect: { type: "move" } }, two),
    Object.assign({ expect: { type: "resize" } }, two),
    Object.assign({ expect: { type: "float", on: false } }, two)
  ] }]
}

const at = (address, x, y, w, h, floating) => ({ action: "geometry", address, at: [x, y], size: [w, h], floating: !!floating })

test("swapping counts when a tiled window of the learner's moves to another spot", () => {
  const m = arranging()
  let s = play(m, [{ action: "open", address: "a", app: "terminal" }, { action: "open", address: "b", app: "terminal" }])
  assert.equal(s.step, 1)
  s = play(m, [at("a", 12, 12, 941, 1030), at("b", 967, 12, 941, 1030), at("grownups", 0, 0, 100, 100)], s)
  s = play(m, [at("grownups", 900, 0, 100, 100), at("a", 30, 12, 941, 1030)], s)
  assert.equal(s.step, 1, "someone else's window, or a nudge, doesn't count")
  s = play(m, [at("a", 967, 12, 941, 1030)], s)
  assert.equal(s.step, 2)
})

test("floating, dragging, resizing, and tiling again each count once, for the learner's window", () => {
  const m = arranging()
  let s = play(m, [{ action: "open", address: "a", app: "terminal" }, { action: "open", address: "b", app: "terminal" }])
  s = play(m, [at("a", 12, 12, 941, 1030)], s)
  s = play(m, [at("a", 967, 12, 941, 1030)], s)
  assert.equal(s.step, 2)
  s = play(m, [{ action: "float", address: "grownups", on: true }], s)
  assert.equal(s.step, 2)
  s = play(m, [{ action: "float", address: "b", on: true }], s)
  assert.equal(s.step, 3)
  // Floating moved the window; that was before this step, so it's the starting point.
  s = play(m, [at("b", 5, 5, 960, 1044, true)], s)
  assert.equal(s.step, 3, "where floating put it doesn't count as a drag")
  s = play(m, [at("b", 300, 200, 960, 1044, true)], s)
  assert.equal(s.step, 4)
  s = play(m, [at("b", 300, 200, 960, 1044, true), at("b", 300, 200, 1100, 1044, true)], s)
  assert.equal(s.step, 5)
  s = play(m, [{ action: "float", address: "b", on: false }], s)
  assert.ok(s.done)
})

// ---------------------------------------------------------------- secret rooms

test("going to a room, and carrying the learner's own window there", () => {
  const m = [{ steps: [
    { expect: { type: "workspace", to: "room" } },
    { expect: { type: "workspace", to: "home" } },
    { expect: { type: "window", action: "open", app: "terminal" } },
    { needs: { app: "terminal", count: 1 }, expect: { type: "carry", to: "room" } }
  ] }]
  let s = play(m, [{ action: "workspace", room: "other" }])
  assert.equal(s.step, 0, "the wrong room doesn't count")
  s = play(m, [{ action: "workspace", room: "room" }], s)
  s = play(m, [{ action: "workspace", room: "home" }], s)
  s = play(m, [{ action: "open", address: "a", app: "terminal" }], s)
  assert.equal(s.step, 3)
  s = play(m, [{ action: "carry", address: "grownups", room: "room" }, { action: "carry", address: "a", room: "other" }], s)
  assert.equal(s.step, 3, "someone else's window, or another room, doesn't count")
  s = play(m, [{ action: "carry", address: "a", room: "room" }], s)
  assert.ok(s.done)
})
