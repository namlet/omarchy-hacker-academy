pragma ComponentBehavior: Bound

import QtQuick
import "../Theme.js" as Theme

// Every mission of the part, grouped by rank: done, being played, or locked.
// `ranks` comes from Engine.campaignView. Compact (desktop missions) draws thin bars
// with no numbers or names.
Item {
  id: root

  property var ranks: []
  property bool compact: false
  property var theme: Theme.DEFAULT_PALETTE
  property string fontFamily: "monospace"
  property real fontSize: 16

  readonly property int count: root.ranks.reduce(function(n, r) { return n + r.missions.length }, 0)
  readonly property real gap: root.fontSize * (root.compact ? 0.2 : 0.35)
  readonly property real groupGap: root.fontSize * (root.compact ? 0.6 : 0.9)
  readonly property real cellWidth: root.count > 0
    ? (root.width - (root.count - root.ranks.length) * root.gap - (root.ranks.length - 1) * root.groupGap) / root.count : 0

  implicitHeight: root.compact ? root.fontSize * 0.5 : root.fontSize * 3

  Row {
    spacing: root.groupGap

    Repeater {
      model: root.ranks

      Column {
        id: group
        required property var modelData
        objectName: "rank-" + group.modelData.name
        spacing: root.fontSize * 0.45

        Row {
          visible: !root.compact
          spacing: root.fontSize * 0.5
          width: cells.width

          Text {
            id: rankName
            text: group.modelData.name.toUpperCase()
            color: group.modelData.earned ? root.theme.done : root.theme.quiet
            font.family: root.fontFamily
            font.pixelSize: root.fontSize * 0.68
            font.letterSpacing: root.fontSize * 0.1
            font.bold: true
          }

          Rectangle {
            anchors.verticalCenter: rankName.verticalCenter
            width: Math.max(0, cells.width - rankName.width - root.fontSize * 0.5)
            height: 1
            color: group.modelData.earned ? root.theme.done : root.theme.line
          }
        }

        Row {
          id: cells
          spacing: root.gap

          Repeater {
            model: group.modelData.missions

            Rectangle {
              id: cell
              required property var modelData
              objectName: "mission-" + cell.modelData.number
              readonly property string missionState: cell.modelData.state
              width: root.cellWidth
              height: root.compact ? root.fontSize * 0.5 : root.fontSize * 1.8
              color: cell.missionState === "done" ? root.theme.done : cell.missionState === "now" ? Theme.mix(String(root.theme.ground), String(root.theme.accent), 0.15) : "transparent"
              border.width: 1
              border.color: cell.missionState === "done" ? root.theme.done : cell.missionState === "now" ? root.theme.accent : root.theme.line

              Text {
                visible: !root.compact
                anchors.centerIn: parent
                text: (cell.modelData.number < 10 ? "0" : "") + cell.modelData.number
                color: cell.missionState === "done" ? root.theme.bars : cell.missionState === "now" ? root.theme.accent : root.theme.faint
                font.family: root.fontFamily
                font.pixelSize: root.fontSize * 0.8
                font.bold: true
              }
            }
          }
        }
      }
    }
  }
}
