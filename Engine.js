// Mission engine: which mission is next, what the current step expects, how help
// grows while the learner is stuck, and the saved progress. No Quickshell, so it
// runs under Node tests and qmltestrunner alike. Every function returns new state.

// Help grows after this long without progress: Bolt's hint, keys lit, the Mentor's demo.
var HINT_DELAYS_MS = [12000, 24000, 36000]

var PROGRESS_VERSION = 1
var CODENAME_MAX = 16

// ---------------------------------------------------------------- progress

// completed: finished mission numbers. current: where an unfinished mission was left
// ({mission, step, codename}), so closing the Academy mid-mission resumes there.
// settings: grown-up choices, kept when progress is reset.
function newProgress(settings) {
  return { version: PROGRESS_VERSION, codename: "", completed: [], current: null, settings: settings || defaultSettings() }
}

// characterColors: "classic" (each character's own colors) or "theme" (follow the theme).
function defaultSettings() {
  return { characterColors: "classic" }
}

function settingsOf(progress) {
  var s = progress && progress.settings
  return { characterColors: s && s.characterColors === "theme" ? "theme" : "classic" }
}

function withSettings(progress, changes) {
  var settings = settingsOf(progress)
  for (var k in changes) settings[k] = changes[k]
  return withChanges(progress, { settings: settingsOf({ settings: settings }) })
}

// Erase the learner's progress, keeping the grown-up's settings.
function resetProgress(progress) {
  return newProgress(settingsOf(progress))
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
  var c = p.current
  var current = c && Number.isInteger(c.mission) && c.mission >= 0 && Number.isInteger(c.step) && c.step >= 0
    ? { mission: c.mission, step: c.step, codename: typeof c.codename === "string" && isValidCodename(c.codename) ? c.codename.trim() : "" }
    : null
  return { version: PROGRESS_VERSION, codename: codename, completed: completed, current: current, settings: settingsOf(p) }
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
  return { version: PROGRESS_VERSION, codename: codename !== undefined ? codename : progress.codename, completed: completed, current: null, settings: settingsOf(progress) }
}

// Remember the step a learner reached, so they can close the Academy and come back.
function rememberStep(progress, session) {
  return {
    version: PROGRESS_VERSION,
    codename: progress.codename,
    completed: progress.completed,
    current: { mission: session.mission, step: session.step, codename: session.codename },
    settings: settingsOf(progress)
  }
}

// ---------------------------------------------------------------- campaign

// The rank held: the last one whose first mission is done, or -1 before the first.
function rankIndex(campaign, progress) {
  var held = -1
  campaign.ranks.forEach(function(rank, i) { if (progress.completed.indexOf(rank.missions[0]) !== -1) held = i })
  return held
}

// The ranks with each mission's state, for the progress strip and the map:
// "done", "now" (the mission being played, `current`), or "locked".
function campaignView(campaign, progress, current) {
  return campaign.ranks.map(function(rank) {
    return {
      name: rank.name,
      earned: progress.completed.indexOf(rank.missions[0]) !== -1,
      missions: rank.missions.map(function(n) {
        return {
          number: n,
          title: campaign.titles[n],
          state: progress.completed.indexOf(n) !== -1 ? "done" : n === current ? "now" : "locked"
        }
      })
    }
  })
}

// One state per step of the mission being played; a step being celebrated is done.
function stepStates(count, step, celebrating) {
  var out = []
  for (var i = 0; i < count; i++) out.push(i < step || (i === step && celebrating) ? "done" : i === step ? "now" : "todo")
  return out
}

// "07": mission numbers are shown as two digits.
function missionNumber(n) {
  return (n < 10 ? "0" : "") + n
}

// The session to start with: the remembered step if it belongs to the next mission, else its start.
// previous (optional) is the session before, whose windows still count when it was the same
// mission. A step that closes a window needs one the learner opened; without one (say,
// after logging out) it resumes a step earlier, where that window gets opened.
function resume(missions, progress, previous) {
  var index = nextMission(missions, progress)
  var session = startMission(index)
  if (previous && previous.mission === index && previous.windows) session.windows = previous.windows
  var c = progress.current
  if (c && c.mission === index && index < missions.length && c.step < missions[index].steps.length) {
    var expect = missions[index].steps[c.step].expect
    var closeWithout = expect.type === "window" && expect.action === "close"
      && !session.windows.some(function(w) { return w.app === expect.app })
    session.step = closeWithout && c.step > 0 ? c.step - 1 : c.step
    session.codename = c.codename
  }
  return session
}

function isValidCodename(name) {
  var trimmed = String(name).trim()
  return trimmed.length >= 1 && trimmed.length <= CODENAME_MAX && /^[A-Za-z0-9 _-]+$/.test(trimmed)
}

// ---------------------------------------------------------------- a mission in play

// windows: the learner's own windows, opened during this mission ({address, app}).
function startMission(index) {
  return { mission: index, step: 0, count: 0, hits: [], typed: "", idleMs: 0, hint: 0, codename: "", windows: [], celebrating: false, done: false }
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
    count: 0, hits: [], typed: "", idleMs: 0, hint: 0,
    codename: session.codename,
    windows: session.windows,
    celebrating: false,
    done: last
  }
}

