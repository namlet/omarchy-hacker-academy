import QtQuick
import QtTest
import "../components"
import "../Theme.js" as Theme

Item {
  width: 300
  height: 300

  Rectangle {
    id: backdrop
    width: sprite.width
    height: sprite.height
    color: "#00ff00"
  }

  PixelSprite {
    id: sprite
    sprite: "bolt"
    width: 96
    height: 120
  }

  TestCase {
    name: "PixelSprite"
    when: windowShown

    function init() {
      sprite.mode = "classic"
      sprite.theme = Theme.DEFAULT_PALETTE
      sprite.flat = "transparent"
      wait(50)
    }

    function colorAt(image, col, row) {
      // The centre of one sprite pixel, in item coordinates.
      const left = (sprite.width - sprite.columns * sprite.pixel) / 2
      const top = (sprite.height - sprite.rows.length * sprite.pixel) / 2
      return String(image.pixel(left + (col + 0.5) * sprite.pixel, top + (row + 0.5) * sprite.pixel))
    }

    function test_pixels_are_whole_squares_that_fit() {
      compare(sprite.columns, 24)
      compare(sprite.pixel, 4)
    }

    function test_classic_keeps_the_sprites_own_colors() {
      const image = grabImage(sprite)
      compare(colorAt(image, 11, 0), "#e0af68", "antenna tip")
      compare(colorAt(image, 6, 6), "#7dcfff", "Bolt's face")
      compare(colorAt(image, 3, 6), "#0e0e14", "outline")
    }

    function test_matching_the_theme_recolors_bolt() {
      sprite.theme = Object.assign({}, Theme.DEFAULT_PALETTE, { accent: "#ff0000", rank: "#00ff00" })
      sprite.mode = "theme"
      wait(50)
      const image = grabImage(sprite)
      compare(colorAt(image, 6, 6), "#ff0000", "the face follows the accent")
      compare(colorAt(image, 11, 0), "#00ff00", "the antenna follows the rank color")
      compare(colorAt(image, 3, 6), "#0e0e14", "outlines stay dark")
    }

    function test_a_flat_color_paints_the_whole_shape() {
      sprite.flat = "#123456"
      wait(50)
      const image = grabImage(sprite)
      compare(colorAt(image, 6, 6), "#123456")
      compare(colorAt(image, 3, 6), "#123456")
    }

    function test_see_through_pixels_stay_empty() {
      // Grab the window, so whatever is behind the sprite is included.
      const image = grabImage(backdrop.parent)
      compare(colorAt(image, 0, 0), "#00ff00", "the backdrop shows through")
    }
  }
}
