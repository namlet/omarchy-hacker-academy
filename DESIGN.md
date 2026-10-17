# Hacker Academy — Design

Hacker Academy teaches someone who has only ever used a tablet how to drive Omarchy, framed as training to become a white-hat hacker.

## Who it's for

Written at a **5th-grade reading level**, which suits anyone starting out:

- **First:** kids who know touchscreens but have never used a pointer or a physical keyboard, including strong younger readers.
- **Also:** older kids and adults new to Omarchy or to tiling window managers.

## How it works

Lessons ask the learner to do **real things on the real desktop**, and the Academy notices when they do. "Hold Super and tap Enter to open a terminal" is checked by watching for the terminal window to open — not by a quiz.

The hacker theme is the motivation: keyboards, terminals, and juggling windows are what a movie hacker does, so mastering them feels like levelling up. Always **white hat**, and no references that date it.

## Story

The learner is a new recruit at a secret school for white-hat hackers hidden inside their own computer, with Omarchy as its headquarters. Inspired by the spirit of *Why's (Poignant) Guide to Ruby*: goofy, warm, and full of odd pictures, but with far fewer words. All characters and text are original. Names are placeholders.

- **The Mentor** gives each mission and celebrates wins: calm, kind, a little dry.
- **Bolt,** a goofy robot sidekick, gets into trouble the learner fixes. When something goes wrong, it went wrong for Bolt first, so the learner is always the rescuer.
- **The Glitch,** a mischievous pixel bug, scrambles windows and hides things from mission 4 on. Annoying, never scary.
- **The learner** picks a codename and rises through four ranks: Recruit (missions 0–2), Agent (3–5), Specialist (6–8), and White Hat at graduation.

Each mission has four beats: the Mentor sets it up, Bolt or the Glitch causes trouble, the learner fixes it with the new skill, and a payoff leads into the next mission. Between missions, a short funny "intercepted transmission" unlocks, and a pixel-art map of HQ shows progress. Everything is drawn as pixel art.

Ideas get memorable pictures: hold keys are **force fields**, Super is **the master key**, the focused window is **in the spotlight**, workspaces are **secret rooms**, and Esc is **the abort button**.

## Missions

Ten missions, each about 3–5 minutes, each proven by a real action the Academy can detect:

0. **Recruitment** — click a button, type a codename, Enter and Backspace.
1. **Pointer Control** — "on a tablet you touch things; here you steer." Move, click, drag, two-finger scroll, right-click.
2. **Force Fields** — tap keys (letters, Space, Enter, Backspace, Esc) do something once; hold keys (Shift, Ctrl, Alt, Super) change other keys while held. Capitals with Shift, Esc as the abort button, the Caps Lock trap.
3. **The Master Key** — *hold Super → tap a key → let go*. Open a terminal, close a window, open the browser.
4. **The Spotlight** — which window hears the keyboard, moving focus with Super + arrows, fullscreen.
5. **Rearranging HQ** — swapping windows, floating, dragging and resizing with Super held.
6. **Secret Rooms** — switching workspaces, and carrying a window to another one.
7. **The Toolkit** — the app launcher, the Omarchy menu, the keybindings cheat sheet.
8. **Lockdown** — lock and unlock, the system menu, then log out and back in with progress picking up where it left off.
9. **Rescue Protocol** — what to do when stuck, ending with Ctrl + Alt + Delete pressed for real to clear the Glitch's tangle.

Graduation earns the White Hat rank and a printable certificate with the learner's codename.

## Rules for young learners

