# Hacker Academy

An Omarchy shell plugin that teaches new users — starting with kids who have only ever used a tablet — how to drive Omarchy: the pointer, the keyboard (including which keys you *hold* and which you *tap*), windows, workspaces, launching apps, and locking or logging out.

The learner trains as a white-hat hacker recruit. Lessons ask them to do real things on the real desktop, and the Academy notices when they do. See [DESIGN.md](DESIGN.md) for the plan.

> **Status: early.** Missions 0–8 are playable, from Recruitment to Lockdown. Mission 9 is coming. Lockdown locks the screen and logs out, so play it on the learner's own account. From mission 3 on, the Academy waits in a corner while the learner uses the real desktop: it opens and closes a terminal and a browser.

## Install

```bash
omarchy plugin add https://github.com/namlet/omarchy-hacker-academy --enable
```

## Open

Click the robot button in the top bar. Or from a terminal:

```bash
omarchy-shell shell toggle io.github.namlet.hacker-academy
```

Press Esc, or click "close", to dismiss it. Progress is saved to `~/.local/state/io.github.namlet.hacker-academy.json` and picks up where the learner left off. **Settings** in the panel lets a grown-up skip a mission, reset progress, or switch the characters between their own 8-bit colors and the current Omarchy theme's.

## Update

```bash
omarchy plugin update io.github.namlet.hacker-academy
omarchy restart shell
```

Restart the shell after updating: it keeps a cached list of each plugin's files, so files added by an update aren't found until it restarts.

## Remove

```bash
omarchy plugin remove io.github.namlet.hacker-academy
```

## Development

Requires `nodejs` and `qt6-declarative` (both in the Arch repos).

```bash
make test   # Node tests for the logic, headless QML tests, and qmllint
```

Branches and contribution rules: [AGENTS.md](AGENTS.md).

## License

[MIT](LICENSE)
