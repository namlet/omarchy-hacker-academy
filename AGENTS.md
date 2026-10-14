# AGENTS.md

Guidance for anyone — human or agent — working in this repo. What the plugin is and how it's built: [DESIGN.md](DESIGN.md).

## Principles

1. **Ask clarifying questions before building.** If a request is ambiguous, surface the interpretations and ask. Never silently pick.
2. **Minimum viable implementation.** If 20 lines solve it, don't write 200. No speculative features, no abstractions for single-use code, no error handling for impossible scenarios.
3. **Touch only what was requested.** No drive-by refactors, reformatting, or unrequested "improvements."
4. **Define "done" before starting.** Turn the task into verifiable success criteria; for multi-step work, a plan with a check per step.
5. **Always tests.** No change merges without tests; bug fixes start with a failing test. How things are tested: [DESIGN.md § Testing](DESIGN.md#testing).

Features and scope are decided case by case with Nathan — never build speculatively. New dependencies or new kinds of surface (services, top-level directories) need his OK first.

## Branches

`main` ← `develop` ← `feature/*`. Branch off `develop`, open a pull request back into `develop`. Releases merge `develop` into `main` and are tagged there. `main` and `develop` are protected on GitHub: changes arrive only by pull request.

## Working agreements

- Keep README and DESIGN current in the same commit as the change they describe.
- Plain JavaScript, no TypeScript.
- Follow the layout of other Omarchy plugins: `manifest.json` at the root, entry QML files named for their role, logic in `*.js` model files.
- Commit style: lowercase imperative, no prefixes.
- The audience includes young children: every learner-facing string is reviewed for reading level and tone.
