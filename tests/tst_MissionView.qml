import QtQuick
import QtTest
import "../components"
import "../Engine.js" as Engine
import "../Missions.js" as Missions

Item {
  width: 1100
  height: 900

  MissionView {
    id: view
    hintClock: false
    celebrationMs: 50
  }

  SignalSpy { id: saved; target: view; signalName: "progressSaved" }
  SignalSpy { id: exited; target: view; signalName: "exitRequested" }

  TestCase {
    name: "MissionView"
    when: windowShown

    function init() {
      view.loginSession = ""
      view.progress = Engine.newProgress()
      view.begin()
      saved.clear()
      exited.clear()
      view.forceActiveFocus()
      wait(20)
    }

    // Let the screen settle before and after a click, as a person's hand would.
    function clickItem(name) {
      wait(20)
      const item = findChild(view, name)
      verify(item !== null && item.visible, name + " should be visible")
      mouseClick(item)
      wait(20)
    }

    function typeText(text) {
      for (let i = 0; i < text.length; i++) keyClick(text.charAt(i))
    }

    function waitForCelebration() {
      verify(view.celebrating)
      tryVerify(function() { return !view.celebrating }, 1000)
      wait(20)
    }

    function test_mission_zero_end_to_end() {
      compare(view.session.step, 0)
      clickItem("button-accept")
      waitForCelebration()
      compare(view.session.step, 1)
      compare(findChild(view, "field").text, "BOLTTTT")
      keyClick(Qt.Key_Backspace)
      keyClick(Qt.Key_Backspace)
      compare(findChild(view, "field").text, "BOLTT")
      keyClick(Qt.Key_Backspace)
      waitForCelebration()
      compare(view.session.step, 2)
      verify(findChild(view, "codenameInput").activeFocus)
      typeText("Zero")
      keyClick(Qt.Key_Return)
      waitForCelebration()
      compare(view.session.step, 3)
      verify(findChild(view, "lines").text.indexOf("Welcome to the Academy, Zero.") !== -1)
      verify(findChild(view, "rankUp").visible)
      saved.clear()
      clickItem("button-finish")
      compare(saved.count, 0)
      waitForCelebration()
      compare(saved.count, 1)
      compare(saved.signalArguments[0][0].completed, [0])
      compare(saved.signalArguments[0][0].codename, "Zero")
      compare(saved.signalArguments[0][0].current, null)
      compare([view.session.mission, view.session.step], [1, 0])
    }

    function test_enter_starts_without_the_mouse() {
      keyClick(Qt.Key_Return)
      verify(view.celebrating)
    }

    function test_fixed_name_stays_and_celebrates_before_moving_on() {
      clickItem("button-accept")
      waitForCelebration()
      for (let i = 0; i < 3; i++) keyClick(Qt.Key_Backspace)
      verify(view.celebrating)
      compare(findChild(view, "field").text, "BOLT")
      verify(findChild(view, "success").visible)
      verify(findChild(view, "success").text.indexOf("That's me!") !== -1)
      verify(!findChild(view, "cursor").visible)
      compare(view.session.step, 1)
      waitForCelebration()
      compare(view.session.step, 2)
    }

    function test_keyboard_shows_only_when_keys_are_the_task() {
      tryCompare(findChild(view, "keyboard"), "opacity", 0, 1000)
      clickItem("button-accept")
      waitForCelebration()
      tryCompare(findChild(view, "keyboard"), "opacity", 1, 1000)
    }

    function test_window_size_never_changes() {
      const w = view.implicitWidth, h = view.implicitHeight
      view.tick(Engine.HINT_DELAYS_MS[2])
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-accept")
      waitForCelebration()
      view.tick(Engine.HINT_DELAYS_MS[2])
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("settingsButton")
      compare([view.implicitWidth, view.implicitHeight], [w, h])
    }

    function test_an_empty_codename_is_not_accepted() {
      view.session = { mission: 0, step: 2, count: 0, idleMs: 0, hint: 0, codename: "", celebrating: false, done: false }
      view.focusTask()
      wait(20)
      keyClick(Qt.Key_Return)
      verify(!view.celebrating)
      compare(view.session.step, 2)
    }

    function test_after_the_codename_step_keys_come_back_to_the_mission() {
      view.session = { mission: 0, step: 2, count: 0, idleMs: 0, hint: 0, codename: "", celebrating: false, done: false }
      view.focusTask()
      wait(20)
      verify(findChild(view, "codenameInput").activeFocus)
      typeText("Zero")
      keyClick(Qt.Key_Return)
      waitForCelebration()
      verify(!findChild(view, "codenameInput").activeFocus)
      verify(view.activeFocus)
    }

    function test_help_grows_bolt_then_keys_then_demo() {
      clickItem("button-accept")
      waitForCelebration()
      verify(!findChild(view, "boltHint").visible)
      view.tick(Engine.HINT_DELAYS_MS[0])
      verify(findChild(view, "boltHint").visible)
      compare(findChild(view, "keyboard").lit, [])
      view.tick(Engine.HINT_DELAYS_MS[1] - Engine.HINT_DELAYS_MS[0])
      compare(findChild(view, "keyboard").lit, ["Backspace"])
      verify(!findChild(view, "demoHint").visible)
      view.tick(Engine.HINT_DELAYS_MS[2] - Engine.HINT_DELAYS_MS[1])
      verify(findChild(view, "demoHint").visible)
      keyClick(Qt.Key_Backspace)
      verify(!findChild(view, "boltHint").visible)
    }

    function test_keyboard_shows_held_keys() {
      keyPress(Qt.Key_Shift)
      compare(findChild(view, "keyboard").pressed, ["Shift"])
      keyRelease(Qt.Key_Shift)
      compare(findChild(view, "keyboard").pressed, [])
    }

    function test_escape_asks_to_close() {
      keyClick(Qt.Key_Escape)
      compare(exited.count, 1)
    }

    function test_closing_mid_mission_resumes_at_the_same_step() {
      clickItem("button-accept")
      waitForCelebration()
      compare(saved.count, 1)
      compare(saved.signalArguments[0][0].current.step, 1)
      view.begin()
      compare(view.session.step, 1)
    }

    function test_continues_at_the_next_unfinished_mission() {
      view.progress = { version: 1, codename: "Zero", completed: [0], current: null }
      view.begin()
      compare([view.session.mission, view.session.step], [1, 0])
      view.progress = { version: 1, codename: "Zero", completed: [0, 1], current: null }
      view.begin()
      compare([view.session.mission, view.session.step], [2, 0])
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2], current: null }
      view.begin()
      compare([view.session.mission, view.session.step], [3, 0])
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], current: null }
      view.begin()
      verify(view.finishedAll)
      verify(findChild(view, "comingSoon").visible)
    }

    // ------------------------------------------------------------ mission 1

    function startMissionOne() {
      view.progress = { version: 1, codename: "Zero", completed: [0], current: null }
      view.begin()
      wait(20)
    }

    function target(name) {
      const item = findChild(view, "target-" + name)
      verify(item !== null && item.visible, name + " should be visible")
      return item
    }

    function test_mission_one_hover_onto_bolt() {
      const playground = findChild(view, "playground")
      // Park the arrow where Bolt will appear, before the mission starts.
      mouseMove(playground, playground.width / 2, playground.height / 2)
      startMissionOne()
      wait(50)
      verify(playground.visible)
      compare(findChild(view, "keyboard").opacity, 0)
      verify(!view.celebrating, "an arrow already resting on Bolt doesn't count")
      mouseMove(playground, 5, 5)
      mouseMove(target("bolt"))
      verify(view.celebrating)
    }

    function test_mission_one_click_five_bugs() {
      startMissionOne()
      view.session = Object.assign({}, view.session, { step: 1 })
      wait(20)
      for (let i = 1; i <= 5; i++) {
        const bug = target("bug" + i)
        mouseClick(bug)
        wait(10)
        verify(!bug.visible, "caught bugs disappear")
      }
      verify(view.celebrating)
      compare(findChild(view, "tally").text, "5/5")
    }

    // Drag like a hand: press on the bug, move across the playground (which stays put), let go.
    function dragTo(item, toX, toY) {
      const area = findChild(view, "playground")
      const from = item.mapToItem(area, item.width / 2, item.height / 2)
      mousePress(area, from.x, from.y)
      for (let i = 1; i <= 8; i++)
        mouseMove(area, from.x + (toX - from.x) * i / 8, from.y + (toY - from.y) * i / 8, 10)
      mouseRelease(area, toX, toY)
    }

    function test_the_meter_fills_as_bugs_are_caught() {
      startMissionOne()
      view.session = Object.assign({}, view.session, { step: 1 })
      wait(20)
      verify(findChild(view, "meter").visible)
      compare(findChild(view, "tally").text, "0/5")
      mouseClick(target("bug1"))
      compare(findChild(view, "tally").text, "1/5")
      view.session = Object.assign({}, view.session, { step: 0, hits: [] })
      wait(20)
      verify(!findChild(view, "meter").visible, "one thing to do needs no meter")
    }

    function test_mission_one_drag_misses_then_lands_in_the_jar() {
      startMissionOne()
      view.session = Object.assign({}, view.session, { step: 2 })
      wait(20)
      const bug = target("bigbug"), jar = target("jar")
      const homeX = bug.x
      dragTo(bug, 10, bug.y + bug.height / 2)
      verify(!view.celebrating, "dropping on the floor doesn't count")
      compare(bug.x, homeX, "a missed drop goes back home")
      // Drop near the jar's edge: the bug still has to end up fully inside.
      dragTo(bug, jar.x + jar.width - 6, jar.y + jar.height / 2)
      verify(view.celebrating)
      verify(bug.x >= jar.x && bug.x + bug.width <= jar.x + jar.width, "bug sits inside the jar sideways")
      verify(bug.y >= jar.y && bug.y + bug.height <= jar.y + jar.height, "bug sits inside the jar up and down")
    }

    function test_mission_one_bugs_crawl_but_freeze_under_the_arrow() {
      startMissionOne()
      view.session = Object.assign({}, view.session, { step: 1 })
      wait(50)
      const bug = target("bug2")
      const x0 = bug.x, y0 = bug.y
      tryVerify(function() { return Math.abs(bug.x - x0) + Math.abs(bug.y - y0) > 5 }, 5000, "bugs crawl")
      // Point at the bug while it's resting between moves, like a learner taking aim.
      let lastX = -1
      tryVerify(function() { const still = bug.x === lastX; lastX = bug.x; wait(60); return still }, 5000, "bug comes to rest")
      mouseMove(bug)
      // Bugs wander randomly, so another one may be on top here: the top bug gets the arrow.
      const bugs = [1, 2, 3, 4, 5].map(function(i) { return findChild(view, "target-bug" + i) })
      let aimed = null
      tryVerify(function() { aimed = bugs.find(function(b) { return b.hovered }) || null; return aimed !== null }, 1000, "the arrow is on a bug")
      const x1 = aimed.x, y1 = aimed.y
      wait(2500)
      compare([aimed.x, aimed.y], [x1, y1], "a bug under the arrow stays put")
      // Another crawling bug may have wandered on top; clicking catches whichever is on top.
      mouseClick(bug)
      compare(view.session.hits.length, 1)
    }

    function test_mission_one_scroll_then_click_the_hidden_bug() {
      startMissionOne()
      view.session = Object.assign({}, view.session, { step: 3 })
      wait(20)
      const scroller = findChild(view, "scroller")
      compare(scroller.contentY, 0)
      for (let i = 0; i < 20 && !scroller.atYEnd; i++) {
        mouseWheel(scroller, scroller.width / 2, scroller.height / 2, 0, -120)
        wait(30)
      }
      verify(scroller.contentY > 0, "the wheel scrolls")
      tryVerify(function() { return scroller.atYEnd && !scroller.moving }, 2000)
      mouseClick(target("hidden"))
      verify(view.celebrating)
    }

    function test_mission_one_sneaky_bug_needs_a_right_click() {
      startMissionOne()
      view.session = Object.assign({}, view.session, { step: 4 })
      wait(20)
      mouseClick(target("sneaky"))
      verify(!view.celebrating)
      mouseClick(target("sneaky"), undefined, undefined, Qt.RightButton)
      verify(view.celebrating)
    }

    function test_mission_one_targets_glow_when_help_lights_up() {
      startMissionOne()
      verify(!findChild(view, "playground").highlight)
      view.tick(Engine.HINT_DELAYS_MS[1])
      verify(findChild(view, "playground").highlight)
    }

    // ------------------------------------------------------------ mission 2

    function startMissionTwo(step) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1], current: null }
      view.begin()
      if (step) view.session = Object.assign({}, view.session, { step: step })
      view.focusTask()
      wait(30)
    }

    function test_mission_two_tap_five_letters() {
      startMissionTwo(0)
      tryCompare(findChild(view, "keyboard"), "opacity", 1, 1000)
      keyClick(Qt.Key_Shift)
      for (const k of [Qt.Key_H, Qt.Key_A, Qt.Key_C, Qt.Key_K]) keyClick(k)
      verify(!view.celebrating)
      compare(findChild(view, "tally").text, "4/5")
      keyClick(Qt.Key_S)
      verify(view.celebrating)
      compare(findChild(view, "typed").text, "h a c k s")
    }

    function test_mission_two_hold_shift_three_seconds() {
      startMissionTwo(1)
      keyPress(Qt.Key_Shift)
      wait(1000)
      verify(findChild(view, "shieldFill").width > 0, "the force field grows while held")
      keyRelease(Qt.Key_Shift)
      wait(20)
      verify(!view.celebrating)
      verify(view.letGoEarly, "letting go early says keep holding")
      keyPress(Qt.Key_Shift)
      tryVerify(function() { return view.celebrating }, 4000)
      keyRelease(Qt.Key_Shift)
    }

    function test_mission_two_capital_letter_with_shift() {
      startMissionTwo(2)
      keyClick(Qt.Key_Q)
      verify(!view.celebrating, "no Shift, no capital")
      keyPress(Qt.Key_Shift)
      keyClick(Qt.Key_Q, Qt.ShiftModifier)
      keyRelease(Qt.Key_Shift)
      verify(view.celebrating)
      compare(findChild(view, "typed").text, "Q")
    }

    function test_mission_two_a_quick_shift_tap_stops_the_shouting() {
      startMissionTwo(3)
      compare(findChild(view, "loud").text, "AAAH! EVERYTHING IS LOUD!")
      keyPress(Qt.Key_Shift)
      wait(800)
      keyRelease(Qt.Key_Shift)
      verify(!view.celebrating, "a long press is a hold, not a tap")
      keyClick(Qt.Key_Shift)
      verify(view.celebrating)
      compare(findChild(view, "loud").text, "Ahh. Everything is quiet now.")
    }

    function test_mission_two_esc_stops_the_alarm_without_closing() {
      startMissionTwo(4)
      keyClick(Qt.Key_Escape)
      verify(view.celebrating)
      compare(exited.count, 0)
    }

    // ------------------------------------------------------------ mission 3

    function startMissionThree(step) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2], current: { mission: 3, step: step, codename: "Zero" } }
      view.begin()
      wait(20)
    }

    function windowOpens(address, appClass) { view.windowEvent({ name: "openwindow", data: address + ",1," + appClass + ",A window" }) }
    function windowCloses(address) { view.windowEvent({ name: "closewindow", data: address }) }

    function test_mission_three_sits_small_in_a_corner() {
      startMissionTwo(0)
      const keyboardWidth = view.implicitWidth
      startMissionThree(0)
      compare(view.stage, "corner")
      verify(!findChild(view, "keyboard").visible)
      verify(view.implicitWidth < keyboardWidth)
    }

    function test_mission_three_never_takes_the_keyboard_from_the_learners_windows() {
      startMissionTwo(0)
      compare(view.keyboardFocus, "exclusive")
      startMissionThree(0)
      compare(view.keyboardFocus, "exclusive", "Enter presses the button")
      for (const step of [1, 2, 3, 4]) {
        startMissionThree(step)
        compare(view.keyboardFocus, "none", "step " + step)
      }
      startMissionThree(5)
      compare(view.keyboardFocus, "exclusive", "Enter finishes, even with no window left to give it focus")
    }

    function test_mission_three_end_to_end() {
      startMissionThree(0)
      const w = view.implicitWidth, h = view.implicitHeight
      clickItem("button-ready")
      waitForCelebration()

      verify(findChild(view, "combo").visible)
      verify(findChild(view, "combo-Win").visible && findChild(view, "combo-Enter").visible)
      windowOpens("b0", "chromium")
      windowCloses("b0")
      verify(!view.celebrating)
      windowOpens("t1", "foot")
      waitForCelebration()

      compare(findChild(view, "instruction").text, "Close the terminal.")
      windowCloses("grownups")
      verify(!view.celebrating)
      windowCloses("t1")
      waitForCelebration()

      windowOpens("t2", "foot")
      verify(!view.celebrating)
      verify(findChild(view, "combo-Shift").visible && findChild(view, "combo-B").visible)
      windowOpens("b1", "chromium")
      waitForCelebration()

      windowCloses("b1")
      waitForCelebration()

      verify(findChild(view, "rankUp").visible)
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(3) !== -1)
    }

    function test_mission_three_ignores_the_screensaver_coming_and_going() {
      startMissionThree(1)
      windowOpens("aa01", "org.omarchy.screensaver")
      verify(!view.celebrating)
      windowOpens("t1", "foot")
      waitForCelebration()
      windowCloses("aa01")
      verify(!view.celebrating)
      windowCloses("t1")
      verify(view.celebrating)
    }

    function test_reopening_mid_mission_keeps_the_learners_windows() {
      startMissionThree(1)
      windowOpens("t1", "foot")
      waitForCelebration()
      verify(view.needsOwnWorkspace(["0x5d28"]), "a grown-up's window means moving away")
      verify(!view.needsOwnWorkspace(["0xt1"]), "the learner's own terminal is fine")
      view.begin()
      compare(view.session.step, 2)
      windowCloses("t1")
      verify(view.celebrating)
    }

    // ------------------------------------------------------------ mission 4

    function startMissionFour(step) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3], current: { mission: 4, step: step, codename: "Zero" } }
      view.begin()
      wait(20)
    }

    function focusOn(address) { view.windowEvent({ name: "activewindowv2", data: address }) }
    function fullscreen(on) { view.windowEvent({ name: "fullscreen", data: on ? "1" : "0" }) }

    function test_mission_four_end_to_end() {
      startMissionFour(0)
      const w = view.implicitWidth, h = view.implicitHeight
      compare(view.stage, "corner")
      clickItem("button-ready")
      waitForCelebration()

      verify(findChild(view, "meter").visible)
      windowOpens("t1", "foot")
      focusOn("t1")
      compare(findChild(view, "tally").text, "1/2")
      windowOpens("t2", "foot")
      focusOn("t2")
      waitForCelebration()

      compare(view.keyboardFocus, "none", "the spotlight stays on the learner's windows")
      focusOn("t2")
      verify(!view.celebrating, "a title change isn't a move")
      focusOn("t1")
      waitForCelebration()
      focusOn("t2")
      waitForCelebration()

      fullscreen(true)
      waitForCelebration()
      fullscreen(false)
      waitForCelebration()

      windowCloses("t2")
      compare(findChild(view, "tally").text, "1/2")
      windowCloses("t1")
      waitForCelebration()

      compare(view.session.step, 7)
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(4) !== -1)
    }

    function test_steps_without_a_button_give_the_rank_up_no_button_name() {
      startMissionFour(2)
      compare(findChild(view, "rankUp").buttonId, "")
    }

    function test_the_glitch_speaks_with_its_own_picture() {
      startMissionFour(1)
      compare(findChild(view, "portraitSprite").sprite, "glitch")
    }

    function test_mission_four_resumes_where_the_terminals_get_opened() {
      startMissionFour(4)
      compare(view.session.step, 1, "after logging out the terminals are gone")
    }

    // ------------------------------------------------------------ mission 5

    function startMissionFive(step) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4], current: { mission: 5, step: step, codename: "Zero" } }
      view.begin()
      wait(20)
    }

    function place(address, x, y, w, h, floating) { view.windowGeometry({ address: "0x" + address, at: [x, y], size: [w, h], floating: floating }) }
    function floats(address, on) { view.windowEvent({ name: "changefloatingmode", data: address + "," + (on ? 1 : 0) }) }

    function test_mission_five_end_to_end() {
      startMissionFive(0)
      const w = view.implicitWidth, h = view.implicitHeight
      clickItem("button-ready")
      waitForCelebration()
      verify(!view.watchesLayout)
      windowOpens("t1", "foot")
      windowOpens("t2", "foot")
      waitForCelebration()

      verify(view.watchesLayout, "swapping sends no event")
      compare(view.keyboardFocus, "none")
      place("t1", 12, 12, 941, 1030, false)
      place("t2", 967, 12, 941, 1030, false)
      verify(!view.celebrating)
      place("t1", 967, 12, 941, 1030, false)
      waitForCelebration()

      floats("t2", true)
      waitForCelebration()
      place("t2", 5, 5, 960, 1044, true)
      verify(!view.celebrating, "where floating put it is the start")
      place("t2", 400, 300, 960, 1044, true)
      waitForCelebration()
      place("t2", 400, 300, 960, 1044, true)
      place("t2", 400, 300, 700, 600, true)
      waitForCelebration()
      floats("t2", false)
      waitForCelebration()

      windowCloses("t1")
      windowCloses("t2")
      waitForCelebration()
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(5) !== -1)
    }

    // ------------------------------------------------------------ mission 6

    function startMissionSix(step) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5], current: { mission: 6, step: step, codename: "Zero" } }
      view.begin()
      view.homeRoom = 2
      view.secretRoom = 3
      wait(20)
    }

    function goTo(n) { view.windowEvent({ name: "workspacev2", data: n + "," + n }) }

    function test_mission_six_end_to_end() {
      startMissionSix(0)
      const w = view.implicitWidth, h = view.implicitHeight
      clickItem("button-ready")
      waitForCelebration()

      compare(findChild(view, "instruction").text, "Go to room 3.")
      verify(findChild(view, "combo-3").visible, "the room's number is the key to press")
      goTo(1)
      verify(!view.celebrating, "the wrong room doesn't count")
      goTo(3)
      waitForCelebration()
      goTo(2)
      waitForCelebration()
      windowOpens("t1", "foot")
      waitForCelebration()
      view.windowEvent({ name: "movewindowv2", data: "t1,3,3" })
      waitForCelebration()
      windowCloses("t1")
      waitForCelebration()
      goTo(2)
      waitForCelebration()

      verify(findChild(view, "rankUp").visible)
      compare(findChild(view, "rankName").text, "SPECIALIST")
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(6) !== -1)
    }

    function test_rooms_show_a_question_mark_until_picked() {
      startMissionSix(1)
      view.secretRoom = 0
      compare(findChild(view, "instruction").text, "Go to room ?.")
    }

    // ------------------------------------------------------------ mission 7

    function startMissionSeven(step) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5, 6], current: { mission: 7, step: step, codename: "Zero" } }
      view.begin()
      wait(20)
    }

    function menu(open) { view.windowEvent({ name: open ? "openlayer" : "closelayer", data: "omarchy-menu" }) }

    function test_mission_seven_end_to_end() {
      startMissionSeven(0)
      const w = view.implicitWidth, h = view.implicitHeight
      clickItem("button-ready")
      waitForCelebration()

      compare(view.keyboardFocus, "none", "the menu gets the keys")
      menu(true)
      waitForCelebration()
      verify(findChild(view, "combo-Esc").visible)
      menu(false)
      waitForCelebration()
      windowOpens("calc", "omacalc")
      waitForCelebration()
      windowCloses("calc")
      waitForCelebration()
      menu(true)
      waitForCelebration()
      menu(false)
      waitForCelebration()

      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(7) !== -1)
    }

    // ------------------------------------------------------------ mission 8

    function startMissionEight(step, login) {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5, 6, 7], current: { mission: 8, step: step, codename: "Zero", login: login || "" } }
      view.begin()
      wait(20)
    }

    function test_mission_eight_locks_and_unlocks() {
      view.loginSession = "47"
      startMissionEight(0)
      const w = view.implicitWidth, h = view.implicitHeight
      clickItem("button-ready")
      waitForCelebration()

      verify(view.watchesLock)
      compare(view.keyboardFocus, "none", "the lock screen gets the keys")
      view.lockState(false)
      verify(!view.celebrating, "not locked yet")
      view.lockState(true)
      waitForCelebration()
      view.lockState(true)
      verify(!view.celebrating, "still locked")
      view.lockState(false)
      waitForCelebration()
      verify(!view.watchesLock)
      menu(true)
      waitForCelebration()
      menu(false)
      waitForCelebration()

      compare(view.expectType, "login")
      compare(saved.signalArguments[saved.count - 1][0].current.login, "47", "the step remembers this login")
      view.arrive()
      verify(!view.celebrating, "the same login: not logged out yet")
      compare([view.implicitWidth, view.implicitHeight], [w, h])
    }

    function test_mission_eight_resumes_after_logging_back_in() {
      view.loginSession = "52"
      startMissionEight(5, "47")
      compare(view.expectType, "login")
      view.arrive()
      waitForCelebration()
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(8) !== -1)
    }

    // ------------------------------------------------------------ mission 9

    function test_mission_nine_end_to_end() {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5, 6, 7, 8], current: { mission: 9, step: 0, codename: "Zero" } }
      view.begin()
      wait(20)
      const w = view.implicitWidth, h = view.implicitHeight
      clickItem("button-ready")
      waitForCelebration()
      menu(true)
      waitForCelebration()
      menu(false)
      waitForCelebration()
      menu(true)
      waitForCelebration()
      menu(false)
      waitForCelebration()

      windowOpens("t1", "foot")
      windowOpens("t2", "foot")
      verify(!view.celebrating, "two of three")
      windowOpens("t3", "foot")
      waitForCelebration()
      verify(findChild(view, "combo-Delete").visible)
      windowCloses("t1")
      windowCloses("t2")
      windowCloses("t3")
      waitForCelebration()

      clickItem("button-help")
      waitForCelebration()
      verify(findChild(view, "rankUp").visible)
      compare(findChild(view, "rankName").text, "WHITE HAT")
      compare([view.implicitWidth, view.implicitHeight], [w, h])
      clickItem("button-finish")
      waitForCelebration()
      verify(saved.signalArguments[saved.count - 1][0].completed.indexOf(9) !== -1)
      verify(view.partDone)
    }

    function test_mission_three_keys_light_up_when_help_grows() {
      startMissionThree(1)
      verify(!findChild(view, "combo-Win").lit)
      view.tick(Engine.HINT_DELAYS_MS[1])
      verify(findChild(view, "combo-Win").lit && findChild(view, "combo-Enter").lit)
      // The keyboard picture stays away: Omarchy's shortcuts never reach it.
      verify(!findChild(view, "keyboard").visible)
    }

    // ------------------------------------------------------------ progress and ranks

    function test_the_strip_shows_missions_done_now_and_locked() {
      startMissionOne()
      compare(findChild(view, "mission-0").missionState, "done")
      compare(findChild(view, "mission-1").missionState, "now")
      compare(findChild(view, "mission-2").missionState, "locked")
      compare(findChild(view, "mission-9").missionState, "locked")
      compare(findChild(view, "stepPips").children.length - 1, view.mission.steps.length)
    }

    function test_the_rank_shows_once_earned() {
      verify(!findChild(view, "rankChip").visible, "no rank before recruitment")
      startMissionOne()
      verify(findChild(view, "rankChip").visible)
      compare(findChild(view, "rankChipText").text, "RECRUIT")
    }

    function test_recruitment_ends_on_the_recruit_badge() {
      view.session = { mission: 0, step: 3, count: 0, hits: [], idleMs: 0, hint: 0, codename: "Zero", windows: [], celebrating: false, done: false }
      wait(20)
      verify(findChild(view, "rankUp").visible)
      verify(!findChild(view, "portrait").visible, "the rank-up takes the whole body")
      compare(findChild(view, "rankName").text, "RECRUIT")
      compare(findChild(view, "rankBadge").sprite, "recruitBadge")
      verify(findChild(view, "rankLine").text.indexOf("You are now a Recruit.") !== -1)
    }

    function test_the_agent_badge_fits_the_corner_window() {
      startMissionThree(0)
      const w = view.implicitWidth, h = view.implicitHeight
      startMissionThree(5)
      verify(findChild(view, "rankUp").visible)
      compare(findChild(view, "rankName").text, "AGENT")
      compare(findChild(view, "rankBadge").sprite, "agentBadge")
      compare([view.implicitWidth, view.implicitHeight], [w, h])
    }

    function test_the_map_shows_the_campaign_when_every_mission_is_done() {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], current: null }
      view.begin()
      wait(20)
      verify(findChild(view, "campaignMap").visible)
      verify(findChild(view, "badge-Recruit").border.color === findChild(view, "badge-White Hat").border.color, "all earned")
      compare(findChild(view, "comingSoon").text, Missions.UI.partDone)
    }

    function test_character_colors_can_follow_the_theme() {
      compare(findChild(view, "portraitSprite").mode, "classic")
      clickItem("settingsButton")
      clickItem("settings-colors")
      compare(saved.signalArguments[0][0].settings.characterColors, "theme")
      compare(findChild(view, "portraitSprite").mode, "theme")
      clickItem("settings-reset")
      clickItem("settings-reset")
      compare(view.progress.settings.characterColors, "theme", "a reset keeps the setting")
    }

    function test_settings_back_returns_to_the_mission() {
      clickItem("settingsButton")
      verify(!findChild(view, "portrait").visible, "settings take the body's place")
      clickItem("settings-back")
      verify(!findChild(view, "settings").visible)
      verify(findChild(view, "portrait").visible)
    }

    function test_settings_reset_asks_first_and_colors_show_the_choice() {
      clickItem("settingsButton")
      verify(findChild(view, "colors-classic").filled)
      verify(!findChild(view, "colors-theme").filled)
      clickItem("settings-colors")
      verify(findChild(view, "colors-theme").filled)
      clickItem("settings-reset")
      verify(view.confirmingReset, "the first click only asks")
      compare(view.session.mission, 0)
    }

    function test_nothing_to_skip_once_every_mission_is_done() {
      view.progress = { version: 1, codename: "Zero", completed: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], current: null }
      view.begin()
      clickItem("settingsButton")
      verify(!findChild(view, "settings-skip").visible)
    }

    function test_settings_skip_and_reset() {
      clickItem("settingsButton")
      verify(findChild(view, "settings").visible)
      clickItem("settings-skip")
      compare(saved.signalArguments[0][0].completed, [0])
      compare(view.session.mission, 1)

      clickItem("settingsButton")
      clickItem("settings-reset")
      compare(saved.count, 1)
      clickItem("settings-reset")
      compare(saved.count, 2)
      compare(saved.signalArguments[1][0].completed, [])
      compare(view.session.mission, 0)
      verify(!findChild(view, "settings").visible)
    }
  }
}
