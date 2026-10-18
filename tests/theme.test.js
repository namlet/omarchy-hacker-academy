const { test } = require("node:test")
const assert = require("node:assert/strict")
const Theme = require("../Theme.js")
const { SPRITES } = require("../Sprites.js")

const BASE = { background: "#101010", foreground: "#d0d0d0", accent: "#3388ff", urgent: "#ff3333", muted: "#505050" }

test("theme colors are read from colors.toml", () => {
  const colors = Theme.parseColors('mode = "dark"\naccent = "#7AA2F7"\n# green = "#000000"\ngreen = "#9ece6a"\nbad = "blue"\n')
  assert.deepEqual(colors, { accent: "#7aa2f7", green: "#9ece6a" })
})

test("the palette uses the theme's own colors when it has them", () => {
  const p = Theme.palette({ background: "#1a1b26", dark_background: "#13141c", green: "#9ece6a", yellow: "#e0af68" }, BASE)
  assert.deepEqual([p.ground, p.bars, p.done, p.rank, p.accent], ["#1a1b26", "#13141c", "#9ece6a", "#e0af68", "#3388ff"])
})

test("a theme with only the basics still gets every role", () => {
  const p = Theme.palette({}, BASE)
  for (const role of Object.keys(Theme.DEFAULT_PALETTE)) assert.match(String(p[role]), /^#[0-9a-f]{6}$/, role)
  assert.equal(p.done, BASE.accent)
  assert.equal(p.danger, BASE.urgent)
  assert.notEqual(p.bars, p.ground, "the bars are a shade darker")
})

test("mixing and shading colors", () => {
  assert.equal(Theme.mix("#000000", "#ffffff", 0.5), "#808080")
  assert.equal(Theme.shade("#808080", 1), "#ffffff")
  assert.equal(Theme.shade("#808080", -1), "#000000")
})

test("classic sprites keep their own colors; matching the theme swaps the themed ones", () => {
  const bolt = SPRITES.bolt
  const pal = Object.assign({}, Theme.DEFAULT_PALETTE, { accent: "#ff0000" })
  assert.deepEqual(Theme.spriteColors(bolt, pal, "classic"), bolt.pal)
  const themed = Theme.spriteColors(bolt, pal, "theme")
  assert.equal(themed.B, "#ff0000", "Bolt's body is the accent")
  assert.equal(themed.b, Theme.shade("#ff0000", -0.4), "its shading follows")
  assert.equal(themed.K, bolt.pal.K, "outlines stay")
})
