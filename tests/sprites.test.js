const { test } = require("node:test")
const assert = require("node:assert/strict")
const { SPRITES, BADGES } = require("../Sprites.js")
const { CAMPAIGN } = require("../Missions.js")

test("every sprite is a rectangle of pixels that all have a color", () => {
  for (const [name, sprite] of Object.entries(SPRITES)) {
    assert.ok(sprite.rows.length > 0, name)
    for (const row of sprite.rows) {
      assert.equal(row.length, sprite.rows[0].length, `${name}: "${row}" is the wrong width`)
      for (const ch of row) assert.ok(ch === "." || ch in sprite.pal, `${name}: no color for "${ch}"`)
    }
  }
})

test("themed letters are ones the sprite uses, following a known theme role", () => {
  const { DEFAULT_PALETTE } = require("../Theme.js")
  for (const [name, sprite] of Object.entries(SPRITES)) {
    for (const [ch, [role, amount]] of Object.entries(sprite.themed)) {
      assert.ok(ch in sprite.pal, `${name}: themed "${ch}" isn't in its colors`)
      assert.ok(role in DEFAULT_PALETTE, `${name}: unknown role ${role}`)
      assert.ok(amount >= -1 && amount <= 1, `${name}: ${amount}`)
    }
  }
})

test("the characters, targets, and every rank's badge have sprites", () => {
  for (const name of ["bolt", "mentor", "bug", "sneakyBug", "glitch", "jar"]) assert.ok(SPRITES[name], name)
  for (const rank of CAMPAIGN.ranks) assert.ok(SPRITES[BADGES[rank.name]], rank.name)
})
