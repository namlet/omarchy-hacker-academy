import QtQuick
import QtTest
import "../components"

Item {
  width: 200
  height: 200

  Rectangle {
    id: backdrop
    width: sprite.width
    height: sprite.height
    color: "#00ff00"
  }

  PixelSprite {
    id: sprite
    sprite: "bolt"
    width: 64
    height: 80
    lineColor: "#ffffff"
    boltColor: "#0000ff"
    accentColor: "#ff8000"
    backgroundColor: "#000000"
  }

  TestCase {
    name: "PixelSprite"
    when: windowShown

    function colorAt(image, col, row) {
      // The centre of one sprite pixel, in item coordinates.
      const left = (sprite.width - sprite.columns * sprite.pixel) / 2
      const top = (sprite.height - sprite.rows.length * sprite.pixel) / 2
      return image.pixel(left + (col + 0.5) * sprite.pixel, top + (row + 0.5) * sprite.pixel)
    }

    function test_pixels_are_whole_squares_that_fit() {
      compare(sprite.columns, 16)
      compare(sprite.pixel, 4)
    }

    function test_each_pixel_takes_its_role_color() {
      wait(50)
      const image = grabImage(sprite)
      compare(String(colorAt(image, 7, 0)), "#ff8000", "antenna tip is accent")
      compare(String(colorAt(image, 3, 3)), "#ffffff", "outline is the line color")
      compare(String(colorAt(image, 3, 4)), "#0000ff", "the face is Bolt's color")
      compare(String(colorAt(image, 4, 5)), "#000000", "eyes are the background")
    }

    function test_see_through_pixels_stay_empty() {
      wait(50)
      // Grab the window, so whatever is behind the sprite is included.
      const image = grabImage(backdrop.parent)
      compare(String(colorAt(image, 0, 0)), "#00ff00", "the backdrop shows through")
    }
  }
}
