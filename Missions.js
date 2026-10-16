// Mission scripts. Every learner-facing string lives here so tests/reading.test.js
// can hold it to a 5th-grade reading level. "{codename}" is filled in when shown.
//
// A step: who speaks, one or two lines, what the learner must do (expect), and the
// help that grows while they're stuck: Bolt's hint, keys lit on the keyboard, then
// the Mentor's demo.

var MISSIONS = [
  {
    id: "recruitment",
    title: "Recruitment",
    stage: "center",
    holdKeyboard: true,
    steps: [
      {
        speaker: "mentor",
        lines: ["We've been watching you.", "You have what it takes to be a hacker."],
        expect: { type: "button", id: "accept", label: "Join the Academy" },
        hint: {
          bolt: "Click the button. It won't bite!",
          keys: [],
          demo: "Move the arrow onto the button. Then click."
        }
      },
      {
        speaker: "bolt",
        lines: ["Hi, I'm Bolt! I typed my name, but too many T's came out."],
        field: "BOLTTTT",
        expect: { type: "key", key: "Backspace", times: 3 },
        hint: {
          bolt: "Backspace eats one letter each time you tap it.",
          keys: ["Backspace"],
          demo: "Find Backspace at the top right. Tap it three times."
        }
      },
      {
        speaker: "mentor",
        lines: ["Now pick your secret hacker name.", "Type it, then tap Enter."],
        expect: { type: "codename" },
        hint: {
          bolt: "Any name works. Mine is Bolt!",
          keys: ["Enter"],
          demo: "Type a name with the letter keys. Then tap Enter."
        }
      },
      {
        speaker: "mentor",
        lines: ["Welcome to the Academy, {codename}.", "You are now a Recruit."],
        badge: "Recruit",
        expect: { type: "button", id: "finish", label: "Start training" },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click."
        }
      }
    ]
  }
]

// Learner-facing strings outside the missions, also checked for reading level.
var UI = {
  comingSoon: "Your next mission is coming soon. Great work so far!",
  codenamePrompt: "Your hacker name",
  close: "Tap Esc or click here to close.",
  settings: "Settings"
}

if (typeof module !== "undefined") {
  module.exports = { MISSIONS: MISSIONS, UI: UI }
}
