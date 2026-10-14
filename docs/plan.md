# Hacker Academy — Execution Plan

*Exactly one phase below is marked **(current)** — that marker is the single source of truth for where the project is. Do not state the current phase anywhere else, in this file or any other doc.*

Phases are sequential gates, not a schedule. Each has an exit criterion; we don't start the next until it's met (or we consciously amend this doc).

## Phase 0 — Planning *(current)*

- [x] Vision captured ([vision.md](vision.md))
- [x] Stack ADR accepted ([ADR-0001](decisions/0001-plugin-stack.md), accepted 2026-10-14)
- [x] Repo pushed to a remote — GitHub ([namlet/omarchy-hacker-academy](https://github.com/namlet/omarchy-hacker-academy), public)
- [ ] Test strategy ADR: runner, what is tested, CI — [ADR-0002](decisions/0002-test-strategy.md) proposed 2026-10-14, awaiting acceptance

**Exit:** test strategy ADR accepted.

## Phase 1 — Skeleton plugin

A plugin that installs with `omarchy plugin add`, opens, and proves the two mechanics everything else depends on: reading key holds/taps in its own surface, and seeing a real Hyprland event (a window opening). Tests and CI running.

**Exit:** installs from the GitHub URL on a clean user account; a test proves each mechanic; CI green.

## Phase 2 — Foundations lessons

Lessons 1–3 from [vision.md](vision.md) (pointer, tap vs. hold, Super combos), playtested with the first tester.

**Exit:** the first tester completes lessons 1–3 without grown-up help.

## Later phases

Scoped at the end of Phase 2: windows and workspaces, apps and menus, lock/log out/log in, rescue skills, certificate, narration, and preparing for listing.

## Process

- Branching: `main` ← `develop` ← `feature/*` (see [CLAUDE.md](../CLAUDE.md))
- All changes via PR to `develop`; releases merge `develop` to `main` and are tagged
- Docs updated in the same commit as the change
