const { test } = require("node:test")
const assert = require("node:assert/strict")
const { ROLES, SPRITES } = require("../Sprites.js")

test("every sprite is a rectangle of known pixels", () => {
  for (const [name, rows] of Object.entries(SPRITES)) {
    assert.ok(rows.length > 0, name)
    for (const row of rows) {
      assert.equal(row.length, rows[0].length, `${name}: "${row}" is the wrong width`)
      for (const ch of row) assert.ok(ch === "." || ch in ROLES, `${name}: unknown pixel "${ch}"`)
    }
  }
})

test("the characters and targets the missions draw all have sprites", () => {
  for (const name of ["bolt", "mentor", "bug", "sneakyBug", "jar"]) assert.ok(SPRITES[name], name)
})
