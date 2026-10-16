// Mission scripts. Every learner-facing string lives here so tests/reading.test.js
// can hold it to a 5th-grade reading level. "{codename}" is filled in when shown.
//
// A step: who speaks, one or two lines, what the learner must do (expect), a short
// success line shown before moving on, and the help that grows while they're stuck:
// Bolt's hint, keys lit on the keyboard, then the Mentor's demo.

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
        expect: { type: "button", id: "accept", label: "Join the Academy", key: "Enter" },
        success: { speaker: "mentor", line: "Welcome aboard, recruit!" },
        hint: {
          bolt: "Tap the Enter key. It won't bite!",
          keys: ["Enter"],
          demo: "Find Enter on the right side of the keyboard. Tap it once."
        }
      },
      {
        speaker: "bolt",
        lines: ["Hi, I'm Bolt! I typed my name, but too many T's came out."],
        field: "BOLTTTT",
        expect: { type: "key", key: "Backspace", times: 3 },
        success: { speaker: "bolt", line: "That's me! Thank you!" },
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
        success: { speaker: "mentor", line: "Great name. Nobody will guess it." },
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
        expect: { type: "button", id: "finish", label: "Start training", key: "Enter" },
        success: { speaker: "bolt", line: "Training time! Let's go!" },
        hint: {
          bolt: "Tap Enter to start!",
          keys: ["Enter"],
          demo: "Find Enter on the right side of the keyboard. Tap it once."
        }
      }
    ]
  }
]

// Learner-facing strings outside the missions, also checked for reading level.
var UI = {
  comingSoon: "Your next mission is coming soon. Great work so far!",
  orEnter: "Tap Enter or click the button.",
  codenamePrompt: "Your hacker name",
  close: "Tap Esc or click here to close.",
  settings: "Settings"
}

if (typeof module !== "undefined") {
  module.exports = { MISSIONS: MISSIONS, UI: UI }
}
