import QtQuick
import "../Sprites.js" as Sprites

// Draws one sprite from Sprites.js in the theme's colors, with square pixels as large
// as fit, centered. Pixels land on whole screen pixels so edges stay crisp.
Item {
  id: root

  property string sprite: ""
  property color lineColor: "white"
  property color boltColor: "deepskyblue"
  property color accentColor: "orange"
  property color dimColor: "gray"
  property color backgroundColor: "black"

  readonly property var rows: Sprites.SPRITES[root.sprite] || []
  readonly property int columns: root.rows.length > 0 ? root.rows[0].length : 0
  readonly property int pixel: root.columns > 0
    ? Math.max(1, Math.floor(Math.min(root.width / root.columns, root.height / root.rows.length))) : 1

  function colorOf(ch) {
    switch (Sprites.ROLES[ch]) {
      case "line": return root.lineColor
      case "bolt": return root.boltColor
      case "accent": return root.accentColor
      case "dim": return root.dimColor
      case "background": return root.backgroundColor
      default: return null
    }
  }

  implicitWidth: root.columns * 4
  implicitHeight: root.rows.length * 4

  onRowsChanged: canvas.requestPaint()
  onPixelChanged: canvas.requestPaint()
  onLineColorChanged: canvas.requestPaint()
  onBoltColorChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()
  onDimColorChanged: canvas.requestPaint()
  onBackgroundColorChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.centerIn: parent
    width: root.columns * root.pixel
    height: root.rows.length * root.pixel

    onPaint: {
      const ctx = canvas.getContext("2d")
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      for (let y = 0; y < root.rows.length; y++) {
        for (let x = 0; x < root.columns; x++) {
          const color = root.colorOf(root.rows[y].charAt(x))
          if (color === null) continue
          ctx.fillStyle = color
          ctx.fillRect(x * root.pixel, y * root.pixel, root.pixel, root.pixel)
        }
      }
    }
  }
}
