pragma ComponentBehavior: Bound

import QtQuick
import "../Sprites.js" as Sprites
import "../Theme.js" as Theme

// The rank-up moment: the new badge in a gold frame, the rank's name, what changed,
// and the ranks so far. Compact for the small desktop-mission window.
Item {
  id: root

  property string rank: ""
  property string previousRank: ""
  property int level: 1
  property var rankNames: []
  property string line: ""
  property var unlocks: []
  property string buttonId: ""
  property string buttonLabel: ""
  property bool celebrating: false
  property bool compact: false
  property string rankUpLabel: "Rank up"
  property string unlockedLabel: "Unlocked"
  property var theme: Theme.DEFAULT_PALETTE
  property string mode: "classic"
  property string fontFamily: "monospace"
  property real fontSize: 16

  signal pressed()

  readonly property real f: root.fontSize

  Row {
    anchors.centerIn: parent
    spacing: root.f * (root.compact ? 1.2 : 3.2)

    // The badge, framed by gold corners.
    Item {
      id: frame
      anchors.verticalCenter: parent.verticalCenter
      width: root.f * (root.compact ? 7.5 : 15)
      height: root.f * (root.compact ? 8.5 : 17)

      Rectangle { anchors.fill: parent; color: root.theme.field; border.color: root.theme.line; border.width: 1 }
      Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]
        Item {
          id: corner
          required property var modelData
          readonly property real size: root.f * 1.1
          x: corner.modelData[0] * (frame.width - corner.size)
          y: corner.modelData[1] * (frame.height - corner.size)
          width: corner.size
          height: corner.size
          Rectangle { width: parent.width; height: 3; y: corner.modelData[1] * (parent.height - 3); color: root.theme.rank }
          Rectangle { width: 3; height: parent.height; x: corner.modelData[0] * (parent.width - 3); color: root.theme.rank }
        }
      }

      PixelSprite {
        id: badgeSprite
        objectName: "rankBadge"
        anchors.centerIn: parent
        width: parent.width * 0.78
        height: parent.height * 0.78
        sprite: Sprites.BADGES[root.rank] || ""
        theme: root.theme
        mode: root.mode

        SequentialAnimation on scale {
          running: root.celebrating
          loops: Animation.Infinite
          onStopped: badgeSprite.scale = 1
          NumberAnimation { to: 1.08; duration: 300; easing.type: Easing.OutQuad }
          NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.InQuad }
        }
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: root.compact ? root.width - frame.width - root.f * 1.2 : root.f * 24
      spacing: root.f * (root.compact ? 0.5 : 1.1)

      Text {
        text: root.rankUpLabel.toUpperCase()
        color: root.theme.rank
        font.family: root.fontFamily
        font.pixelSize: root.f * 0.8
        font.letterSpacing: root.f * 0.3
        font.bold: true
      }

      Column {
        spacing: root.f * 0.3

        Text {
          objectName: "rankName"
          text: root.rank.toUpperCase()
          color: root.theme.text
          font.family: root.fontFamily
          font.pixelSize: root.f * (root.compact ? 2.3 : 4.4)
          font.weight: Font.Black
          font.letterSpacing: root.f * 0.1
        }

        Text {
          visible: root.previousRank !== "" && !root.compact
          text: root.previousRank.toUpperCase() + "  ────▶  " + root.rank.toUpperCase()
          color: root.theme.quiet
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.9
        }
      }

      Text {
        objectName: "rankLine"
        width: parent.width
        text: root.line
        color: root.theme.text
        font.family: root.fontFamily
        font.pixelSize: root.f * (root.compact ? 0.95 : 1.15)
        wrapMode: Text.Wrap
      }

      Box {
        visible: !root.compact
        width: parent.width
        height: unlockList.implicitHeight + root.f * 2
        label: root.unlockedLabel
        labelColor: root.theme.quiet
        lineColor: root.theme.line
        ground: root.theme.ground
        fontFamily: root.fontFamily
        fontSize: root.f

        Column {
          id: unlockList
          spacing: root.f * 0.3
          Repeater {
            model: root.unlocks
            Text {
              required property string modelData
              text: "<font color=\"" + root.theme.done + "\">+</font> " + modelData
              textFormat: Text.StyledText
              color: root.theme.text
              font.family: root.fontFamily
              font.pixelSize: root.f * 0.9
            }
          }
        }
      }

      Row {
        visible: !root.compact
        spacing: root.f * 0.5
        Repeater {
          model: root.rankNames
          Rectangle {
            id: chip
            required property string modelData
            required property int index
            readonly property bool held: chip.index < root.level - 1
            readonly property bool isNew: chip.index === root.level - 1
            width: chipText.implicitWidth + root.f
            height: root.f * 1.7
            color: chip.isNew ? root.theme.rank : "transparent"
            border.width: 1
            border.color: chip.isNew ? root.theme.rank : chip.held ? root.theme.done : root.theme.line

            Text {
              id: chipText
              anchors.centerIn: parent
              text: chip.modelData.toUpperCase()
              color: chip.isNew ? root.theme.bars : chip.held ? root.theme.done : root.theme.faint
              font.family: root.fontFamily
              font.pixelSize: root.f * 0.7
              font.bold: true
              font.letterSpacing: root.f * 0.08
            }
          }
        }
      }

      Rectangle {
        objectName: "button-" + root.buttonId
        width: buttonText.implicitWidth + root.f * 2.4
        height: Math.max(44, root.f * 2.5)
        color: buttonArea.containsMouse || root.celebrating ? Theme.shade(String(root.theme.rank), 0.25) : root.theme.rank

        Text {
          id: buttonText
          anchors.centerIn: parent
          text: root.buttonLabel.toUpperCase()
          color: root.theme.bars
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.9
          font.bold: true
          font.letterSpacing: root.f * 0.08
        }

        MouseArea {
          id: buttonArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.pressed()
        }
      }
    }
  }
}
