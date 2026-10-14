# Hacker Academy

An Omarchy shell plugin that teaches new users — starting with kids who have only ever used a tablet — how to drive Omarchy: the pointer, the keyboard (including which keys you *hold* and which you *tap*), windows, workspaces, launching apps, and locking or logging out.

The learner trains as a white-hat hacker recruit. Lessons ask them to do real things on the real desktop, and the Academy notices when they do. See [DESIGN.md](DESIGN.md) for the plan.

> **Status: early skeleton.** It opens a small coach panel that lights up while Shift is held, counts tapped keys, and notices when a window opens. No lessons yet.

## Install

```bash
omarchy plugin add https://github.com/namlet/omarchy-hacker-academy --enable
```

## Open

```bash
omarchy-shell shell summon io.github.namlet.hacker-academy
```

Click the panel to give it the keyboard. Press Esc, or click "close", to dismiss it.

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
