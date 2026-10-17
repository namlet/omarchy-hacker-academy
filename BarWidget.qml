import QtQuick
import qs.Ui

// Top-bar button: opens and closes the Academy, so learners never need a command.
BarWidget {
  id: root
  moduleName: "io.github.namlet.hacker-academy"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\u{F06A9}"
    tooltipText: "Hacker Academy"
    onPressed: function(mouseButton) {
      if (root.bar && root.bar.shell) root.bar.shell.toggle(root.moduleName, "{}")
    }
  }
}
