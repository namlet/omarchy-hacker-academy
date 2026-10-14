import QtQuick
import QtQuick.Layouts
import "../Model.js" as Model

// Shows whether Shift is being held and counts tapped keys. No Quickshell
// imports, so it runs under qmltestrunner; the panel passes in theme values.
FocusScope {
  id: root

  property color textColor: "white"
  property color dimColor: "gray"
  property color accentColor: "orange"
  property string fontFamily: "monospace"
  property int fontSize: 14

  signal exitRequested()

  property var keyState: Model.initialKeyState()
  readonly property bool shiftHeld: Model.isHeld(keyState, "shift")
  readonly property int taps: keyState.taps

  implicitWidth: column.implicitWidth
  implicitHeight: column.implicitHeight

  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_Escape) {
      root.exitRequested()
      return
    }
    root.keyState = Model.pressKey(root.keyState, event.key, event.isAutoRepeat, event.nativeScanCode)
  }
  Keys.onReleased: (event) => {
    if (!event.isAutoRepeat) root.keyState = Model.releaseKey(root.keyState, event.key, event.nativeScanCode)
  }
  // Releases of keys held when focus leaves go to another window, so let go now.
  onActiveFocusChanged: if (!activeFocus) root.keyState = Model.releaseAll(root.keyState)

  ColumnLayout {
    id: column
    anchors.fill: parent
    spacing: root.fontSize

    Rectangle {
      objectName: "shiftIndicator"
      Layout.alignment: Qt.AlignHCenter
      implicitWidth: shiftLabel.implicitWidth + root.fontSize * 2
      implicitHeight: shiftLabel.implicitHeight + root.fontSize
      radius: root.fontSize / 2
      color: root.shiftHeld ? root.accentColor : "transparent"
      border.color: root.shiftHeld ? root.accentColor : root.dimColor
      border.width: 2

      Text {
        id: shiftLabel
        anchors.centerIn: parent
        text: "SHIFT"
        color: root.shiftHeld ? "black" : root.dimColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.bold: true
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: root.shiftHeld ? "Holding Shift!" : "Hold Shift to light it up"
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }

    Text {
      objectName: "tapCount"
      Layout.alignment: Qt.AlignHCenter
      text: "Taps: " + root.taps
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }
}
