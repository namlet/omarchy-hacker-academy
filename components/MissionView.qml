pragma ComponentBehavior: Bound

import QtQuick
import "../Engine.js" as Engine
import "../Missions.js" as Missions
import "../Model.js" as Model

// Plays missions: the speaker and lines, the task, a short success moment after each
// step, help that grows while the learner is stuck, the on-screen keyboard, and a
// settings screen for grown-ups. No Quickshell imports; the panel passes in theme
// values, saves progress, and forwards Hyprland's window events.
//
// The size is fixed and every area keeps its space, so nothing jumps when hints
// or the keyboard appear.
FocusScope {
  id: root

  property var missions: Missions.MISSIONS
  property var progress: Engine.newProgress()
  property bool hintClock: true
  property int celebrationMs: 2000

  property color textColor: "white"
  property color dimColor: "gray"
  property color accentColor: "orange"
  property color boltColor: "deepskyblue"
  property color backgroundColor: "black"
  property string fontFamily: "monospace"
  property int fontSize: 16

  signal progressSaved(var progress)
  signal exitRequested()

  property var session: Engine.startMission(0)
  property var keys: Model.initialPressedState()
  property bool showingSettings: false
  property bool confirmingReset: false
  // Shift as a hold key: when it went down, whether anything else was pressed
  // meanwhile (so a lone quick press is a tap), and how long it has been held.
  property double shiftDownAt: 0
  property bool shiftAlone: false
  property real shiftHeldMs: 0
  property bool letGoEarly: false
  readonly property int tapMaxMs: 600

  readonly property bool finishedAll: root.session.mission >= root.missions.length
  readonly property var mission: root.finishedAll ? null : root.missions[root.session.mission]
  readonly property var step: root.finishedAll ? null : Engine.currentStep(root.missions, root.session)
  readonly property string stage: root.mission ? root.mission.stage : "center"
  readonly property bool holdKeyboard: root.mission ? root.mission.holdKeyboard : true
  // Desktop missions sit small in a corner, out of the way of the real windows.
  readonly property bool onDesktop: root.stage === "corner"
  readonly property string codename: root.session.codename || root.progress.codename
  readonly property bool celebrating: root.session.celebrating === true
  readonly property string expectType: root.step ? root.step.expect.type : ""
  readonly property bool keyTask: ["key", "codename", "anykey", "hold", "capital", "tap"].indexOf(root.expectType) !== -1
  readonly property bool shiftHeld: Model.pressedLabels(root.keys).indexOf("Shift") !== -1
  // The keyboard picture only shows when keys are the task, or a hint lights one.
  readonly property bool keyboardShown: root.step !== null && !root.showingSettings
    && (root.keyTask || (root.session.hint >= 2 && root.step.hint.keys.length > 0))

  readonly property real unit: root.fontSize * 2.4
  readonly property real pad: root.fontSize * 1.5

  // Start (or continue) at the first mission not yet completed.
  function begin() {
    root.session = Engine.resume(root.missions, root.progress)
    codenameInput.text = ""
    root.showingSettings = false
    root.confirmingReset = false
    root.focusTask()
  }

  function handle(event) {
    root.session = Engine.handle(root.missions, root.session, event)
    root.focusTask()
  }

  // A raw Hyprland event ({name, data}); windows opening and closing can finish a step.
  function windowEvent(event) {
    const w = Model.windowEvent(event)
    if (w) root.handle({ type: "window", action: w.action, app: w.app })
  }

  // Called after the success moment; finishing the last step completes the mission.
  function finishCelebration() {
    root.session = Engine.finishCelebration(root.missions, root.session)
    if (root.session.done) {
      root.progress = Engine.completeMission(root.progress, root.session.mission, root.codename)
      root.progressSaved(root.progress)
      root.begin()
    } else {
      root.progress = Engine.rememberStep(root.progress, root.session)
      root.progressSaved(root.progress)
      root.focusTask()
    }
  }

  function tick(ms) {
    if (!root.finishedAll && !root.showingSettings) root.session = Engine.tick(root.session, ms)
  }

  function focusTask() {
    Qt.callLater(function() {
      if (root.expectType === "codename" && !root.celebrating && !root.showingSettings) {
        codenameInput.forceActiveFocus()
      } else {
        // Inside this focus scope a child that once had focus keeps it, even hidden,
        // and would swallow the keys; take it back explicitly.
        codenameInput.focus = false
        root.forceActiveFocus()
      }
    })
  }

  function trackDown(event) {
    root.keys = Model.keyDown(root.keys, event.key, event.nativeScanCode)
    if (Model.keyLabel(event.key) === "Shift") {
      if (root.shiftDownAt === 0) { root.shiftDownAt = Date.now(); root.shiftAlone = true; root.letGoEarly = false }
    } else {
      root.shiftAlone = false
    }
  }

  function trackUp(event) {
    root.keys = Model.keyUp(root.keys, event.key, event.nativeScanCode)
    if (root.shiftDownAt !== 0 && !root.shiftHeld) shiftReleased()
  }

  function shiftReleased() {
    const ms = Date.now() - root.shiftDownAt
    const tapped = root.shiftAlone && ms < root.tapMaxMs
    root.letGoEarly = root.expectType === "hold" && !root.celebrating && ms >= root.tapMaxMs
    root.shiftDownAt = 0
    root.shiftHeldMs = 0
    if (tapped) root.handle({ type: "tap", key: "Shift" })
  }

  function skipMission() {
    root.progress = Engine.completeMission(root.progress, root.session.mission)
    root.progressSaved(root.progress)
    root.begin()
  }

  function resetProgress() {
    if (!root.confirmingReset) { root.confirmingReset = true; return }
    root.progress = Engine.newProgress()
    root.progressSaved(root.progress)
    root.begin()
  }

  implicitWidth: column.width + root.pad * 2
  implicitHeight: column.height + root.pad * 2

  Keys.onPressed: (event) => {
    if (event.isAutoRepeat) return
    root.trackDown(event)
    const label = Model.keyLabel(event.key)
    // Esc closes the Academy, unless pressing Esc is the task.
    if (label === "Esc" && !(root.expectType === "key" && root.step.expect.key === "Esc")) { root.exitRequested(); return }
    if (label) root.handle({ type: "key", key: label, text: event.text, shift: root.shiftHeld })
  }
  Keys.onReleased: (event) => { if (!event.isAutoRepeat) root.trackUp(event) }
  onActiveFocusChanged: if (!root.activeFocus && !codenameInput.activeFocus) {
    root.keys = Model.initialPressedState()
    root.shiftDownAt = 0
    root.shiftHeldMs = 0
  }

  // While Shift is down, report how long, for hold steps and the force-field bar.
  Timer {
    interval: 50
    repeat: true
    running: root.shiftDownAt !== 0
    onTriggered: {
      root.shiftHeldMs = Date.now() - root.shiftDownAt
      if (root.expectType === "hold") root.handle({ type: "held", key: "Shift", ms: root.shiftHeldMs })
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.hintClock && !root.finishedAll
    onTriggered: root.tick(1000)
  }

  Timer {
    interval: root.celebrationMs
    running: root.celebrating
    onTriggered: root.finishCelebration()
  }

  Column {
    id: column
    x: root.pad
    y: root.pad
    width: root.onDesktop ? root.fontSize * 30 : keyboard.implicitWidth
    spacing: root.fontSize

    // Header: mission title, the learner's name, settings. Plain, so only the task glows.
    Item {
      width: parent.width
      height: root.fontSize * 1.6

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.mission ? "Mission " + root.session.mission + ": " + root.mission.title : "Hacker Academy"
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 1.15
        font.bold: true
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.fontSize

        Text {
          visible: root.codename !== ""
          text: root.codename
          color: root.dimColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize
        }

        Text {
          objectName: "settingsButton"
          visible: !root.showingSettings
          text: Missions.UI.settings
          color: root.dimColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 0.85
          font.underline: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.showingSettings = true; root.confirmingReset = false; root.forceActiveFocus() }
          }
        }
      }
    }

    // Speaker and lines.
    Item {
      width: parent.width
      height: root.fontSize * 4
      opacity: !root.showingSettings && root.step !== null ? 1 : 0
      enabled: opacity > 0

      Rectangle {
        id: portrait
        objectName: "portrait"
        width: root.fontSize * 4
        height: root.fontSize * 4
        radius: root.fontSize / 2
        color: "transparent"
        border.width: 2
        border.color: root.step && root.step.speaker === "bolt" ? root.boltColor : root.dimColor

        Text {
          anchors.centerIn: parent
          text: root.step && root.step.speaker === "bolt" ? "BOLT" : "MENTOR"
          color: root.textColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 0.6
        }
      }

      Text {
        objectName: "lines"
        anchors.left: portrait.right
        anchors.leftMargin: root.fontSize
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.step ? Engine.render(root.step.lines.join("\n"), root.codename) : ""
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 1.15
        wrapMode: Text.Wrap
      }
    }

    // The task.
    Item {
      width: parent.width
      height: root.fontSize * 5
      opacity: !root.showingSettings && root.step !== null ? 1 : 0
      enabled: opacity > 0

      Column {
        visible: root.expectType === "button"
        anchors.centerIn: parent
        spacing: root.fontSize / 2

        Rectangle {
          objectName: root.expectType === "button" ? "button-" + root.step.expect.id : "taskButton"
          anchors.horizontalCenter: parent.horizontalCenter
          width: buttonLabel.implicitWidth + root.fontSize * 3
          height: root.fontSize * 3
          radius: root.fontSize / 2
          color: buttonArea.containsMouse || root.celebrating ? root.accentColor : "transparent"
          border.color: root.accentColor
          border.width: 2

          Text {
            id: buttonLabel
            anchors.centerIn: parent
            text: root.step && root.step.expect.label ? root.step.expect.label : ""
            color: buttonArea.containsMouse || root.celebrating ? root.backgroundColor : root.accentColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize * 1.1
            font.bold: true
          }

          MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.handle({ type: "button", id: root.step.expect.id })
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: root.step !== null && root.step.expect.key !== undefined
          text: Missions.UI.orEnter
          color: root.dimColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 0.85
        }
      }

      // Labelled tasks: what to do, a tally, and what the step shows (typed letters,
      // the force-field bar, or Bolt's shouting and alarm).
      Column {
        visible: root.expectType !== "button" && root.step !== null && root.step.expect.label !== undefined
        anchors.centerIn: parent
        spacing: root.fontSize / 3

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: root.fontSize

          Text {
            objectName: "instruction"
            text: root.step && root.step.expect.label ? root.step.expect.label : ""
            color: root.accentColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize * 1.2
            font.bold: true
          }

          Text {
            objectName: "tally"
            visible: (root.expectType === "pointer" && root.step.expect.ids.length > 1) || root.expectType === "anykey"
            text: root.expectType === "pointer" ? root.session.hits.length + " of " + root.step.expect.ids.length
              : root.expectType === "anykey" ? root.session.count + " of " + root.step.expect.times : ""
            color: root.dimColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // The shortcut to press, since Omarchy's shortcuts never reach the Academy's keyboard.
        Row {
          objectName: "combo"
          visible: root.step !== null && root.step.combo !== undefined
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: root.fontSize / 2

          Repeater {
            model: root.step && root.step.combo ? root.step.combo : []

            Row {
              id: comboKey
              required property string modelData
              required property int index
              spacing: root.fontSize / 2

              Text {
                visible: comboKey.index > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                color: root.dimColor
                font.family: root.fontFamily
                font.pixelSize: root.fontSize * 1.2
              }

              Rectangle {
                id: comboCap
                objectName: "combo-" + comboKey.modelData
                property bool lit: root.celebrating || root.session.hint >= 2
                width: Math.max(comboLabel.implicitWidth + root.fontSize, root.fontSize * 2.4)
                height: root.fontSize * 2.2
                radius: root.fontSize / 3
                color: comboCap.lit ? root.accentColor : "transparent"
                border.color: root.accentColor
                border.width: 2

                Text {
                  id: comboLabel
                  anchors.centerIn: parent
                  text: comboKey.modelData
                  color: comboCap.lit ? root.backgroundColor : root.textColor
                  font.family: root.fontFamily
                  font.pixelSize: root.fontSize
                  font.bold: true
                }
              }
            }
          }
        }

        Text {
          objectName: "typed"
          visible: root.step !== null && root.step.display === "typed"
          anchors.horizontalCenter: parent.horizontalCenter
          text: (root.session.typed || "").split("").join(" ")
          color: root.celebrating ? root.accentColor : root.boltColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 2.2
          font.bold: true
        }

        Item {
          objectName: "shield"
          visible: root.step !== null && root.step.display === "shield"
          anchors.horizontalCenter: parent.horizontalCenter
          width: root.fontSize * 20
          height: root.fontSize * 2

          Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "transparent"
            border.color: root.accentColor
            border.width: 2
          }

          Rectangle {
            objectName: "shieldFill"
            height: parent.height
            radius: height / 2
            color: root.accentColor
            opacity: 0.8
            width: root.celebrating ? parent.width
              : root.expectType === "hold" ? parent.width * Math.min(1, root.shiftHeldMs / root.step.expect.ms) : 0
          }

          Text {
            anchors.centerIn: parent
            visible: root.letGoEarly && !root.celebrating
            text: Missions.UI.keepHolding
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: true
          }
        }

        Text {
          id: loudText
          objectName: "loud"
          visible: root.step !== null && root.step.display === "loud"
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.step && root.step.loud ? (root.celebrating ? root.step.quiet : root.step.loud) : ""
          color: root.celebrating ? root.textColor : root.accentColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 1.8
          font.bold: !root.celebrating

          SequentialAnimation on opacity {
            running: !root.celebrating && root.step !== null && root.step.display === "loud"
            loops: Animation.Infinite
            onStopped: loudText.opacity = 1
            NumberAnimation { to: 0.3; duration: 250 }
            NumberAnimation { to: 1; duration: 250 }
          }
        }
      }

      // Bolt's typo, with a blinking cursor where Backspace erases.
      Row {
        visible: root.step !== null && root.step.field !== undefined
        anchors.centerIn: parent
        spacing: root.fontSize * 0.1

        Text {
          id: fieldText
          objectName: "field"
          text: root.step && root.step.field ? root.step.field.slice(0, root.step.field.length - root.session.count) : ""
          color: root.celebrating ? root.accentColor : root.boltColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 2.6
          font.bold: true

          SequentialAnimation on scale {
            running: root.celebrating
            loops: Animation.Infinite
            NumberAnimation { to: 1.2; duration: 300; easing.type: Easing.OutQuad }
            NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.InQuad }
          }
        }

        Rectangle {
          objectName: "cursor"
          visible: !root.celebrating
          width: root.fontSize * 0.25
          height: fieldText.height * 0.8
          anchors.verticalCenter: fieldText.verticalCenter
          color: root.boltColor

          SequentialAnimation on opacity {
            running: !root.celebrating
            loops: Animation.Infinite
            NumberAnimation { to: 0; duration: 500 }
            NumberAnimation { to: 1; duration: 500 }
          }
        }
      }

      Rectangle {
        visible: root.expectType === "codename"
        anchors.centerIn: parent
        width: root.fontSize * 18
        height: root.fontSize * 2.6
        radius: root.fontSize / 3
        color: "transparent"
        border.color: codenameInput.activeFocus || root.celebrating ? root.accentColor : root.dimColor
        border.width: 2

        TextInput {
          id: codenameInput
          objectName: "codenameInput"
          anchors.fill: parent
          anchors.margins: root.fontSize / 2
          verticalAlignment: TextInput.AlignVCenter
          maximumLength: 16
          readOnly: root.celebrating
          color: root.celebrating ? root.accentColor : root.textColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 1.3
          Keys.onPressed: (event) => {
            root.trackDown(event)
            if (event.key === Qt.Key_Escape) { root.exitRequested(); event.accepted = true; return }
            event.accepted = false
          }
          Keys.onReleased: (event) => { root.trackUp(event); event.accepted = false }
          onAccepted: root.handle({ type: "submit", value: codenameInput.text })

          Text {
            visible: codenameInput.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: Missions.UI.codenamePrompt
            color: root.dimColor
            font: codenameInput.font
          }
        }
      }

      Rectangle {
        objectName: "badge"
        visible: root.step !== null && root.step.badge !== undefined
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: badgeText.implicitWidth + root.fontSize * 2
        height: root.fontSize * 2.2
        radius: height / 2
        color: "transparent"
        border.color: root.accentColor
        border.width: 2

        Text {
          id: badgeText
          anchors.centerIn: parent
          text: root.step && root.step.badge ? root.step.badge.toUpperCase() : ""
          color: root.accentColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize
          font.bold: true
        }
      }
    }

    // Feedback: the success line, or help that grows (Bolt's hint, then the Mentor's demo).
    // Always takes its space, so the window never grows.
    Column {
      width: parent.width
      height: root.fontSize * 5.5
      spacing: root.fontSize / 2
      opacity: !root.showingSettings ? 1 : 0

      Text {
        objectName: "success"
        width: parent.width
        visible: root.celebrating
        text: root.step && root.celebrating
          ? (root.step.success.speaker === "bolt" ? "Bolt: " : "Mentor: ") + Engine.render(root.step.success.line, root.codename)
          : ""
        color: root.accentColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 1.15
        font.bold: true
        wrapMode: Text.Wrap
      }

      Text {
        objectName: "boltHint"
        width: parent.width
        visible: root.step !== null && !root.celebrating && root.session.hint >= 1
        text: root.step ? "Bolt: " + root.step.hint.bolt : ""
        color: root.boltColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        wrapMode: Text.Wrap
      }

      Text {
        objectName: "demoHint"
        width: parent.width
        visible: root.step !== null && !root.celebrating && root.session.hint >= 3
        text: root.step ? "Mentor: " + root.step.hint.demo : ""
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        wrapMode: Text.Wrap
      }

      Text {
        objectName: "comingSoon"
        width: parent.width
        visible: root.finishedAll
        text: Missions.UI.comingSoon
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 1.15
        wrapMode: Text.Wrap
      }
    }

    // The keyboard keeps its space even when hidden; pointer steps play in the same space.
    // Desktop missions have neither.
    Item {
      visible: !root.onDesktop
      width: keyboard.implicitWidth
      height: keyboard.implicitHeight

    PointerPlayground {
      id: playground
      objectName: "playground"
      anchors.fill: parent
      visible: root.expectType === "pointer" && !root.showingSettings
      enabled: !root.celebrating
      play: root.step && root.step.play ? root.step.play : ""
      hits: root.session.hits
      highlight: root.session.hint >= 2
      textColor: root.textColor
      dimColor: root.dimColor
      accentColor: root.accentColor
      boltColor: root.boltColor
      fontFamily: root.fontFamily
      fontSize: root.fontSize
      keepScrollingText: Missions.UI.keepScrolling
      onPointerEvent: (event) => root.handle(event)
    }

    OnScreenKeyboard {
      id: keyboard
      objectName: "keyboard"
      opacity: root.keyboardShown ? 1 : 0
      pressed: Model.pressedLabels(root.keys)
      lit: root.step && root.session.hint >= 2 ? root.step.hint.keys : []
      textColor: root.textColor
      dimColor: root.dimColor
      accentColor: root.accentColor
      fontFamily: root.fontFamily
      unit: root.unit

      Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Missions.UI.close
      color: root.dimColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize * 0.8

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.exitRequested()
      }
    }
  }

  // Settings, for grown-ups: drawn over the mission area, same window size.
  Column {
    objectName: "settings"
    visible: root.showingSettings
    x: root.pad
    y: root.pad + root.fontSize * 3
    spacing: root.fontSize

    Repeater {
      model: [
        { id: "skip", label: "Skip this mission", enabled: !root.finishedAll },
        { id: "reset", label: root.confirmingReset ? "Click again to erase all progress" : "Reset all progress", enabled: true },
        { id: "back", label: "Back", enabled: true }
      ]

      Text {
        id: settingsItem
        required property var modelData
        objectName: "settings-" + settingsItem.modelData.id
        visible: settingsItem.modelData.enabled
        text: settingsItem.modelData.label
        color: settingsItem.modelData.id === "reset" && root.confirmingReset ? root.accentColor : root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.underline: true

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (settingsItem.modelData.id === "skip") root.skipMission()
            else if (settingsItem.modelData.id === "reset") root.resetProgress()
            else { root.showingSettings = false; root.focusTask() }
          }
        }
      }
    }
  }
}