// A finished step first celebrates, so the learner sees what they did, and only
// moves on when finishCelebration() is called (the view does that after a pause).
function celebrate(session, changes) {
  var next = withChanges(session, { celebrating: true, idleMs: 0, hint: 0 })
  for (var k in changes) next[k] = changes[k]
  return next
}

function finishCelebration(missions, session) {
  return session.celebrating ? advance(missions, session) : session
}

// event: {type: "button", id} | {type: "key", key} | {type: "submit", value}
//      | {type: "pointer", action: "hover" | "click" | "rightclick" | "drop", id, target?}
//      | {type: "held", key, ms}   a hold key has been down this long
//      | {type: "tap", key}        a hold key was pressed and let go quickly, alone
//      | {type: "window", action: "open" | "close", address, app}   a real window on the desktop
// Key events may carry text (what the key typed) and shift (Shift was held).
// A button step may also accept a key (expect.key), so Enter works before the mouse is taught.
// Only progress resets the help timer, so mashing other keys still brings hints.
function handle(missions, session, event) {
  var closedOwn = event.type === "window" && event.action === "close" ? ownWindow(session, event.address) : null
  if (event.type === "window") session = trackWindow(session, event)
  var step = currentStep(missions, session)
  if (!step || session.done || session.celebrating) return session
  var expect = step.expect
  if (expect.type === "button") {
    var clicked = event.type === "button" && event.id === expect.id
    var pressed = event.type === "key" && expect.key !== undefined && event.key === expect.key
    return clicked || pressed ? celebrate(session, {}) : session
  }
  if (expect.type === "key" && event.type === "key" && event.key === expect.key) {
    var count = session.count + 1
    if (count >= (expect.times || 1)) return celebrate(session, { count: count })
    return withChanges(session, { count: count, idleMs: 0, hint: 0 })
  }
  if (expect.type === "codename" && event.type === "submit" && isValidCodename(event.value))
    return celebrate(session, { codename: String(event.value).trim() })
  if (expect.type === "pointer" && event.type === "pointer") return handlePointer(expect, session, event)
  if (expect.type === "anykey" && event.type === "key" && isLetterOrDigit(event.key)) {
    var typed = (session.typed + (event.text || event.key.toLowerCase())).slice(-12)
    var taps = session.count + 1
    if (taps >= expect.times) return celebrate(session, { count: taps, typed: typed })
    return withChanges(session, { count: taps, typed: typed, idleMs: 0, hint: 0 })
  }
  if (expect.type === "hold" && event.type === "held" && event.key === expect.key && event.ms >= expect.ms)
    return celebrate(session, {})
  if (expect.type === "capital" && event.type === "key" && /^[A-Z]$/.test(event.key) && event.shift)
    return celebrate(session, { typed: event.key })
  if (expect.type === "tap" && event.type === "tap" && event.key === expect.key)
    return celebrate(session, {})
  // Opening counts for the right kind of app; closing only for a window the learner
  // opened, so closing someone else's work never counts.
  if (expect.type === "window" && event.type === "window" && event.action === expect.action) {
    if (event.action === "open" && event.app === expect.app) return celebrate(session, {})
    if (event.action === "close" && closedOwn && closedOwn.app === expect.app) return celebrate(session, {})
  }
  return session
}

function ownWindow(session, address) {
  for (var i = 0; i < session.windows.length; i++)
    if (session.windows[i].address === address) return session.windows[i]
  return null
}

function trackWindow(session, event) {
  var others = session.windows.filter(function(w) { return w.address !== event.address })
  var windows = event.action === "open" ? others.concat([{ address: event.address, app: event.app }]) : others
  return withChanges(session, { windows: windows })
}

function isLetterOrDigit(label) {
  return /^[A-Z0-9]$/.test(label)
}

// A pointer step lists targets (ids) to hover, click, right-click, or drop on
// expect.target; it is done once every target has been hit.
function handlePointer(expect, session, event) {
  if (event.action !== expect.action || expect.ids.indexOf(event.id) === -1) return session
  if (expect.action === "drop" && event.target !== expect.target) return session
  if (session.hits.indexOf(event.id) !== -1) return session
  var hits = session.hits.concat([event.id])
  if (hits.length >= expect.ids.length) return celebrate(session, { hits: hits, count: hits.length })
  return withChanges(session, { hits: hits, count: hits.length, idleMs: 0, hint: 0 })
}

function tick(session, ms) {
  if (session.celebrating || session.done) return session
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
    defaultSettings: defaultSettings,
    settingsOf: settingsOf,
    withSettings: withSettings,
    resetProgress: resetProgress,
    rankIndex: rankIndex,
    campaignView: campaignView,
    stepStates: stepStates,
    missionNumber: missionNumber,
    rememberStep: rememberStep,
    resume: resume,
    isValidCodename: isValidCodename,
    startMission: startMission,
    currentStep: currentStep,
    handle: handle,
    finishCelebration: finishCelebration,
    tick: tick,
    render: render
  }
}
