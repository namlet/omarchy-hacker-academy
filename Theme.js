// Colors: the screen's palette from the Omarchy theme, and the sprites' colors for the
// "character colors" setting. No Quickshell, so it runs under Node tests too.

// The roles the screens draw with. The panel fills them from the theme; these are
// stand-ins for tests and previews (Tokyo Night).
var DEFAULT_PALETTE = {
  ground: "#1a1b26",   // the window
  bars: "#13141c",     // title bar and key bar
  field: "#16161e",    // the task's play area, a shade darker than the ground
  line: "#414868",     // box borders
  text: "#c0caf5",     // what to read
  quiet: "#a9b1d6",    // labels and secondary text
  faint: "#565f89",    // locked things
  accent: "#7aa2f7",   // the live task
  done: "#9ece6a",     // finished missions and steps
  rank: "#e0af68",     // rank-up moments only
  danger: "#f7768e",
  magenta: "#bb9af7",
  cyan: "#0db9d7"
}

function hex(n) { return ("0" + Math.round(Math.max(0, Math.min(255, n))).toString(16)).slice(-2) }

// Blend two "#rrggbb" colors: t = 0 gives a, t = 1 gives b.
function mix(a, b, t) {
  var out = "#"
  for (var i = 1; i < 7; i += 2) {
    var x = parseInt(a.substr(i, 2), 16), y = parseInt(b.substr(i, 2), 16)
    out += hex(x + (y - x) * t)
  }
  return out
}

// Lighter toward white for amount > 0, darker toward black for amount < 0.
function shade(color, amount) {
  return amount >= 0 ? mix(color, "#ffffff", amount) : mix(color, "#000000", -amount)
}

// The "name = \"#rrggbb\"" lines of a theme's colors.toml.
function parseColors(text) {
  var colors = {}
  String(text || "").split("\n").forEach(function(line) {
    var m = line.match(/^\s*([A-Za-z0-9_]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
    if (m) colors[m[1]] = m[2].toLowerCase()
  })
  return colors
}

// The screen's palette. `base` is what Omarchy's shell already knows (background,
// foreground, accent, urgent, muted); `colors` adds the rest of the theme when it has it.
function palette(colors, base) {
  var c = colors || {}
  var ground = c.background || base.background
  var text = c.bright_foreground || base.foreground
  return {
    ground: ground,
    bars: c.dark_background || shade(ground, -0.3),
    field: mix(ground, c.dark_background || shade(ground, -0.3), 0.5),
    line: base.muted,
    text: text,
    quiet: c.foreground || base.foreground,
    faint: c.dark_foreground || mix(text, ground, 0.6),
    accent: base.accent,
    done: c.green || base.accent,
    rank: c.yellow || base.accent,
    danger: c.red || base.urgent,
    magenta: c.magenta || base.accent,
    cyan: c.bright_cyan || c.cyan || base.accent
  }
}

// A sprite's colors, letter by letter: its own 8-bit colors ("classic"), or with the
// letters it marks as themed taken from the palette ("theme").
function spriteColors(sprite, pal, mode) {
  var colors = {}
  for (var k in sprite.pal) colors[k] = sprite.pal[k]
  if (mode === "theme" && pal) {
    for (var ch in sprite.themed) {
      var role = sprite.themed[ch]
      if (pal[role[0]]) colors[ch] = shade(String(pal[role[0]]), role[1])
    }
  }
  return colors
}

if (typeof module !== "undefined") {
  module.exports = { DEFAULT_PALETTE: DEFAULT_PALETTE, mix: mix, shade: shade, parseColors: parseColors, palette: palette, spriteColors: spriteColors }
}
