# Hacker Academy — Vision

*Status: draft, captured from initial planning 2026-10-14. Expect revision.*

## One-liner

Hacker Academy is an Omarchy plugin that teaches someone who has only ever used a tablet how to drive Omarchy — framed as training to become a white-hat hacker.

## Who it's for

- **First:** kids around 7 who know touchscreens but have never used a pointer or a physical keyboard. The first tester is Nathan's son.
- **Also:** adults new to Omarchy or to tiling window managers. The skills are the same; the framing still works.

## Core concept

Lessons ask the learner to do **real things on the real desktop**, and the Academy notices when they do. "Hold Super and tap Enter to open a terminal" is checked by watching for the terminal window to actually open — not by a quiz. Omarchy's shell already receives live Hyprland events (windows opening and closing, focus changes, workspace switches), so the Academy can follow along without a separate helper.

The hacker theme is the motivation: keyboards, terminals, and window juggling are exactly what a movie hacker does, so mastering them feels like levelling up. Always **white hat** — the Academy is about skill and responsibility, never breaking into things. The theme should not date itself (no current memes or events).

## What it teaches

In order, each a short level (about 3–5 minutes):

1. **The pointer** — "on a tablet you touch things; here you move the arrow, then click." Click, drag, two-finger scroll, right-click.
2. **Tap keys vs. hold keys** — tap keys (letters, Space, Enter, Backspace, Esc) do something once; hold keys (Shift, Ctrl, Alt, Super) change what other keys do while held. Capitals with Shift, fixing mistakes with Backspace, Esc as the "never mind" key, the Caps Lock trap.
3. **Super combos** — the pattern *hold Super → tap a key → let go*. Open a terminal, close a window, open the browser.
4. **Windows** — side-by-side tiling, which window is listening (focus), moving focus, swapping, fullscreen, floating, dragging and resizing.
5. **Workspaces** — switching, and carrying a window to another workspace.
6. **Finding apps** — the app launcher, the Omarchy menu, the keybindings cheat sheet.
7. **Lock, log out, log in** — locking and unlocking; the system menu; finishing by logging out and back in, with progress picking up where it left off.
8. **Rescue skills** — what to do when stuck; why Ctrl + Alt + Delete (close all windows) is for emergencies.

Graduation earns a printable certificate.

## Design principles for young learners

- **No failure states.** Hints escalate when the learner is stuck: a hint, then the keys light up, then a demonstration.
- **Few words, large text, read-aloud option** for learners who don't read yet.
- **Show the keyboard.** An on-screen keyboard lights up keys as they are held and tapped, labelled the way the learner's physical keys are labelled (e.g. Super printed as "Win" on many keyboards).
- **Progress is saved** and levels can be replayed; a grown-up can skip or reset.

## Safety posture

Some lessons are inherently disruptive (closing all windows, logging out). The Academy is meant to run in the learner's own user account, not over a grown-up's open work; it should say so before those lessons.

## Distribution

A third-party Omarchy shell plugin: a public git repo with a `manifest.json`, installed with `omarchy plugin add <git-url>`, with the aim of being good enough to list for other families.

## Open questions

Unresolved until answered here or in an ADR.

- **Read-aloud narration** — offline text-to-speech, recorded voice, or both? Affects package size and dependencies.
- **Keyboard labelling** — detect the layout, or ask once ("what does your Super key say?")?
- **Where progress lives** — plugin settings vs. a file under the user's state directory; must survive logout/login.
- **Lessons that end the session** — how the lock and log-out levels resume cleanly afterwards.
- **Localization** — English first; whether strings are structured for translation from the start.
