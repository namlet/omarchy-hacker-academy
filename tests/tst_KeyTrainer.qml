import QtQuick
import QtTest
import "../components"
import "../Model.js" as Model

Item {
  width: 300
  height: 200

  KeyTrainer {
    id: trainer
    anchors.fill: parent
  }

  Item {
    id: elsewhere
  }

  TestCase {
    name: "KeyTrainer"
    when: windowShown

    function init() {
      trainer.keyState = Model.initialKeyState()
      trainer.forceActiveFocus()
    }

    function test_shift_lights_only_while_held() {
      verify(!trainer.shiftHeld)
      keyPress(Qt.Key_Shift)
      verify(trainer.shiftHeld)
      keyRelease(Qt.Key_Shift)
      verify(!trainer.shiftHeld)
    }

    function test_each_letter_tap_counts_once() {
      keyClick(Qt.Key_A)
      keyClick(Qt.Key_B)
      compare(trainer.taps, 2)
    }

    function test_tapping_while_holding_shift() {
      keyPress(Qt.Key_Shift)
      keyClick(Qt.Key_A)
      verify(trainer.shiftHeld)
      compare(trainer.taps, 1)
      keyRelease(Qt.Key_Shift)
      verify(!trainer.shiftHeld)
    }

    SignalSpy {
      id: exitSpy
      target: trainer
      signalName: "exitRequested"
    }

    function test_escape_asks_to_exit_and_is_not_a_tap() {
      exitSpy.clear()
      keyClick(Qt.Key_Escape)
      compare(exitSpy.count, 1)
      compare(trainer.taps, 0)
    }

    function test_losing_focus_lets_go_of_shift() {
      keyPress(Qt.Key_Shift)
      verify(trainer.shiftHeld)
      elsewhere.forceActiveFocus()
      verify(!trainer.shiftHeld)
    }

    function test_hold_keys_are_not_taps() {
      keyClick(Qt.Key_Control)
      keyClick(Qt.Key_Alt)
      compare(trainer.taps, 0)
    }
  }
}