- **No failure states.** Hints escalate: a hint, then the keys light up, then a demonstration.
- **5th-grade reading level:** sentences under 15 words, everyday words, one instruction at a time, at most two sentences per speech bubble, large text.
- **Works silently.** Nothing has to be said aloud. Sound effects are optional with an off switch, and every sound has a caption.
- **An on-screen keyboard** lights up keys as they are held and tapped, labelled like the learner's keys (Super is printed "Win" on many keyboards).
- **Progress is saved** to `$XDG_STATE_HOME/io.github.namlet.hacker-academy.json` (outside the plugin folder, which the shell watches for code changes), so it survives logging out. A settings screen lets a grown-up skip a mission or reset progress.
- **Opened from a top-bar button,** so learners never need a command.
- **Plays on a workspace of its own.** When the Academy opens on a workspace holding anyone else's windows, it moves to an empty one, so a learner practising Win + W can't close a grown-up's work. Closing steps only count windows the learner opened.
- Disruptive missions (closing all windows, logging out) are meant for the learner's own account; the Academy warns first. Omarchy's Ctrl + Alt + Delete closes every app window but not the Academy, which is part of the shell like the top bar, so the mission can watch the windows close.

## Stack

A third-party Omarchy shell plugin: QML for Quickshell, with logic in QML's built-in JavaScript. Desktop events come from `Quickshell.Hyprland` (the `onRawEvent` stream Omarchy's own shell uses). No helper process and no dependencies beyond what Omarchy ships. Installed with `omarchy plugin add <git-url>`; aimed at the Kids category of the Omarchy plugin marketplace.

Considered and rejected: a web app with a local event helper (two moving parts, not a plugin, no theming) and a Python/GTK app (doesn't fit Omarchy's plugin model).

## Keyboard input

Learners have every kind of keyboard and layout, so key names can't be trusted for releases: layouts and options remap them, and Omarchy's default `shift:both_capslock_cancel` reports Shift's release as Caps Lock. Rules:

- Pair every press with its release by **physical key** (scan code), never by key name. All hold keys (Shift, Ctrl, Alt, Super) are tracked this way.
- When the Academy loses the keyboard, let go of every held key — the releases go to another window.
- Omarchy gives the keyboard to whatever is under the mouse. During keyboard exercises the Academy holds the keyboard (exclusive focus) so a drifting pointer can't take it; during desktop exercises it lets go so real windows get keys.
- Bugs from real keyboards get a test that replays the captured events.

## Testing

Quickshell's modules are compiled into the `quickshell` binary, and the shell's own `qs.*` modules (theme colors, UI pieces) only exist inside the running shell, so neither loads under Qt's test runner or linter. Tests are split by what each tool can reach:

- **Logic** — lesson steps, hints, progress, key classification, reading Hyprland events — lives in plain `.js` model files carrying Omarchy's `if (typeof module !== "undefined") module.exports = {...}` guard, tested with Node's built-in runner. Events are fed in as plain `{ name, data }` objects.
- **UI and keyboard behaviour** in QML that doesn't import Quickshell or `qs.*` lives in `components/`, takes theme values as properties, is tested headless with `qmltestrunner` (simulated key holds and taps work), and is linted strictly with `qmllint`.
- **Quickshell wiring** (`Panel.qml`) stays thin with no logic, and is checked by hand on a real Omarchy desktop: it can't be linted or tested outside the shell.

- **Pixel art** is text in `Sprites.js` (one character per pixel, named by role so it takes the theme's colors), checked for shape by tests and by eye with `make preview`, which shows every sprite on a dark and a light theme.

Rule: anything testable must not import Quickshell or `qs.*`. `make test` runs everything; CI runs it on every pull request in an Arch Linux container.

## Roadmap

1. **Skeleton** — installs with `omarchy plugin add`, opens, reads key holds and taps, and sees a real window open. Tests and CI running.
2. **Foundations** — missions 0–3 with the Mentor, Bolt, and pixel art, playtested with a 7-year-old until he finishes them without help.
3. **The rest** — missions 4–9 with the Glitch, ranks, transmissions, certificate, sound, marketplace submission.

## Open questions

- Read-aloud narration on top of sound effects: offline text-to-speech, a recorded voice, or none?
- Final character names.
- Keyboard labels: detect the layout, or ask once what the Super key says?
- Where progress is stored so it survives logging out.
- How the lock and log-out lessons resume cleanly.
- Translation: English first; structure strings for translation from the start?
- Later: a classroom mode for shared computers (skip the log-out step, reset progress between students).
