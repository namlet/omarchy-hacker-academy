import QtQuick
import "../Sprites.js" as Sprites
import "../Theme.js" as Theme

// Draws one sprite from Sprites.js with square pixels as large as fit, centered.
// Pixels land on whole screen pixels so edges stay crisp. `mode` is the character
// colors setting: "classic" keeps the sprite's own colors, "theme" follows `theme`.
// A `flat` color draws the whole sprite in that one color (locked badges).
Item {
  id: root

  property string sprite: ""
  property var theme: Theme.DEFAULT_PALETTE
  property string mode: "classic"
  property color flat: "transparent"

  readonly property var rows: Sprites.SPRITES[root.sprite] ? Sprites.SPRITES[root.sprite].rows : []
  readonly property int columns: root.rows.length > 0 ? root.rows[0].length : 0
  readonly property int pixel: root.columns > 0
    ? Math.max(1, Math.floor(Math.min(root.width / root.columns, root.height / root.rows.length))) : 1
  readonly property var pixelColors: Sprites.SPRITES[root.sprite]
    ? Theme.spriteColors(Sprites.SPRITES[root.sprite], root.theme, root.mode) : ({})

  implicitWidth: root.columns * 4
  implicitHeight: root.rows.length * 4

  onPixelColorsChanged: canvas.requestPaint()
  onPixelChanged: canvas.requestPaint()
  onFlatChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.centerIn: parent
    width: root.columns * root.pixel
    height: root.rows.length * root.pixel

    onPaint: {
      const ctx = canvas.getContext("2d")
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      const flat = root.flat.a > 0 ? String(root.flat) : ""
      for (let y = 0; y < root.rows.length; y++) {
        for (let x = 0; x < root.columns; x++) {
          const color = root.pixelColors[root.rows[y].charAt(x)]
          if (!color) continue
          ctx.fillStyle = flat || color
          ctx.fillRect(x * root.pixel, y * root.pixel, root.pixel, root.pixel)
        }
      }
    }
  }
}
