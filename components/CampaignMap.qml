pragma ComponentBehavior: Bound

import QtQuick
import "../Sprites.js" as Sprites
import "../Theme.js" as Theme

// The whole part at a glance: missions as a tree under their ranks, the badges
// earned, and the next part waiting, locked. `ranks` comes from Engine.campaignView.
Item {
  id: root

  property var ranks: []
  property string part: ""
  property string nextPart: ""
  property string nextPartText: ""
  property string message: ""
  property string badgesLabel: "Badges"
  property string lockedLabel: "Locked"
  property var theme: Theme.DEFAULT_PALETTE
  property string mode: "classic"
  property string fontFamily: "monospace"
  property real fontSize: 16

  readonly property real f: root.fontSize
  readonly property var missions: root.ranks.reduce(function(all, r) { return all.concat(r.missions) }, [])
  readonly property int doneCount: root.missions.filter(function(m) { return m.state === "done" }).length

  Row {
    anchors.fill: parent
    spacing: root.f * 1.2

    Box {
      width: parent.width - side.width - parent.spacing
      height: parent.height
      label: root.part
      labelColor: root.theme.accent
      lineColor: root.theme.line
      ground: root.theme.ground
      boldLabel: true
      fontFamily: root.fontFamily
      fontSize: root.f

      Column {
        anchors.fill: parent
        spacing: root.f * 0.6

        Text {
          objectName: "comingSoon"
          width: parent.width
          text: root.message
          color: root.theme.text
          font.family: root.fontFamily
          font.pixelSize: root.f
          wrapMode: Text.Wrap
        }

        Row {
          width: parent.width
          spacing: root.f * 0.6

          Text {
            id: tally
            text: root.doneCount + " / " + root.missions.length
            color: root.theme.quiet
            font.family: root.fontFamily
            font.pixelSize: root.f * 0.8
          }

          Rectangle {
            anchors.verticalCenter: tally.verticalCenter
            width: parent.width - tally.width - parent.spacing
            height: root.f * 0.45
            color: root.theme.line

            Rectangle {
              width: root.missions.length > 0 ? parent.width * root.doneCount / root.missions.length : 0
              height: parent.height
              color: root.theme.done
            }
          }
        }

        // The tree: each rank, then its missions.
        Column {
          Repeater {
            model: root.ranks

            Column {
              id: rankRows
              required property var modelData
              required property int index
              readonly property bool last: rankRows.index === root.ranks.length - 1

              Text {
                text: (rankRows.last ? "└─ " : "├─ ") + rankRows.modelData.name.toUpperCase()
                color: rankRows.modelData.earned ? root.theme.done : root.theme.quiet
                font.family: root.fontFamily
                font.pixelSize: root.f * 0.9
                font.bold: true
                lineHeight: 1.35
              }

              Repeater {
                model: rankRows.modelData.missions

                Text {
                  id: missionRow
                  required property var modelData
                  readonly property string missionState: missionRow.modelData.state
                  text: (rankRows.last ? "    " : "│   ")
                    + (missionRow.missionState === "done" ? "■ " : missionRow.missionState === "now" ? "▶ " : "· ")
                    + (missionRow.modelData.number < 10 ? "0" : "") + missionRow.modelData.number + "  " + missionRow.modelData.title
                  color: missionRow.missionState === "done" ? root.theme.quiet
                    : missionRow.missionState === "now" ? root.theme.accent : root.theme.faint
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 0.9
                  font.bold: missionRow.missionState === "now"
                  lineHeight: 1.35
                }
              }
            }
          }
        }
      }
    }

    Column {
      id: side
      width: root.f * 17
      height: parent.height
      spacing: root.f * 1.2

      Box {
        width: parent.width
        height: badgeGrid.implicitHeight + root.f * 2
        label: root.badgesLabel
        labelColor: root.theme.quiet
        lineColor: root.theme.line
        ground: root.theme.ground
        fontFamily: root.fontFamily
        fontSize: root.f

        Grid {
          id: badgeGrid
          columns: 2
          spacing: root.f * 0.5

          Repeater {
            model: root.ranks

            Rectangle {
              id: badge
              required property var modelData
              objectName: "badge-" + badge.modelData.name
              width: (side.width - root.f * 2.1) / 2
              height: root.f * 2.6
              color: "transparent"
              border.width: 1
              border.color: badge.modelData.earned ? root.theme.done : root.theme.line

              Row {
                anchors.verticalCenter: parent.verticalCenter
                x: root.f * 0.4
                spacing: root.f * 0.4

                PixelSprite {
                  anchors.verticalCenter: parent.verticalCenter
                  width: root.f * 1.6
                  height: root.f * 1.7
                  sprite: Sprites.BADGES[badge.modelData.name] || ""
                  theme: root.theme
                  mode: root.mode
                  flat: badge.modelData.earned ? "transparent" : root.theme.line
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: badge.modelData.name.toUpperCase()
                  color: badge.modelData.earned ? root.theme.text : root.theme.faint
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 0.65
                  font.bold: true
                }
              }
            }
          }
        }
      }

      Box {
        width: parent.width
        height: parent.height - y
        label: root.lockedLabel
        labelColor: root.theme.quiet
        lineColor: root.theme.line
        ground: root.theme.ground
        fill: root.theme.field
        fontFamily: root.fontFamily
        fontSize: root.f

        Column {
          anchors.fill: parent
          spacing: root.f * 0.6

          Text {
            width: parent.width
            text: root.nextPart
            color: root.theme.text
            font.family: root.fontFamily
            font.pixelSize: root.f * 1.1
            font.bold: true
            wrapMode: Text.Wrap
          }

          Text {
            width: parent.width
            text: root.nextPartText
            color: root.theme.quiet
            font.family: root.fontFamily
            font.pixelSize: root.f * 0.85
            wrapMode: Text.Wrap
          }

          Text {
            text: "~ $ █"
            color: root.theme.faint
            font.family: root.fontFamily
            font.pixelSize: root.f * 0.85
          }
        }
      }
    }
  }
}
