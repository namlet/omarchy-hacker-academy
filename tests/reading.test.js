// Every line a learner sees must read at a 5th-grade level (see DESIGN.md).
const { test } = require("node:test")
const assert = require("node:assert/strict")
const { MISSIONS, UI } = require("../Missions.js")

const MAX_WORDS_PER_SENTENCE = 14
const MAX_SENTENCES_PER_BUBBLE = 2
const MAX_GRADE = 5

// Each bubble the learner reads at once: a step's lines together, each hint, labels, UI text.
function bubbles() {
  const out = []
  for (const mission of MISSIONS) {
    out.push(mission.title)
    for (const step of mission.steps) {
      out.push(step.lines.join(" "))
      out.push(step.hint.bolt, step.hint.demo)
      if (step.expect.label) out.push(step.expect.label)
    }
  }
  return out.concat(Object.values(UI))
}

function sentences(text) {
  return text.split(/(?<=[.!?])\s+/).filter((s) => s.trim() !== "")
}

function words(text) {
  return text.replace(/\{codename\}/g, "name").match(/[A-Za-z][A-Za-z']*/g) || []
}

// Vowel groups, minus a silent final "e"; good enough for short everyday words.
function syllables(word) {
  const w = word.toLowerCase().replace(/'.*$/, "")
  const groups = w.match(/[aeiouy]+/g) || []
  let n = groups.length
  if (w.endsWith("e") && !w.endsWith("le") && n > 1) n--
  return Math.max(1, n)
}

function fleschKincaidGrade(texts) {
  let s = 0, w = 0, syl = 0
  for (const text of texts) {
    s += sentences(text).length
    for (const word of words(text)) { w++; syl += syllables(word) }
  }
  return 0.39 * (w / s) + 11.8 * (syl / w) - 15.59
}

test("syllable counting handles common words", () => {
  assert.equal(syllables("hacker"), 2)
  assert.equal(syllables("time"), 1)
  assert.equal(syllables("Academy"), 4)
  assert.equal(syllables("button"), 2)
})

test("no sentence is longer than the limit", () => {
  for (const bubble of bubbles()) {
    for (const sentence of sentences(bubble)) {
      const n = words(sentence).length
      assert.ok(n <= MAX_WORDS_PER_SENTENCE, `${n} words: "${sentence}"`)
    }
  }
})

test("no bubble has more than two sentences", () => {
  for (const bubble of bubbles()) {
    const n = sentences(bubble).length
    assert.ok(n <= MAX_SENTENCES_PER_BUBBLE, `${n} sentences: "${bubble}"`)
  }
})

test("all learner text reads at a 5th-grade level or easier", (t) => {
  const grade = fleschKincaidGrade(bubbles())
  t.diagnostic(`Flesch-Kincaid grade ${grade.toFixed(1)}`)
  assert.ok(grade <= MAX_GRADE, `Flesch-Kincaid grade ${grade.toFixed(1)} is above ${MAX_GRADE}`)
})
