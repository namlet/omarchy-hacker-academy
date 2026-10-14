# ADR-0002: Test strategy

**Status:** Proposed
**Date:** 2026-10-14
**Deciders:** Nathan

## Context

The principles require tests for every change ([CLAUDE.md](../../CLAUDE.md)). [ADR-0001](0001-plugin-stack.md) makes the product a QML plugin for Quickshell whose lessons react to key presses in its own surface and to live Hyprland events. We need a way to test that which runs locally and in CI, without a real desktop.

Evidence from a spike on 2026-10-14 (Quickshell 0.3.1, Qt 6.11.2, Node 26):

- **Plain-JS logic tests with `node:test`** — a model file exporting through Omarchy's `if (typeof module !== "undefined") module.exports = {...}` guard loads directly in Node. Tests passed with no dependencies.
- **`qmltestrunner` runs headless** (`QT_QPA_PLATFORM=offscreen`). A `TestCase` simulated *holding* Shift, *tapping* A, and releasing Shift (`keyPress` / `keyClick` / `keyRelease`), and called the same model file from QML. All passed in 4 ms.
- **Quickshell modules cannot be imported under `qmltestrunner`.** `import Quickshell` fails with *plugin "quickshell-coreplugin" not found*: Quickshell's modules are compiled into the `quickshell` binary, not shipped as loadable plugins.

Omarchy's own first-party plugins already follow the shape this suggests: logic lives in plain-JS `*Model.js` files (e.g. `IdleModel.js`, `BarModel.js`) carrying the `module.exports` guard, separate from the QML that uses them.

## Decision

Three layers, matched to what each tool can actually reach:

1. **Logic → `node:test`.** Everything with rules in it — lesson steps, progress, hint escalation, key classification, turning Hyprland events into lesson facts — lives in plain-JS `*Model.js` files with Omarchy's `module.exports` guard, and is tested with Node's built-in runner. Hyprland events are passed in as plain `{ name, data }` objects, so tests feed synthetic events. No npm dependencies.
2. **UI and keyboard behaviour → `qmltestrunner`, headless.** QML components that do not import Quickshell are tested with Qt's `TestCase`, including simulated key holds and taps. `qmltestrunner` ships with `qt6-declarative`; nothing to add.
3. **Quickshell wiring → thin adapters, verified by hand.** The few files that must import Quickshell (the plugin entry point and the Hyprland event listener) hold no logic: they forward events and mount components. They are checked by a manual smoke test on a real Omarchy desktop, recorded in each phase's exit verification.

**Rule that makes this work:** anything that can be tested must not import Quickshell. If a file needs both Quickshell and logic, split it.

**Layout:** tests live in a top-level `tests/` directory (`tests/*.test.js` for Node, `tests/tst_*.qml` for QML).

**CI:** a GitHub Actions workflow runs both suites on every PR inside an `archlinux` container, installing `nodejs` and `qt6-declarative` with pacman, so CI uses the same Qt that Omarchy users have. Red means no merge.

## Options Considered

#### Option A: node:test + qmltestrunner + thin adapters (proposed)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Low — two built-in runners, no frameworks |
| Dependencies | None added; Node and Qt test tooling already present |
| Coverage | All logic and all non-Quickshell UI; adapters by hand |
| Fidelity | Real Qt key handling; real Arch Qt in CI |

**Pros:** Matches Omarchy's own model-file convention and the `node:test` preference. Fast. Nothing to install for users.
**Cons:** The Quickshell adapters are only checked manually; a mistake there shows up in the smoke test, not CI. Mitigated by keeping them tiny.

#### Option B: qmltestrunner only
**Pros:** One runner.
**Cons:** Can't load Quickshell either, so it has the same adapter gap; and plain-JS logic is quicker and clearer to test in Node.

#### Option C: Full end-to-end in CI (headless Wayland compositor running Quickshell and the plugin)
**Pros:** Would cover the adapters too.
**Cons:** Running a compositor, Quickshell, and the Omarchy shell headless in CI is a project of its own, brittle, and slow. Revisit if adapter bugs actually start slipping through.

## Consequences

- New top-level `tests/` directory and `.github/workflows/` CI file (both covered by accepting this ADR).
- Code review checks the "no Quickshell import in testable files" rule.
- Phase exit verifications include a manual smoke test on a real Omarchy desktop.
