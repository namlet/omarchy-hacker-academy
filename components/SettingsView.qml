pragma ComponentBehavior: Bound

import QtQuick
import "../Theme.js" as Theme

// Settings, for grown-ups: one row per choice, each with what it does and its
// control on the right. Resetting asks twice. Rows are named settings-<id> and
// clicking anywhere on a row does what its control does.
Item {
  id: root

  // "Mission 02: Force Fields", or "" when there's no mission left to skip.
  property string missionName: ""
  property string characterColors: "classic"
  property bool confirmingReset: false
  // The small desktop-mission window: one line per row, no explanations.
  property bool compact: false
  property var theme: Theme.DEFAULT_PALETTE
  property string fontFamily: "monospace"
  property real fontSize: 16

  signal skip()
  signal toggleColors()
  signal reset()
  signal back()

  readonly property real f: root.fontSize

  // A small square-cornered button.
  component Chip: Rectangle {
    id: chip
    property string text: ""
    property color tint: root.theme.accent
    property bool filled: false
    width: chipText.implicitWidth + root.f * 1.6
    height: root.f * 1.9
    color: chip.filled ? chip.tint : "transparent"
    border.width: 1
    border.color: chip.tint

    Text {
      id: chipText
      anchors.centerIn: parent
      text: chip.text
      color: chip.filled ? root.theme.bars : chip.tint
      font.family: root.fontFamily
      font.pixelSize: root.f * 0.75
      font.bold: true
      font.letterSpacing: root.f * 0.1
    }
  }

  // One choice: a name, what it does, and a control on the right.
  component SettingRow: Item {
    id: row
    property string name: ""
    property color nameColor: root.theme.text
    property string detail: ""
    property color detailColor: root.theme.quiet
    default property alias control: controlSlot.data
    signal activated()
    width: parent ? parent.width : 0
    height: root.f * (root.compact ? 2.7 : 3.8)

    Rectangle {
      anchors.fill: parent
      color: rowArea.containsMouse ? Theme.mix(String(root.theme.field), String(root.theme.accent), 0.08) : "transparent"
    }

    // A bar marks the row under the pointer, like a cursor in a terminal menu.
    Rectangle {
      width: root.f * 0.2
      height: parent.height
      color: root.theme.accent
      visible: rowArea.containsMouse
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: root.f * 0.9
      anchors.right: controlSlot.left
      anchors.rightMargin: root.f
      anchors.verticalCenter: parent.verticalCenter
      spacing: root.f * 0.2

      Text {
        text: row.name
        color: row.nameColor
        font.family: root.fontFamily
        font.pixelSize: root.f
        font.bold: true
      }

      Text {
        visible: !root.compact
        width: parent.width
        text: row.detail
        color: row.detailColor
        font.family: root.fontFamily
        font.pixelSize: root.f * 0.78
        wrapMode: Text.Wrap
      }
    }

    Item {
      id: controlSlot
      anchors.right: parent.right
      anchors.rightMargin: root.f * 0.6
      anchors.verticalCenter: parent.verticalCenter
      width: childrenRect.width
      height: childrenRect.height
    }

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.theme.line }

    MouseArea {
      id: rowArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row.activated()
    }
  }

  Box {
    anchors.fill: parent
    label: "Settings · for grown-ups"
    labelColor: root.theme.accent
    lineColor: root.theme.line
    ground: root.theme.ground
    boldLabel: true
    fontFamily: root.fontFamily
    fontSize: root.f

    Column {
      id: rows
      width: parent.width

      SettingRow {
        objectName: "settings-skip"
        visible: root.missionName !== ""
        name: "Skip this mission"
        detail: "Mark " + root.missionName + " as done and move on."
        onActivated: root.skip()

        Chip { text: "SKIP" }
      }

      SettingRow {
        objectName: "settings-colors"
        name: "Character colors"
        detail: root.characterColors === "theme"
          ? "The characters match the Omarchy theme's colors."
          : "The characters keep their own 8-bit colors."
        onActivated: root.toggleColors()

        Row {
          spacing: root.f * 0.6

          PixelSprite {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            width: root.f * 3.2
            height: root.f * 3.2
            sprite: "bolt"
            theme: root.theme
            mode: root.characterColors
          }

          Row {
            anchors.verticalCenter: parent.verticalCenter
            Chip { objectName: "colors-classic"; text: "CLASSIC"; filled: root.characterColors === "classic" }
            Chip { objectName: "colors-theme"; text: "THEME"; filled: root.characterColors === "theme" }
          }
        }
      }

      SettingRow {
        objectName: "settings-reset"
        name: root.compact && root.confirmingReset ? "Click again to erase all" : "Reset all progress"
        nameColor: root.confirmingReset ? root.theme.danger : root.theme.text
        detail: root.confirmingReset
          ? "Click again to erase everything. This can't be undone."
          : "Erase missions, codename, and badges. Settings stay."
        detailColor: root.confirmingReset ? root.theme.danger : root.theme.quiet
        onActivated: root.reset()

        Chip { text: root.confirmingReset ? "CONFIRM" : "RESET"; tint: root.theme.danger; filled: root.confirmingReset }
      }
    }

    Rectangle {
      objectName: "settings-back"
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: backText.implicitWidth + root.f * 1.6
      height: Math.max(44, root.f * 2.4)
      color: backArea.containsMouse ? root.theme.accent : "transparent"
      border.width: 1
      border.color: root.theme.accent

      Text {
        id: backText
        anchors.centerIn: parent
        text: root.missionName !== "" ? "◀ BACK TO THE MISSION" : "◀ BACK"
        color: backArea.containsMouse ? root.theme.bars : root.theme.accent
        font.family: root.fontFamily
        font.pixelSize: root.f * 0.8
        font.bold: true
        font.letterSpacing: root.f * 0.08
      }

      MouseArea {
        id: backArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.back()
      }
    }
  }
}
