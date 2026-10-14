# Hacker Academy — Design

Hacker Academy teaches someone who has only ever used a tablet how to drive Omarchy, framed as training to become a white-hat hacker.

## Who it's for

- **First:** kids around 7 who know touchscreens but have never used a pointer or a physical keyboard.
- **Also:** adults new to Omarchy or to tiling window managers.

## How it works

Lessons ask the learner to do **real things on the real desktop**, and the Academy notices when they do. "Hold Super and tap Enter to open a terminal" is checked by watching for the terminal window to open — not by a quiz.

The hacker theme is the motivation: keyboards, terminals, and juggling windows are what a movie hacker does, so mastering them feels like levelling up. Always **white hat**, and no references that date it.

## Lessons

Each a short level (about 3–5 minutes):

1. **The pointer** — "on a tablet you touch things; here you move the arrow, then click." Click, drag, two-finger scroll, right-click.
2. **Tap keys vs. hold keys** — tap keys (letters, Space, Enter, Backspace, Esc) do something once; hold keys (Shift, Ctrl, Alt, Super) change other keys while held. Capitals with Shift, Backspace, Esc as "never mind", the Caps Lock trap.
3. **Super combos** — *hold Super → tap a key → let go*. Open a terminal, close a window, open the browser.
4. **Windows** — side-by-side tiling, focus, moving focus, swapping, fullscreen, floating, dragging and resizing.
5. **Workspaces** — switching, and carrying a window to another workspace.
6. **Finding apps** — the app launcher, the Omarchy menu, the keybindings cheat sheet.
7. **Lock, log out, log in** — ending with logging out and back in, progress picking up where it left off.
8. **Rescue skills** — what to do when stuck; why Ctrl + Alt + Delete (close all windows) is for emergencies.

Graduation earns a printable certificate.

## Rules for young learners

- **No failure states.** Hints escalate: a hint, then the keys light up, then a demonstration.
- **Few words, large text, read-aloud option.**
- **An on-screen keyboard** lights up keys as they are held and tapped, labelled like the learner's keys (Super is printed "Win" on many keyboards).
- **Progress is saved;** levels can be replayed, and a grown-up can skip or reset.
- Disruptive lessons (closing all windows, logging out) are meant for the learner's own account; the Academy says so first.

## Stack

A third-party Omarchy shell plugin: QML for Quickshell, with logic in QML's built-in JavaScript. Desktop events come from `Quickshell.Hyprland` (the `onRawEvent` stream Omarchy's own shell uses). No helper process and no dependencies beyond what Omarchy ships. Installed with `omarchy plugin add <git-url>`; aimed at the Kids category of the Omarchy plugin marketplace.

Considered and rejected: a web app with a local event helper (two moving parts, not a plugin, no theming) and a Python/GTK app (doesn't fit Omarchy's plugin model).

## Testing

Quickshell's modules are compiled into the `quickshell` binary, and the shell's own `qs.*` modules (theme colors, UI pieces) only exist inside the running shell, so neither loads under Qt's test runner or linter. Tests are split by what each tool can reach:

- **Logic** — lesson steps, hints, progress, key classification, reading Hyprland events — lives in plain `.js` model files carrying Omarchy's `if (typeof module !== "undefined") module.exports = {...}` guard, tested with Node's built-in runner. Events are fed in as plain `{ name, data }` objects.
- **UI and keyboard behaviour** in QML that doesn't import Quickshell or `qs.*` lives in `components/`, takes theme values as properties, is tested headless with `qmltestrunner` (simulated key holds and taps work), and is linted strictly with `qmllint`.
- **Quickshell wiring** (`Panel.qml`) stays thin with no logic, and is checked by hand on a real Omarchy desktop: it can't be linted or tested outside the shell.

Rule: anything testable must not import Quickshell or `qs.*`. `make test` runs everything; CI runs it on every pull request in an Arch Linux container.

## Roadmap

1. **Skeleton** — installs with `omarchy plugin add`, opens, reads key holds and taps, and sees a real window open. Tests and CI running.
2. **Foundations** — lessons 1–3, playtested with a 7-year-old until he finishes them without help.
3. **The rest** — lessons 4–8, certificate, narration, marketplace submission.

## Open questions

- Read-aloud narration: offline text-to-speech, a recorded voice, or both?
- Keyboard labels: detect the layout, or ask once what the Super key says?
- Where progress is stored so it survives logging out.
- How the lock and log-out lessons resume cleanly.
- Translation: English first; structure strings for translation from the start?
