// Mission engine: which mission is next, what the current step expects, how help
// grows while the learner is stuck, and the saved progress. No Quickshell, so it
// runs under Node tests and qmltestrunner alike. Every function returns new state.

// Help grows after this long without progress: Bolt's hint, keys lit, the Mentor's demo.
var HINT_DELAYS_MS = [12000, 24000, 36000]

var PROGRESS_VERSION = 1
var CODENAME_MAX = 16

// ---------------------------------------------------------------- progress

function newProgress() {
  return { version: PROGRESS_VERSION, codename: "", completed: [] }
}

// Saved progress is user-editable text, so anything unexpected starts fresh.
function parseProgress(text) {
  var p
  try { p = JSON.parse(text) } catch (e) { return newProgress() }
  if (!p || p.version !== PROGRESS_VERSION) return newProgress()
  var completed = Array.isArray(p.completed)
    ? p.completed.filter(function(n) { return Number.isInteger(n) && n >= 0 })
    : []
  var codename = typeof p.codename === "string" && isValidCodename(p.codename) ? p.codename.trim() : ""
  return { version: PROGRESS_VERSION, codename: codename, completed: completed }
}

function serializeProgress(progress) {
  return JSON.stringify(progress, null, 2) + "\n"
}

// The first mission not yet completed; missions.length when all are done.
function nextMission(missions, progress) {
  for (var i = 0; i < missions.length; i++)
    if (progress.completed.indexOf(i) === -1) return i
  return missions.length
}

function completeMission(progress, index, codename) {
  var completed = progress.completed.indexOf(index) === -1 ? progress.completed.concat([index]) : progress.completed
  return { version: PROGRESS_VERSION, codename: codename !== undefined ? codename : progress.codename, completed: completed }
}

function isValidCodename(name) {
  var trimmed = String(name).trim()
  return trimmed.length >= 1 && trimmed.length <= CODENAME_MAX && /^[A-Za-z0-9 _-]+$/.test(trimmed)
}

// ---------------------------------------------------------------- a mission in play

function startMission(index) {
  return { mission: index, step: 0, count: 0, idleMs: 0, hint: 0, codename: "", done: false }
}

function currentStep(missions, session) {
  var mission = missions[session.mission]
  return mission ? mission.steps[session.step] : null
}

function advance(missions, session) {
  var last = session.step + 1 >= missions[session.mission].steps.length
  return {
    mission: session.mission,
    step: last ? session.step : session.step + 1,
    count: 0, idleMs: 0, hint: 0,
    codename: session.codename,
    done: last
  }
}

// event: {type: "button", id} | {type: "key", key} | {type: "submit", value}
// Only progress resets the help timer, so mashing other keys still brings hints.
function handle(missions, session, event) {
  var step = currentStep(missions, session)
  if (!step || session.done) return session
  var expect = step.expect
  if (expect.type === "button" && event.type === "button" && event.id === expect.id)
    return advance(missions, session)
  if (expect.type === "key" && event.type === "key" && event.key === expect.key) {
    var count = session.count + 1
    if (count >= (expect.times || 1)) return advance(missions, session)
    return withChanges(session, { count: count, idleMs: 0, hint: 0 })
  }
  if (expect.type === "codename" && event.type === "submit" && isValidCodename(event.value)) {
    var next = advance(missions, session)
    next.codename = String(event.value).trim()
    return next
  }
  return session
}

function tick(session, ms) {
  var idle = session.idleMs + ms
  var hint = 0
  for (var i = 0; i < HINT_DELAYS_MS.length; i++)
    if (idle >= HINT_DELAYS_MS[i]) hint = i + 1
  return withChanges(session, { idleMs: idle, hint: hint })
}

function withChanges(session, changes) {
  var next = {}
  for (var k in session) next[k] = session[k]
  for (var c in changes) next[c] = changes[c]
  return next
}

// Lines may mention the learner's codename.
function render(line, codename) {
  return String(line).replace(/\{codename\}/g, codename || "Recruit")
}

if (typeof module !== "undefined") {
  module.exports = {
    HINT_DELAYS_MS: HINT_DELAYS_MS,
    newProgress: newProgress,
    parseProgress: parseProgress,
    serializeProgress: serializeProgress,
    nextMission: nextMission,
    completeMission: completeMission,
    isValidCodename: isValidCodename,
    startMission: startMission,
    currentStep: currentStep,
    handle: handle,
    tick: tick,
    render: render
  }
}
