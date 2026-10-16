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
  },
  {
    id: "pointer",
    title: "Pointer Control",
    stage: "center",
    holdKeyboard: true,
    steps: [
      {
        speaker: "mentor",
        lines: ["Hackers don't touch the screen. They steer an arrow."],
        play: "bolt",
        expect: { type: "pointer", action: "hover", ids: ["bolt"], label: "Move the arrow onto Bolt." },
        success: { speaker: "bolt", line: "Hey, that tickles!" },
        hint: {
          bolt: "Slide one finger on the touchpad. Or move the mouse.",
          keys: [],
          demo: "Watch the arrow as you move. Stop when it sits on me."
        }
      },
      {
        speaker: "bolt",
        lines: ["Uh oh. My antenna sparked, and bugs got out!"],
        play: "bugs",
        expect: { type: "pointer", action: "click", ids: ["bug1", "bug2", "bug3", "bug4", "bug5"], label: "Click each bug to catch it." },
        success: { speaker: "mentor", line: "Five bugs caught. Nice work!" },
        hint: {
          bolt: "Put the arrow on a bug. Then press the button once.",
          keys: [],
          demo: "Point at a bug and click. Do that for every bug."
        }
      },
      {
        speaker: "mentor",
        lines: ["This bug is too big to click.", "Drag it into the jar instead."],
        play: "drag",
        expect: { type: "pointer", action: "drop", ids: ["bigbug"], target: "jar", label: "Drag the big bug into the jar." },
        success: { speaker: "bolt", line: "It fits! Just barely." },
        hint: {
          bolt: "Press the button and hold it down. Move the bug, then let go.",
          keys: [],
          demo: "Keep holding while you move. Let go when the bug is over the jar."
        }
      },
      {
        speaker: "bolt",
        lines: ["One bug is hiding way down low.", "Scroll down to find it."],
        play: "scroll",
        expect: { type: "pointer", action: "click", ids: ["hidden"], label: "Scroll down, then click the bug." },
        success: { speaker: "mentor", line: "Found it! Scrolling shows what is hidden." },
        hint: {
          bolt: "Slide two fingers up the touchpad. Or roll the mouse wheel.",
          keys: [],
          demo: "Keep scrolling until you see the bug. Then click it."
        }
      },
      {
        speaker: "mentor",
        lines: ["The last bug is sneaky.", "It only answers a right-click."],
        play: "sneaky",
        expect: { type: "pointer", action: "rightclick", ids: ["sneaky"], label: "Right-click the sneaky bug." },
        success: { speaker: "bolt", line: "Got it! That was the last bug!" },
        hint: {
          bolt: "Tap the touchpad with two fingers. Or press the right mouse button.",
          keys: [],
          demo: "Point at the bug. Then click with the right side of the mouse."
        }
      },
      {
        speaker: "bolt",
        lines: ["You steer like a pro now.", "Next, teach me the keyboard!"],
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "mentor", line: "Mission complete, {codename}!" },
        hint: {
          bolt: "Click the button. You know how now!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  }
]

// Learner-facing strings outside the missions, also checked for reading level.
var UI = {
  comingSoon: "Your next mission is coming soon. Great work so far!",
  orEnter: "Tap Enter or click the button.",
  keepScrolling: "Keep scrolling down.",
  codenamePrompt: "Your hacker name",
  close: "Tap Esc or click here to close.",
  settings: "Settings"
}

if (typeof module !== "undefined") {
  module.exports = { MISSIONS: MISSIONS, UI: UI }
}
