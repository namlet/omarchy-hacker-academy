pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../Sprites.js" as Sprites

// Every sprite at a few sizes, on a dark and a light theme, for checking the art.
//   make preview              opens a window
//   make preview PNG=out.png  saves a picture instead
Rectangle {
  id: root

  readonly property var themes: [
    { name: "dark", background: "#1a1b26", line: "#c0caf5", bolt: "#7dcfff", accent: "#ff9e64", dim: "#565f89" },
    { name: "light", background: "#f5f5f0", line: "#1f2335", bolt: "#2e7de9", accent: "#b15c00", dim: "#8990b3" }
  ]
  readonly property string pngPath: {
    const args = Qt.application.arguments
    const i = args.indexOf("--png")
    return i !== -1 && i + 1 < args.length ? args[i + 1] : ""
  }

  width: column.width + 40
  height: column.height + 40
  color: "#808080"

  Column {
    id: column
    x: 20
    y: 20
    spacing: 20

    Repeater {
      model: root.themes

      Rectangle {
        id: themeRow
        required property var modelData
        width: row.width + 40
        height: row.height + 40
        color: themeRow.modelData.background

        Row {
          id: row
          x: 20
          y: 20
          spacing: 30

          Repeater {
            model: Object.keys(Sprites.SPRITES)

            Column {
              id: spriteColumn
              required property string modelData
              spacing: 8

              Row {
                spacing: 12
                Repeater {
                  model: [2, 4, 8]
                  PixelSprite {
                    required property int modelData
                    sprite: spriteColumn.modelData
                    width: implicitWidth / 4 * modelData
                    height: implicitHeight / 4 * modelData
                    lineColor: themeRow.modelData.line
                    boltColor: themeRow.modelData.bolt
                    accentColor: themeRow.modelData.accent
                    dimColor: themeRow.modelData.dim
                    backgroundColor: themeRow.modelData.background
                  }
                }
              }

              Text {
                text: spriteColumn.modelData
                color: themeRow.modelData.line
                font.family: "monospace"
                font.pixelSize: 14
              }
            }
          }
        }
      }
    }
  }

  Timer {
    running: root.pngPath !== ""
    interval: 300
    onTriggered: root.grabToImage(function(result) {
      result.saveToFile(root.pngPath)
      Qt.quit()
    })
  }
}
