import QtQuick
import QtTest
import "../components"
import "../Engine.js" as Engine

Item {
  width: 900
  height: 760

  MissionView {
    id: view
    anchors.fill: parent
    hintClock: false
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
      wait(0)
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

    function test_mission_zero_end_to_end() {
      compare(view.session.step, 0)
      clickItem("button-accept")
      compare(view.session.step, 1)
      compare(findChild(view, "field").text, "BOLTTTT")
      keyClick(Qt.Key_Backspace)
      keyClick(Qt.Key_Backspace)
      compare(findChild(view, "field").text, "BOLTT")
      keyClick(Qt.Key_Backspace)
      compare(view.session.step, 2)
      wait(0)
      verify(findChild(view, "codenameInput").activeFocus)
      typeText("Zero")
      keyClick(Qt.Key_Return)
      compare(view.session.step, 3)
      verify(findChild(view, "lines").text.indexOf("Welcome to the Academy, Zero.") !== -1)
      verify(findChild(view, "badge").visible)
      clickItem("button-finish")
      compare(saved.count, 1)
      compare(saved.signalArguments[0][0].completed, [0])
      compare(saved.signalArguments[0][0].codename, "Zero")
      verify(view.finishedAll)
      verify(findChild(view, "comingSoon").visible)
    }

    function test_an_empty_codename_is_not_accepted() {
      view.session = { mission: 0, step: 2, count: 0, idleMs: 0, hint: 0, codename: "", done: false }
      view.focusTask()
      wait(0)
      keyClick(Qt.Key_Return)
      compare(view.session.step, 2)
    }

    function test_after_the_codename_step_keys_come_back_to_the_mission() {
      view.session = { mission: 0, step: 2, count: 0, idleMs: 0, hint: 0, codename: "", done: false }
      view.focusTask()
      wait(20)
      verify(findChild(view, "codenameInput").activeFocus)
      typeText("Zero")
      keyClick(Qt.Key_Return)
      wait(20)
      verify(!findChild(view, "codenameInput").activeFocus)
      verify(view.activeFocus)
    }

    function test_help_grows_bolt_then_keys_then_demo() {
      clickItem("button-accept")
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

    function test_continues_at_the_next_unfinished_mission() {
      view.progress = { version: 1, codename: "Zero", completed: [0] }
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
