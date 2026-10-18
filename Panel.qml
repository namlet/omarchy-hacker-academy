import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import "components"
import "Engine.js" as Engine
import "Theme.js" as Theme

// Shell adapter: shows the mission view, loads and saves progress, and places the
// window for the current mission. No lesson logic here — it lives in Engine.js,
// Missions.js, Model.js and components/, where it is tested.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  // Outside the plugin folder: the shell reloads plugins when files there change.
  readonly property string progressPath:
    (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/io.github.namlet.hacker-academy.json"

  function open(payloadJson) {
    root.opened = true
    view.begin()
    // Play on a workspace of its own, away from anyone else's windows.
    const ws = Hyprland.focusedWorkspace
    if (ws && view.needsOwnWorkspace(ws.toplevels.values.map(function(t) { return t.address })))
      Hyprland.dispatch('hl.dsp.focus({ workspace = "empty" })')
    // The window maps after open() returns; take keyboard focus once it exists.
    Qt.callLater(function() {
      if (root.opened) view.focusTask()
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.namlet.hacker-academy")
    else close()
  }

  // The theme's full color list (green, yellow, darker backgrounds), which the shell's
  // Color doesn't carry. Reread when the shell's colors change, i.e. on a theme switch.
  property string themeColors: ""
  readonly property var academyTheme: Theme.palette(Theme.parseColors(root.themeColors), {
    background: String(Color.background), foreground: String(Color.foreground), accent: String(Color.accent),
    urgent: String(Color.urgent), muted: String(Color.muted)
  })

  FileView {
    id: colorsFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    printErrors: false
    onLoaded: root.themeColors = colorsFile.text()
    onLoadFailed: root.themeColors = ""
  }

  Connections {
    target: Color
    function onAccentChanged() { colorsFile.reload() }
    function onBackgroundChanged() { colorsFile.reload() }
  }

  FileView {
    id: progressFile
    path: root.progressPath
    atomicWrites: true
    printErrors: false
    onLoaded: { view.progress = Engine.parseProgress(progressFile.text()); view.begin() }
    onLoadFailed: { view.progress = Engine.newProgress(); view.begin() }
    onSaveFailed: (error) => console.warn("Hacker Academy: could not save progress to " + root.progressPath + " (error " + error + ")")
  }

  // Windows opening and closing on the real desktop, for missions played there.
  Connections {
    target: Hyprland
    enabled: root.opened
    function onRawEvent(event) {
      if (event) view.windowEvent({ name: String(event.name), data: String(event.data) })
    }
  }

  PanelWindow {
    visible: root.opened
    // Centered for missions inside the panel; a corner when the real desktop is the stage.
    anchors {
      bottom: view.stage === "corner"
      right: view.stage === "corner"
    }
    margins { bottom: Style.space(24); right: Style.space(24) }
    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight
    color: "transparent"
    // Stay clear of the bar when sitting in a corner.
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.namespace: "hacker-academy"
    // Desktop missions sit above full-screen windows, so the next step stays in sight.
    WlrLayershell.layer: view.stage === "corner" ? WlrLayer.Overlay : WlrLayer.Top
    // The Academy holds the keyboard so a drifting pointer can't take it (Omarchy
    // focuses whatever is under the mouse), and lets go for steps done in other windows.
    WlrLayershell.keyboardFocus: view.keyboardFocus === "none" ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    MissionView {
      id: view
      anchors.fill: parent
      focus: true
      theme: root.academyTheme
      fontFamily: Style.font.family
      fontSize: Math.round(Style.font.body * 1.3)
      hintClock: root.opened
      onProgressSaved: (progress) => progressFile.setText(Engine.serializeProgress(progress))
      onExitRequested: root.dismiss()
    }
  }
}
