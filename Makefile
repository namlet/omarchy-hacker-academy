QT_BIN ?= /usr/lib/qt6/bin

.PHONY: test test-js test-qml lint

test: test-js test-qml lint

# Lesson logic in plain JS, runs anywhere Node does.
test-js:
	node --test tests/

# Quickshell-free QML components, headless.
test-qml:
	QT_QPA_PLATFORM=offscreen $(QT_BIN)/qmltestrunner -input tests

# Panel.qml is left out: qs.* and Quickshell types only resolve inside the
# running shell, so it is checked by the manual smoke test instead.
lint:
	$(QT_BIN)/qmllint --max-warnings 0 components/*.qml tests/*.qml
