pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../Sprites.js" as Sprites
import "../Theme.js" as Theme

// Every sprite at two sizes, on a dark and a light theme, in its own colors and
// matching the theme, for checking the art.
//   make preview              opens a window
//   make preview PNG=out.png  saves a picture instead
Rectangle {
  id: root

  readonly property var themes: [
    { name: "dark, classic", mode: "classic", palette: Theme.DEFAULT_PALETTE },
    { name: "dark, match theme", mode: "theme", palette: Theme.palette({ green: "#9ece6a", yellow: "#ff9e64", red: "#f7768e", magenta: "#bb9af7", cyan: "#7dcfff" },
      { background: "#1a1b26", foreground: "#c0caf5", accent: "#bb9af7", urgent: "#f7768e", muted: "#414868" }) },
    { name: "light, classic", mode: "classic", palette: Theme.palette({}, { background: "#f5f5f0", foreground: "#1f2335", accent: "#2e7de9", urgent: "#c64343", muted: "#a8aecb" }) },
    { name: "light, match theme", mode: "theme", palette: Theme.palette({ green: "#587539", yellow: "#b15c00", magenta: "#9854f1", cyan: "#007197" },
      { background: "#f5f5f0", foreground: "#1f2335", accent: "#2e7de9", urgent: "#c64343", muted: "#a8aecb" }) }
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
        color: themeRow.modelData.palette.ground

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
                  model: [3, 6]
                  PixelSprite {
                    required property int modelData
                    sprite: spriteColumn.modelData
                    width: implicitWidth / 4 * modelData
                    height: implicitHeight / 4 * modelData
                    theme: themeRow.modelData.palette
                    mode: themeRow.modelData.mode
                  }
                }
              }

              Text {
                text: spriteColumn.modelData
                color: themeRow.modelData.palette.text
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
