import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import "components"
import "Model.js" as Model

// Shell adapter: opens the coach panel and forwards Hyprland events.
// No lesson logic here — it lives in Model.js and components/ where it is tested.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string lastWindow: ""

  function open(payloadJson) {
    root.opened = true
    // The window maps after open() returns; take keyboard focus once it exists.
    Qt.callLater(function() {
      if (root.opened) trainer.forceActiveFocus()
    })
  }

  function close() {
    root.opened = false
    root.lastWindow = ""
  }

  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.namlet.hacker-academy")
    else close()
  }

  Connections {
    target: Hyprland
    enabled: root.opened

    function onRawEvent(event) {
      var info = Model.parseOpenWindow(event)
      if (info) root.lastWindow = Model.appLabel(info)
    }
  }

  PanelWindow {
    visible: root.opened
    anchors { bottom: true; right: true }
    margins { bottom: Style.space(24); right: Style.space(24) }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hacker-academy"
    WlrLayershell.layer: WlrLayer.Top
    // On demand: the coach takes keys when clicked, and real windows keep working.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
      id: card
      anchors.fill: parent
      implicitWidth: content.implicitWidth + Style.space(48)
      implicitHeight: content.implicitHeight + Style.space(48)
      radius: Style.cornerRadius
      color: Color.popups.background
      border.color: Color.popups.border
      border.width: 2

      MouseArea {
        anchors.fill: parent
        onClicked: trainer.forceActiveFocus()
      }

      ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: Style.space(16)

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "HACKER ACADEMY"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        KeyTrainer {
          id: trainer
          Layout.alignment: Qt.AlignHCenter
          textColor: Color.popups.text
          dimColor: Color.muted
          accentColor: Color.accent
          fontFamily: Style.font.family
          fontSize: Style.font.body
          onExitRequested: root.dismiss()
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.lastWindow ? "You opened " + root.lastWindow + "!" : "Open any window to see it here"
          color: root.lastWindow ? Color.accent : Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "Esc or click here to close"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismiss()
          }
        }
      }
    }
  }
}
