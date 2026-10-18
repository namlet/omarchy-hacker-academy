// Mission scripts. Every learner-facing string lives here so tests/reading.test.js
// can hold it to a 5th-grade reading level. "{codename}" is filled in when shown.
//
// A step: who speaks, one or two lines, what the learner must do (expect), a short
// success line shown before moving on, and the help that grows while they're stuck:
// Bolt's hint, keys lit on the keyboard, then the Mentor's demo.
//
// From mission 3 the real desktop is the stage: the Academy waits in a corner, lets
// go of the keyboard, and watches windows open and close. Closing only counts for
// windows the learner opened in the mission. Omarchy's shortcuts never
// reach the Academy, so those steps show their keys (combo) instead of a keyboard.

var MISSIONS = [
  {
    id: "recruitment",
    title: "Recruitment",
    stage: "center",
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
  },
  {
    id: "force-fields",
    title: "Force Fields",
    stage: "center",
    steps: [
      {
        speaker: "mentor",
        lines: ["Some keys you tap. Tap means press and let go fast."],
        display: "typed",
        expect: { type: "anykey", times: 5, label: "Tap any five letter keys." },
        success: { speaker: "bolt", line: "Tap, tap, tap! You are fast." },
        hint: {
          bolt: "Press a letter key and let go. Do it five times.",
          keys: [],
          demo: "Tap A, then B, then C. Any letters work!"
        }
      },
      {
        speaker: "mentor",
        lines: ["Shift is a hold key. It works like a force field."],
        display: "shield",
        expect: { type: "hold", key: "Shift", ms: 3000, label: "Hold Shift down for three seconds." },
        success: { speaker: "mentor", line: "Force field up! Hold keys work while you hold them." },
        hint: {
          bolt: "Press Shift and keep your finger on it.",
          keys: ["Shift"],
          demo: "Shift is on the left side. Hold it until the bar is full."
        }
      },
      {
        speaker: "mentor",
        lines: ["Hold Shift, then tap a letter.", "You get a big letter!"],
        display: "typed",
        expect: { type: "capital", label: "Make a big letter with Shift." },
        success: { speaker: "bolt", line: "Whoa, a capital letter!" },
        hint: {
          bolt: "Keep holding Shift. While it is down, tap a letter.",
          keys: ["Shift"],
          demo: "Hold Shift with one finger. Tap a letter with another."
        }
      },
      {
        speaker: "bolt",
        lines: ["HELP! I CAN'T STOP SHOUTING!"],
        display: "loud",
        loud: "AAAH! EVERYTHING IS LOUD!",
        quiet: "Ahh. Everything is quiet now.",
        expect: { type: "tap", key: "Shift", label: "Tap Shift once to stop the shouting." },
        success: { speaker: "bolt", line: "Phew. That is much better." },
        hint: {
          bolt: "TAP SHIFT. JUST ONE QUICK TAP!",
          keys: ["Shift"],
          demo: "Both Shift keys at once turn shouting on. One quick tap turns it off."
        }
      },
      {
        speaker: "bolt",
        lines: ["Oops, I set off the alarm!", "Esc is the abort button."],
        display: "loud",
        loud: "ALARM! ALARM!",
        quiet: "All quiet.",
        expect: { type: "key", key: "Esc", label: "Tap Esc to stop the alarm." },
        success: { speaker: "mentor", line: "Alarm stopped. Esc means never mind." },
        hint: {
          bolt: "Esc is in the top left corner. Tap it!",
          keys: ["Esc"],
          demo: "Find Esc at the top left of the keyboard. Tap it once."
        }
      },
      {
        speaker: "mentor",
        lines: ["You know tap keys and hold keys now.", "Next, you get the master key!"],
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Woohoo! Mission complete, {codename}!" },
        hint: {
          bolt: "Tap Enter to finish!",
          keys: ["Enter"],
          demo: "Find Enter on the right side of the keyboard. Tap it once."
        }
      }
    ]
  },
  {
    id: "master-key",
    title: "The Master Key",
    stage: "corner",
    steps: [
      {
        speaker: "mentor",
        lines: ["Hackers have a master key.", "On your keyboard, it says Win."],
        expect: { type: "button", id: "ready", label: "Show me", key: "Enter" },
        success: { speaker: "bolt", line: "A master key? Can I hold it?" },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      },
      {
        speaker: "mentor",
        lines: ["Hold Win, tap Enter, then let go.", "That opens a terminal."],
        combo: ["Win", "Enter"],
        expect: { type: "window", action: "open", app: "terminal", label: "Open a terminal." },
        success: { speaker: "mentor", line: "A terminal! Hackers type commands in there." },
        hint: {
          bolt: "Keep Win down while you tap Enter.",
          keys: ["Win", "Enter"],
          demo: "Win is at the bottom left. Hold it, tap Enter, then let go."
        }
      },
      {
        speaker: "bolt",
        lines: ["Oops, that window is in my way!", "Win and W closes a window."],
        combo: ["Win", "W"],
        expect: { type: "window", action: "close", app: "terminal", label: "Close the terminal." },
        success: { speaker: "bolt", line: "Poof! It's gone." },
        hint: {
          bolt: "Hold Win, then tap W.",
          keys: ["Win", "W"],
          demo: "Click the terminal first. Then hold Win and tap W."
        }
      },
      {
        speaker: "bolt",
        lines: ["I want to watch robot videos!", "Win, Shift, and B open the browser."],
        combo: ["Win", "Shift", "B"],
        expect: { type: "window", action: "open", app: "browser", label: "Open the browser." },
        success: { speaker: "mentor", line: "Two hold keys at once. Very smooth." },
        hint: {
          bolt: "Hold Win and Shift. Then tap B.",
          keys: ["Win", "Shift", "B"],
          demo: "Hold Win with one finger and Shift with another. Then tap B."
        }
      },
      {
        speaker: "mentor",
        lines: ["Videos later, Bolt.", "Close the browser too."],
        combo: ["Win", "W"],
        expect: { type: "window", action: "close", app: "browser", label: "Close the browser." },
        success: { speaker: "bolt", line: "Aww. Okay, fine." },
        hint: {
          bolt: "Same trick as before. Win and W!",
          keys: ["Win", "W"],
          demo: "Click the browser first. Then hold Win and tap W."
        }
      },
      {
        speaker: "mentor",
        lines: ["You hold the master key now.", "You are an Agent, {codename}."],
        badge: "Agent",
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Agent {codename}! That sounds so cool." },
        hint: {
          bolt: "Click the button. You know how!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  },
  {
    id: "spotlight",
    title: "The Spotlight",
    stage: "corner",
    steps: [
      {
        speaker: "mentor",
        lines: ["Only one window can hear the keyboard.", "Its bright border is called the spotlight."],
        expect: { type: "button", id: "ready", label: "Show me", key: "Enter" },
        success: { speaker: "glitch", line: "Hee hee! Something sneaky is coming." },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      },
      {
        speaker: "glitch",
        lines: ["I'm the Glitch, and I hide in windows.", "Open two terminals and try to find me!"],
        combo: ["Win", "Enter"],
        expect: { type: "window", action: "open", app: "terminal", times: 2, label: "Open two terminals." },
        success: { speaker: "mentor", line: "Two windows. Only one has the bright border." },
        hint: {
          bolt: "Win and Enter, then Win and Enter again.",
          keys: ["Win", "Enter"],
          demo: "Hold Win and tap Enter. Let go, then do it one more time."
        }
      },
      {
        speaker: "glitch",
        lines: ["I'm hiding in the other window!", "Win and an arrow key moves the spotlight."],
        combo: ["Win", "←"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "focus", label: "Move the spotlight to the other window." },
        success: { speaker: "glitch", line: "Eek! You found me." },
        hint: {
          bolt: "Hold Win, then tap the left arrow.",
          keys: ["Win"],
          demo: "The arrow keys are at the bottom right. Hold Win and tap the left one."
        }
      },
      {
        speaker: "glitch",
        lines: ["Now I'm back in the first one!", "Can you catch me again?"],
        combo: ["Win", "→"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "focus", label: "Move the spotlight back." },
        success: { speaker: "bolt", line: "Ha! Caught you again, Glitch." },
        hint: {
          bolt: "This time, Win and the right arrow.",
          keys: ["Win"],
          demo: "Hold Win and tap the right arrow. Watch the bright border move."
        }
      },
      {
        speaker: "bolt",
        lines: ["Let's make that window huge!", "Win and F fills the whole screen."],
        combo: ["Win", "F"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "fullscreen", on: true, label: "Make the window fill the screen." },
        success: { speaker: "mentor", line: "One big window. No room to hide." },
        hint: {
          bolt: "Hold Win, then tap F.",
          keys: ["Win", "F"],
          demo: "F is in the middle row of letters. Hold Win and tap F."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win and F again shrinks it back.", "The same keys undo it."],
        combo: ["Win", "F"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "fullscreen", on: false, label: "Shrink the window back." },
        success: { speaker: "bolt", line: "Back to normal size!" },
        hint: {
          bolt: "Same keys again. Win and F!",
          keys: ["Win", "F"],
          demo: "Hold Win and tap F one more time."
        }
      },
      {
        speaker: "mentor",
        lines: ["Hackers clean up when they're done.", "Close both terminals."],
        combo: ["Win", "W"],
        expect: { type: "window", action: "close", app: "terminal", times: 2, label: "Close both terminals." },
        success: { speaker: "glitch", line: "Fine! I'll find another place to hide." },
        hint: {
          bolt: "Win and W closes the window in the spotlight.",
          keys: ["Win", "W"],
          demo: "Hold Win and tap W. Then do it again for the other one."
        }
      },
      {
        speaker: "mentor",
        lines: ["You can steer the spotlight now.", "The Glitch can't hide from you, {codename}."],
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Spotlight master {codename}! Woohoo!" },
        hint: {
          bolt: "Click the button. You know how!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  },
  {
    id: "rearranging",
    title: "Rearranging HQ",
    stage: "corner",
    steps: [
      {
        speaker: "mentor",
        lines: ["HQ is getting messy.", "Let's learn to move windows around."],
        expect: { type: "button", id: "ready", label: "Show me", key: "Enter" },
        success: { speaker: "glitch", line: "Messy? I can make it messier!" },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      },
      {
        speaker: "bolt",
        lines: ["We need two windows to play with.", "Open two terminals."],
        combo: ["Win", "Enter"],
        expect: { type: "window", action: "open", app: "terminal", times: 2, label: "Open two terminals." },
        success: { speaker: "glitch", line: "Hee hee. Now watch this!" },
        hint: {
          bolt: "Win and Enter, two times.",
          keys: ["Win", "Enter"],
          demo: "Hold Win and tap Enter. Let go, then do it one more time."
        }
      },
      {
        speaker: "glitch",
        lines: ["I put your windows in the wrong spots!", "Win, Shift, and an arrow swaps them."],
        combo: ["Win", "Shift", "←"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "swap", label: "Swap the two windows." },
        success: { speaker: "bolt", line: "They traded places!" },
        hint: {
          bolt: "Hold Win and Shift. Then tap an arrow.",
          keys: ["Win", "Shift"],
          demo: "Hold Win and Shift with two fingers. Tap the left arrow with another."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win and T lets a window float.", "It pops up on top of the others."],
        combo: ["Win", "T"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "float", on: true, label: "Make a window float." },
        success: { speaker: "bolt", line: "Whoa, it's floating!" },
        hint: {
          bolt: "Hold Win, then tap T.",
          keys: ["Win", "T"],
          demo: "T is in the top row of letters. Hold Win and tap T."
        }
      },
      {
        speaker: "mentor",
        lines: ["Hold Win, then drag the window with the mouse.", "You can put it anywhere."],
        combo: ["Win", "Drag"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "move", label: "Drag the floating window." },
        success: { speaker: "glitch", line: "Hey! Where did it go?" },
        hint: {
          bolt: "Keep Win down while you drag.",
          keys: ["Win"],
          demo: "Hold Win. Press the mouse button on the window and move it."
        }
      },
      {
        speaker: "bolt",
        lines: ["Now make it bigger!", "Hold Win and drag with the right button."],
        combo: ["Win", "Right drag"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "resize", label: "Make the window bigger or smaller." },
        success: { speaker: "mentor", line: "Big or small. You decide." },
        hint: {
          bolt: "Hold Win. Use the right mouse button this time.",
          keys: ["Win"],
          demo: "Hold Win. Press the right button on the window and drag."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win and T again puts it back in line."],
        combo: ["Win", "T"],
        needs: { app: "terminal", count: 2 },
        expect: { type: "float", on: false, label: "Put the window back in line." },
        success: { speaker: "bolt", line: "Neat and tidy!" },
        hint: {
          bolt: "Same keys as before. Win and T!",
          keys: ["Win", "T"],
          demo: "Click the floating window. Then hold Win and tap T."
        }
      },
      {
        speaker: "mentor",
        lines: ["Hackers clean up when they're done.", "Close both terminals."],
        combo: ["Win", "W"],
        expect: { type: "window", action: "close", app: "terminal", times: 2, label: "Close both terminals." },
        success: { speaker: "glitch", line: "You ruined my mess!" },
        hint: {
          bolt: "Win and W closes the window in the spotlight.",
          keys: ["Win", "W"],
          demo: "Hold Win and tap W. Then do it again for the other one."
        }
      },
      {
        speaker: "mentor",
        lines: ["HQ is yours to arrange now.", "Nice moves, {codename}."],
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Interior designer {codename}! Ha!" },
        hint: {
          bolt: "Click the button. You know how!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  },
  {
    id: "secret-rooms",
    title: "Secret Rooms",
    stage: "corner",
    steps: [
      {
        speaker: "mentor",
        lines: ["HQ has secret rooms called workspaces.", "Each room keeps its own windows."],
        expect: { type: "button", id: "ready", label: "Show me", key: "Enter" },
        success: { speaker: "glitch", line: "Ooh, rooms! I found one to hide in." },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      },
      {
        speaker: "glitch",
        lines: ["Come find me in room {room}!", "Win and {room} takes you there."],
        combo: ["Win", "{room}"],
        expect: { type: "workspace", to: "room", label: "Go to room {room}." },
        success: { speaker: "glitch", line: "How did you get in here?!" },
        hint: {
          bolt: "Hold Win, then tap the {room} key.",
          keys: ["Win"],
          demo: "The number keys are in the top row. Hold Win and tap {room}."
        }
      },
      {
        speaker: "mentor",
        lines: ["You are home in room {home}.", "Win and {home} takes you back."],
        combo: ["Win", "{home}"],
        expect: { type: "workspace", to: "home", label: "Go back to room {home}." },
        success: { speaker: "bolt", line: "Home sweet home." },
        hint: {
          bolt: "Hold Win, then tap {home}.",
          keys: ["Win"],
          demo: "Hold Win and tap the {home} key in the top row."
        }
      },
      {
        speaker: "bolt",
        lines: ["I want a window in the secret room.", "Open a terminal first."],
        combo: ["Win", "Enter"],
        expect: { type: "window", action: "open", app: "terminal", label: "Open a terminal." },
        success: { speaker: "mentor", line: "Now carry it to the other room." },
        hint: {
          bolt: "Win and Enter. You know this one!",
          keys: ["Win", "Enter"],
          demo: "Hold Win and tap Enter. Then let go."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win, Shift, and {room} carries the window there.", "You go along with it."],
        combo: ["Win", "Shift", "{room}"],
        needs: { app: "terminal", count: 1 },
        expect: { type: "carry", to: "room", label: "Carry the terminal to room {room}." },
        success: { speaker: "glitch", line: "Hey! That's my room!" },
        hint: {
          bolt: "Hold Win and Shift. Then tap {room}.",
          keys: ["Win", "Shift"],
          demo: "Hold Win and Shift with two fingers. Tap {room} with another."
        }
      },
      {
        speaker: "bolt",
        lines: ["Let's tidy up the secret room.", "Close the terminal."],
        combo: ["Win", "W"],
        expect: { type: "window", action: "close", app: "terminal", label: "Close the terminal." },
        success: { speaker: "glitch", line: "Fine. I'll find a new hiding spot." },
        hint: {
          bolt: "Win and W closes it.",
          keys: ["Win", "W"],
          demo: "Hold Win and tap W."
        }
      },
      {
        speaker: "mentor",
        lines: ["Now head home to room {home}."],
        combo: ["Win", "{home}"],
        expect: { type: "workspace", to: "home", label: "Go back to room {home}." },
        success: { speaker: "bolt", line: "Back at HQ!" },
        hint: {
          bolt: "Hold Win, then tap {home}.",
          keys: ["Win"],
          demo: "Hold Win and tap the {home} key in the top row."
        }
      },
      {
        speaker: "mentor",
        lines: ["You know every room in HQ now.", "You are a Specialist, {codename}."],
        badge: "Specialist",
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Specialist {codename}! That's so fancy!" },
        hint: {
          bolt: "Click the button. You know how!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  },
  {
    id: "toolkit",
    title: "The Toolkit",
    stage: "corner",
    steps: [
      {
        speaker: "mentor",
        lines: ["Every hacker needs a toolkit.", "Omarchy keeps its tools in menus."],
        expect: { type: "button", id: "ready", label: "Show me", key: "Enter" },
        success: { speaker: "bolt", line: "Tools! I love tools." },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win and Space opens the Omarchy menu.", "Look, but don't click anything yet."],
        combo: ["Win", "Space"],
        expect: { type: "menu", open: true, label: "Open the Omarchy menu." },
        success: { speaker: "bolt", line: "So many tools!" },
        hint: {
          bolt: "Hold Win, then tap the long Space bar.",
          keys: ["Win", "Space"],
          demo: "Space is the long key at the bottom. Hold Win and tap it."
        }
      },
      {
        speaker: "mentor",
        lines: ["Esc closes a menu without picking anything."],
        combo: ["Esc"],
        expect: { type: "menu", open: false, label: "Close the menu." },
        success: { speaker: "glitch", line: "Hey, I was reading that!" },
        hint: {
          bolt: "Esc is the top left key.",
          keys: ["Esc"],
          demo: "Tap Esc once. The menu goes away."
        }
      },
      {
        speaker: "bolt",
        lines: ["Win, Alt, and Space shows all your apps.", "Pick any app and tap Enter."],
        combo: ["Win", "Alt", "Space"],
        expect: { type: "window", action: "open", app: "any", label: "Open an app from the list." },
        success: { speaker: "bolt", line: "It worked! You opened an app." },
        hint: {
          bolt: "Hold Win and Alt. Then tap Space.",
          keys: ["Win", "Alt", "Space"],
          demo: "Use the arrow keys to pick an app. Then tap Enter."
        }
      },
      {
        speaker: "mentor",
        lines: ["Close the app when you're done."],
        combo: ["Win", "W"],
        expect: { type: "window", action: "close", app: "any", label: "Close the app." },
        success: { speaker: "glitch", line: "Hmph. I bet you can't remember every key." },
        hint: {
          bolt: "Win and W closes it.",
          keys: ["Win", "W"],
          demo: "Click the app first. Then hold Win and tap W."
        }
      },
      {
        speaker: "mentor",
        lines: ["You don't have to remember them all.", "Win and K shows a list of every key."],
        combo: ["Win", "K"],
        expect: { type: "menu", open: true, label: "Open the list of keys." },
        success: { speaker: "glitch", line: "No fair! You found the list." },
        hint: {
          bolt: "Hold Win, then tap K.",
          keys: ["Win", "K"],
          demo: "K is in the middle row of letters. Hold Win and tap K."
        }
      },
      {
        speaker: "mentor",
        lines: ["Esc closes the list too."],
        combo: ["Esc"],
        expect: { type: "menu", open: false, label: "Close the list." },
        success: { speaker: "bolt", line: "Easy peasy." },
        hint: {
          bolt: "Esc is the top left key.",
          keys: ["Esc"],
          demo: "Tap Esc once."
        }
      },
      {
        speaker: "mentor",
        lines: ["Your toolkit is ready, {codename}.", "Just two more missions to White Hat."],
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Toolkit expert {codename}! Beep boop!" },
        hint: {
          bolt: "Click the button. You know how!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  },
  {
    id: "lockdown",
    title: "Lockdown",
    stage: "corner",
    steps: [
      {
        speaker: "mentor",
        lines: ["A hacker never walks away from an open screen.", "Lock it, and nobody can sneak in."],
        expect: { type: "button", id: "ready", label: "Show me", key: "Enter" },
        success: { speaker: "glitch", line: "Sneak in? Who, me?" },
        hint: {
          bolt: "Click the button to start!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win, Ctrl, and L locks the screen.", "Your password opens it again."],
        combo: ["Win", "Ctrl", "L"],
        expect: { type: "lock", on: true, label: "Lock the screen." },
        success: { speaker: "glitch", line: "Hey! I can't get in!" },
        hint: {
          bolt: "Hold Win and Ctrl. Then tap L.",
          keys: ["Win", "Ctrl", "L"],
          demo: "Hold Win and Ctrl with two fingers. Tap L with another."
        }
      },
      {
        speaker: "bolt",
        lines: ["Type your password and tap Enter."],
        combo: ["Enter"],
        expect: { type: "lock", on: false, label: "Unlock the screen." },
        success: { speaker: "bolt", line: "You're back! The Glitch is still outside." },
        hint: {
          bolt: "Type your password. Then tap Enter.",
          keys: ["Enter"],
          demo: "Type your password on the lock screen. Then tap Enter."
        }
      },
      {
        speaker: "mentor",
        lines: ["Win and Esc opens the System menu.", "Look, but don't click anything."],
        combo: ["Win", "Esc"],
        expect: { type: "menu", open: true, label: "Open the System menu." },
        success: { speaker: "bolt", line: "Lock, log out, and turn off. All in one place!" },
        hint: {
          bolt: "Hold Win, then tap Esc.",
          keys: ["Win", "Esc"],
          demo: "Esc is the top left key. Hold Win and tap it."
        }
      },
      {
        speaker: "mentor",
        lines: ["Esc closes it again."],
        combo: ["Esc"],
        expect: { type: "menu", open: false, label: "Close the menu." },
        success: { speaker: "mentor", line: "Now for the big one." },
        hint: {
          bolt: "Esc is the top left key.",
          keys: ["Esc"],
          demo: "Tap Esc once."
        }
      },
      {
        speaker: "mentor",
        lines: ["Logging out closes all your windows, but your mission waits.", "Log out, then log back in."],
        combo: ["Win", "Esc"],
        expect: { type: "login", label: "Pick Logout. Then log back in." },
        success: { speaker: "bolt", line: "You came back! And your mission waited." },
        hint: {
          bolt: "Open the System menu. Type logout and tap Enter.",
          keys: ["Win", "Esc"],
          demo: "Log in with your password. Then click the Academy on the bar."
        }
      },
      {
        speaker: "mentor",
        lines: ["Your screen is safe with you, {codename}.", "One mission left: Rescue Protocol."],
        expect: { type: "button", id: "finish", label: "Finish mission", key: "Enter" },
        success: { speaker: "bolt", line: "Lockdown complete! Beep boop!" },
        hint: {
          bolt: "Click the button. You know how!",
          keys: [],
          demo: "Move the arrow onto the button. Then click once."
        }
      }
    ]
  }
]

// The whole tutorial: Part 1 is ten missions (MISSIONS holds the ones built so far),
// and the learner rises through four ranks. A rank is earned by finishing the first
// mission of its group, whose last step shows the rank's badge.
var CAMPAIGN = {
  part: "Part 1: The Desktop",
  nextPart: "Part 2: The Command Line",
  titles: ["Recruitment", "Pointer Control", "Force Fields", "The Master Key", "The Spotlight",
    "Rearranging HQ", "Secret Rooms", "The Toolkit", "Lockdown", "Rescue Protocol"],
  ranks: [
    { name: "Recruit", missions: [0, 1, 2] },
    { name: "Agent", missions: [3, 4, 5] },
    { name: "Specialist", missions: [6, 7, 8] },
    { name: "White Hat", missions: [9] }
  ]
}

// Learner-facing strings outside the missions, also checked for reading level.
var UI = {
  comingSoon: "Your next mission is coming soon. Great work so far!",
  yourTask: "Your task",
  transmission: "Transmission",
  rankUp: "Rank up",
  unlocked: "Unlocked",
  accessLevel: "Access level {level}",
  badgeAdded: "{rank} badge added to your file",
  badges: "Badges",
  locked: "Locked",
  nextPartLocked: "Real hackers type their orders. Become a White Hat to open it.",
  progressSaved: "Progress saved",
  caught: "Caught",
  tapped: "Tapped",
  opened: "Opened",
  closed: "Closed",
  orEnter: "Tap Enter or click the button.",
  keepScrolling: "Keep scrolling down.",
  keepHolding: "Keep holding Shift!",
  codenamePrompt: "Your hacker name",
  settings: "Settings"
}

if (typeof module !== "undefined") {
  module.exports = { MISSIONS: MISSIONS, CAMPAIGN: CAMPAIGN, UI: UI }
}
