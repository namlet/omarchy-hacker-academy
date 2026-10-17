// Pixel art, drawn as text so it is easy to edit and review. Each character is one
// pixel, named by its role so the art takes the colors of the Omarchy theme:
//   o  line        the theme's text color (outlines, the Mentor's white hat)
//   b  bolt        Bolt's color
//   a  accent      the theme's accent
//   d  dim         the theme's muted color
//   k  background  the panel's background (eyes, sunglasses)
//   .  nothing     see-through
// See them all with `make preview`.

var ROLES = { o: "line", b: "bolt", a: "accent", d: "dim", k: "background" }

var SPRITES = {
  // Goofy robot sidekick: antenna, bolts for ears, eyes that don't agree, a big grin.
  bolt: [
    ".......aa.......",
    "......aaaa......",
    ".......oo.......",
    "...oooooooooo...",
    "..obbbbbbbbbbo..",
    "..obkkkbbkkkbo..",
    "aaobkokbbkkoboaa",
    "..obkkkbbkkkbo..",
    "..obbbbbbbbbbo..",
    "..obbkkkkkkbbo..",
    "..obbkokokkbbo..",
    "..obbbkkkkbbbo..",
    "...obbbbbbbbo...",
    "....oooooooo....",
    "......obbo......",
    "....oobbbboo...."
  ],

  // Calm, kind, a little dry: a white hat, sunglasses, a small smile.
  mentor: [
    "................",
    ".....oooooo.....",
    "....oooooooo....",
    "....aaaaaaaa....",
    "..oooooooooooo..",
    "...oddddddddo...",
    "...okkkddkkko...",
    "...odkkddkkdo...",
    "...oddddddddo...",
    "...oddddddddo...",
    "...odddkkkddo...",
    "....oddddddo....",
    ".....oddddo.....",
    "...oooaaaaooo...",
    "..ooooaaaaoooo..",
    "..oooooaaooooo.."
  ],

  bug: [
    "..o......o..",
    "...o....o...",
    "....oooo....",
    "...oaaaao...",
    "..oakaakao..",
    "..oaaaaaao..",
    ".ooaaaaaaoo.",
    "..oaaaaaao..",
    ".ooaaaaaaoo.",
    "..oaaaaaao..",
    "...oooooo...",
    "..o......o.."
  ],

  // The bug that only answers a right-click wears a bandit mask.
  sneakyBug: [
    "..o......o..",
    "...o....o...",
    "....oooo....",
    "...oaaaao...",
    "..okokkoko..",
    "..oaaaaaao..",
    ".ooaaaaaaoo.",
    "..oaaaaaao..",
    ".ooaaaaaaoo.",
    "..oaaaaaao..",
    "...oooooo...",
    "..o......o.."
  ],

  // Glass jar with a lid; the inside is see-through so the caught bug shows.
  jar: [
    "...oooooooooo...",
    "...oaaaaaaaao...",
    "...oooooooooo...",
    "....o......o....",
    "...o........o...",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "..o..........o..",
    "...o........o...",
    "....oooooooo...."
  ]
}

if (typeof module !== "undefined") {
  module.exports = { ROLES: ROLES, SPRITES: SPRITES }
}
