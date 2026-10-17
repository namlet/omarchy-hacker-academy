QT_BIN ?= /usr/lib/qt6/bin

.PHONY: test test-js test-qml lint preview

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
	@for f in components/*.qml tests/*.qml tools/*.qml; do \
		$(QT_BIN)/qmllint --max-warnings 0 "$$f" || { echo "qmllint failed: $$f"; exit 1; }; \
	done

# Every sprite on a dark and a light theme. PNG=out.png saves a picture instead of opening a window.
preview:
ifdef PNG
	QT_QPA_PLATFORM=offscreen $(QT_BIN)/qml tools/preview.qml -- --png $(abspath $(PNG))
else
	$(QT_BIN)/qml tools/preview.qml
endif
