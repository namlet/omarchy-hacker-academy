# ADR-0001: Plugin stack

**Status:** Accepted (2026-10-14)
**Date:** 2026-10-14
**Deciders:** Nathan

## Context

Per [vision.md](../vision.md), Hacker Academy teaches Omarchy by having the learner perform real desktop actions and noticing when they happen. It is meant to be distributed to other Omarchy users.

Constraints shaping this decision:

- **Must observe the real desktop** — window open/close, focus, workspace switches, and key presses inside its own surface.
- **Distributable the Omarchy way.** Omarchy has a third-party shell plugin model: a git repo with a `manifest.json` and QML entry points, installed with `omarchy plugin add <git-url>` into `~/.config/omarchy/plugins/<plugin-id>/`.
- **Should look native** across every Omarchy theme without per-theme work.
- **Plain JavaScript over TypeScript** — owner preference.
- **No background services** to install or keep running for a tutorial.

## Decision

**An Omarchy shell plugin written in QML for Quickshell**, with behaviour in QML's built-in JavaScript. Desktop events come from Quickshell's `Quickshell.Hyprland` module (the same `onRawEvent` stream Omarchy's own shell code uses). No helper process, no extra runtime.

Plugin kinds, entry points, and the test runner are decided in later ADRs as they come up.

## Options Considered

#### Option A: QML shell plugin (chosen)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium — QML/Quickshell is less familiar, but small surface |
| Distribution | Native: `omarchy plugin add`; no packaging |
| Desktop integration | Live Hyprland events in-process; inherits the active theme |
| Dependencies | None beyond what Omarchy already ships (Quickshell, Qt 6) |

**Pros:** Fits Omarchy's plugin model exactly, so it can be listed and installed like first-party plugins. Hyprland events and theming come for free. Logic is JavaScript.
**Cons:** Runs inside the shared `omarchy-shell` process, so a bad plugin can affect the bar; plugins receive capability-scoped facades, which may limit some interactions (to be discovered in practice). Smaller pool of QML examples than web.

#### Option B: Web app + local helper
**Pros:** Rich animation and audio are easy; huge ecosystem; plain JS.
**Cons:** Not a plugin — needs a browser app window plus a background helper relaying Hyprland events; two moving parts to install and keep running; doesn't inherit the theme.

#### Option C: Python + GTK desktop app
**Pros:** Standalone, familiar tooling.
**Cons:** Doesn't match Omarchy's plugin model or theming; Python dependency management for end users; still needs its own Hyprland IPC client.

## Consequences

- QML and Quickshell become the project's core skills; examples come from Omarchy's own first-party plugins under `$OMARCHY_PATH/shell/plugins/`.
- The test strategy must work for QML (Qt's `qmltestrunner` ships with `qt6-declarative` and is the first candidate).
- If the plugin facades block something essential, revisit with a superseding ADR rather than working around them.
