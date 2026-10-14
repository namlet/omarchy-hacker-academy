# CLAUDE.md — Hacker Academy

Project context for agents working in this repo.

## Current phase

The phase marked *(current)* in `docs/plan.md` is the single source of truth — never restate it here or elsewhere. Standing rules regardless of phase: features and scope are decided case by case in conversation with Nathan — never build speculatively. The permission gate applies to *new surface*: new services, new top-level directories, or dependencies beyond the accepted ADRs need Nathan's explicit OK before building.

## Source of truth

- `docs/vision.md` — the product idea. If it conflicts with anything you infer, the doc wins.
- `docs/decisions/` — ADRs. Numbered, immutable once accepted; supersede rather than edit.
- `docs/plan.md` — execution plan with the current phase marked.

## Branching model

`main` ← `develop` ← `feature/*`. All changes branch off `develop` and merge back to it by PR; `develop` merges to `main` for releases, and each release is tagged on `main`. Direct commits to `main` or `develop` are blocked by the hook in `.githooks/` — always create a work branch first. After cloning, enable it once with `git config core.hooksPath .githooks`.

## Engineering principles

These bind every contributor in this repo, human or agent ("Karpathy rules" + always-tests):

1. **Ask clarifying questions before building.** If a request is ambiguous, surface the interpretations and ask — one question up front beats five rounds of revision. Never silently pick.
2. **Minimum viable implementation.** If 20 lines solve it, don't write 200. No speculative features, no abstractions for single-use code, no error handling for impossible scenarios.
3. **Touch only what was requested.** No drive-by refactors, no reformatting, no unrequested "improvements." Every changed line traces to the ask.
4. **Define "done" before starting.** Translate the task into verifiable success criteria first; for multi-step work, state a plan with a verification check per step.
5. **Always tests.** No code change merges without tests. Bug fixes start with a failing test that reproduces the bug. The test runner and CI setup are decided by ADR before the first line of plugin code.

## Working agreements

- Keep docs current in the same commit as the change they describe.
- Owner is a 30-year software vet; prefers plain JavaScript over TypeScript (a default, not a decision — stack is decided only by ADR).
- Commit style: lowercase imperative, no prefixes.
- The audience includes young children: every learner-facing string is reviewed for reading level and tone.
