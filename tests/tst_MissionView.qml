import QtQuick
import QtTest
import "../components"
import "../Engine.js" as Engine

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
      var item = findChild(view, name)
      verify(item !== null && item.visible, name + " should be visible")
      mouseClick(item)
      wait(20)
    }

    function typeText(text) {
      for (var i = 0; i < text.length; i++) keyClick(text.charAt(i))
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
      verify(findChild(view, "badge").visible)
      saved.clear()
      clickItem("button-finish")
      compare(saved.count, 0)
      waitForCelebration()
      compare(saved.count, 1)
      compare(saved.signalArguments[0][0].completed, [0])
      compare(saved.signalArguments[0][0].codename, "Zero")
      compare(saved.signalArguments[0][0].current, null)
      verify(view.finishedAll)
      verify(findChild(view, "comingSoon").visible)
    }

    function test_enter_starts_without_the_mouse() {
      keyClick(Qt.Key_Return)
      verify(view.celebrating)
    }

    function test_fixed_name_stays_and_celebrates_before_moving_on() {
      clickItem("button-accept")
      waitForCelebration()
      for (var i = 0; i < 3; i++) keyClick(Qt.Key_Backspace)
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
      var w = view.implicitWidth, h = view.implicitHeight
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
      verify(view.finishedAll)
    }

    function test_settings_skip_and_reset() {
      clickItem("settingsButton")
      verify(findChild(view, "settings").visible)
      clickItem("settings-skip")
      compare(saved.signalArguments[0][0].completed, [0])
      verify(view.finishedAll)

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
