pragma ComponentBehavior: Bound

import QtQuick

// A picture of the keyboard. Keys in `pressed` fill in; keys in `lit` glow as a hint.
// Labels match Model.keyLabel(), so Super is printed "Win".
Item {
  id: root

  property var pressed: []
  property var lit: []
  property color textColor: "white"
  property color dimColor: "gray"
  property color accentColor: "orange"
  property color pressedTextColor: "black"
  property string fontFamily: "monospace"
  property real unit: 28

  readonly property var rows: [
    [["Esc", 1], ["1", 1], ["2", 1], ["3", 1], ["4", 1], ["5", 1], ["6", 1], ["7", 1], ["8", 1], ["9", 1], ["0", 1], ["Backspace", 2]],
    [["Tab", 1.5], ["Q", 1], ["W", 1], ["E", 1], ["R", 1], ["T", 1], ["Y", 1], ["U", 1], ["I", 1], ["O", 1], ["P", 1.5]],
    [["Caps", 1.75], ["A", 1], ["S", 1], ["D", 1], ["F", 1], ["G", 1], ["H", 1], ["J", 1], ["K", 1], ["L", 1], ["Enter", 2.25]],
    [["Shift", 2.25], ["Z", 1], ["X", 1], ["C", 1], ["V", 1], ["B", 1], ["N", 1], ["M", 1], ["Shift", 2.75]],
    [["Ctrl", 1.5], ["Win", 1.5], ["Alt", 1.5], ["Space", 5.5], ["Alt", 1.5], ["Ctrl", 1.5]]
  ]
  readonly property real gap: root.unit * 0.12

  function isPressed(label) { return root.pressed.indexOf(label) !== -1 }
  function isLit(label) { return root.lit.indexOf(label) !== -1 }

  implicitWidth: 13 * root.unit + 12 * root.gap
  implicitHeight: 5 * root.unit + 4 * root.gap

  Column {
    spacing: root.gap

    Repeater {
      model: root.rows

      Row {
        id: keyRow
        required property var modelData
        spacing: root.gap

        Repeater {
          model: keyRow.modelData

          Rectangle {
            id: key
            required property var modelData
            readonly property string label: key.modelData[0]
            readonly property bool down: root.isPressed(key.label)
            readonly property bool hinted: root.isLit(key.label)

            objectName: "key-" + key.label
            width: key.modelData[1] * root.unit + (key.modelData[1] - 1) * root.gap
            height: root.unit
            radius: root.unit * 0.06
            color: key.down ? root.accentColor : "transparent"
            border.color: key.hinted || key.down ? root.accentColor : root.dimColor
            border.width: key.hinted ? 3 : 1

            Text {
              anchors.centerIn: parent
              text: key.label
              color: key.down ? root.pressedTextColor : (key.hinted ? root.accentColor : root.textColor)
              font.family: root.fontFamily
              font.pixelSize: root.unit * 0.36
              font.bold: key.hinted
            }
          }
        }
      }
    }
  }
}
