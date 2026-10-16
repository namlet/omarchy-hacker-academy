pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../Engine.js" as Engine
import "../Missions.js" as Missions
import "../Model.js" as Model

// Plays missions: the speaker and lines, the task, help that grows while the
// learner is stuck, the on-screen keyboard, and a settings screen for grown-ups.
// No Quickshell imports; the panel passes in theme values and saves progress.
FocusScope {
  id: root

  property var missions: Missions.MISSIONS
  property var progress: Engine.newProgress()
  property bool hintClock: true

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

  readonly property bool finishedAll: root.session.mission >= root.missions.length
  readonly property var mission: root.finishedAll ? null : root.missions[root.session.mission]
  readonly property var step: root.finishedAll ? null : Engine.currentStep(root.missions, root.session)
  readonly property string stage: root.mission ? root.mission.stage : "center"
  readonly property bool holdKeyboard: root.mission ? root.mission.holdKeyboard : true
  readonly property string codename: root.session.codename || root.progress.codename

  // Start (or continue) at the first mission not yet completed.
  function begin() {
    root.session = Engine.startMission(Engine.nextMission(root.missions, root.progress))
    root.showingSettings = false
    root.confirmingReset = false
    root.focusTask()
  }

  function handle(event) {
    root.session = Engine.handle(root.missions, root.session, event)
    if (root.session.done) {
      root.progress = Engine.completeMission(root.progress, root.session.mission, root.codename)
      root.progressSaved(root.progress)
      root.begin()
    } else {
      root.focusTask()
    }
  }

  function tick(ms) {
    if (!root.finishedAll && !root.showingSettings) root.session = Engine.tick(root.session, ms)
  }

  function focusTask() {
    Qt.callLater(function() {
      if (root.step && root.step.expect.type === "codename" && !root.showingSettings) {
        codenameInput.forceActiveFocus()
      } else {
        // Inside this focus scope a child that once had focus keeps it, even hidden,
        // and would swallow the keys; take it back explicitly.
        codenameInput.focus = false
        root.forceActiveFocus()
      }
    })
  }

  function trackDown(event) { root.keys = Model.keyDown(root.keys, event.key, event.nativeScanCode) }
  function trackUp(event) { root.keys = Model.keyUp(root.keys, event.key, event.nativeScanCode) }

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

  implicitWidth: layout.implicitWidth + root.fontSize * 3
  implicitHeight: layout.implicitHeight + root.fontSize * 3

  Keys.onPressed: (event) => {
    root.trackDown(event)
    if (event.key === Qt.Key_Escape) { root.exitRequested(); return }
    if (!event.isAutoRepeat) {
      var label = Model.keyLabel(event.key)
      if (label) root.handle({ type: "key", key: label })
    }
  }
  Keys.onReleased: (event) => { if (!event.isAutoRepeat) root.trackUp(event) }
  onActiveFocusChanged: if (!root.activeFocus && !codenameInput.activeFocus) root.keys = Model.initialPressedState()

  Timer {
    interval: 1000
    repeat: true
    running: root.hintClock && !root.finishedAll
    onTriggered: root.tick(1000)
  }

  ColumnLayout {
    id: layout
    anchors.centerIn: parent
    width: keyboard.implicitWidth
    spacing: root.fontSize

    // Header: mission title, the learner's name, settings.
    RowLayout {
      Layout.fillWidth: true

      Text {
        Layout.fillWidth: true
        text: root.mission ? "Mission " + root.session.mission + ": " + root.mission.title : "Hacker Academy"
        color: root.accentColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 1.25
        font.bold: true
      }

      Text {
        visible: root.codename !== ""
        text: root.codename
        color: root.dimColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }

      Text {
        objectName: "settingsButton"
        text: root.showingSettings ? "" : Missions.UI.settings
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

    // Speaker and lines.
    RowLayout {
      visible: !root.showingSettings && root.step !== null
      Layout.fillWidth: true
      spacing: root.fontSize

      Rectangle {
        objectName: "portrait"
        Layout.preferredWidth: root.fontSize * 4
        Layout.preferredHeight: root.fontSize * 4
        Layout.alignment: Qt.AlignTop
        radius: root.fontSize / 2
        color: "transparent"
        border.width: 2
        border.color: root.step && root.step.speaker === "bolt" ? root.boltColor : root.accentColor

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
        Layout.fillWidth: true
        text: root.step ? Engine.render(root.step.lines.join("\n"), root.codename) : ""
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 1.15
        wrapMode: Text.Wrap
      }
    }

    // The task.
    Item {
      visible: !root.showingSettings && root.step !== null
      Layout.fillWidth: true
      Layout.preferredHeight: root.fontSize * 4

      Rectangle {
        objectName: root.step && root.step.expect.type === "button" ? "button-" + root.step.expect.id : "taskButton"
        visible: root.step !== null && root.step.expect.type === "button"
        anchors.centerIn: parent
        width: buttonLabel.implicitWidth + root.fontSize * 3
        height: root.fontSize * 3
        radius: root.fontSize / 2
        color: buttonArea.containsMouse ? root.accentColor : "transparent"
        border.color: root.accentColor
        border.width: 2

        Text {
          id: buttonLabel
          anchors.centerIn: parent
          text: root.step && root.step.expect.label ? root.step.expect.label : ""
          color: buttonArea.containsMouse ? root.backgroundColor : root.accentColor
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
        objectName: "field"
        visible: root.step !== null && root.step.field !== undefined
        anchors.centerIn: parent
        text: root.step && root.step.field ? root.step.field.slice(0, root.step.field.length - root.session.count) : ""
        color: root.boltColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 2.4
        font.bold: true
      }

      Rectangle {
        visible: root.step !== null && root.step.expect.type === "codename"
        anchors.centerIn: parent
        width: root.fontSize * 18
        height: root.fontSize * 2.6
        radius: root.fontSize / 3
        color: "transparent"
        border.color: codenameInput.activeFocus ? root.accentColor : root.dimColor
        border.width: 2

        TextInput {
          id: codenameInput
          objectName: "codenameInput"
          anchors.fill: parent
          anchors.margins: root.fontSize / 2
          verticalAlignment: TextInput.AlignVCenter
          maximumLength: 16
          color: root.textColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize * 1.3
          Keys.onPressed: (event) => {
            root.trackDown(event)
            if (event.key === Qt.Key_Escape) { root.exitRequested(); event.accepted = true; return }
            event.accepted = false
          }
          Keys.onReleased: (event) => { root.trackUp(event); event.accepted = false }
          onAccepted: {
            var before = root.session
            root.handle({ type: "submit", value: codenameInput.text })
            if (root.session !== before) codenameInput.text = ""
          }

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
        color: root.accentColor

        Text {
          id: badgeText
          anchors.centerIn: parent
          text: root.step && root.step.badge ? root.step.badge.toUpperCase() : ""
          color: root.backgroundColor
          font.family: root.fontFamily
          font.pixelSize: root.fontSize
          font.bold: true
        }
      }
    }

    // Help that grows: Bolt's hint, then lit keys (below), then the Mentor's demo.
    Text {
      objectName: "boltHint"
      visible: !root.showingSettings && root.step !== null && root.session.hint >= 1
      Layout.fillWidth: true
      text: root.step ? "Bolt: " + root.step.hint.bolt : ""
      color: root.boltColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      wrapMode: Text.Wrap
    }

    Text {
      objectName: "demoHint"
      visible: !root.showingSettings && root.step !== null && root.session.hint >= 3
      Layout.fillWidth: true
      text: root.step ? "Mentor: " + root.step.hint.demo : ""
      color: root.accentColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      wrapMode: Text.Wrap
    }

    // Every mission is done for now.
    Text {
      objectName: "comingSoon"
      visible: !root.showingSettings && root.finishedAll
      Layout.fillWidth: true
      text: Missions.UI.comingSoon
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize * 1.15
      wrapMode: Text.Wrap
    }

    // Settings, for grown-ups.
    ColumnLayout {
      objectName: "settings"
      visible: root.showingSettings
      Layout.fillWidth: true
      spacing: root.fontSize / 2

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
          color: settingsItem.modelData.id === "reset" && root.confirmingReset ? root.boltColor : root.textColor
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

    OnScreenKeyboard {
      id: keyboard
      objectName: "keyboard"
      visible: !root.showingSettings
      Layout.alignment: Qt.AlignHCenter
      pressed: Model.pressedLabels(root.keys)
      lit: root.step && root.session.hint >= 2 ? root.step.hint.keys : []
      textColor: root.textColor
      dimColor: root.dimColor
      accentColor: root.accentColor
      fontFamily: root.fontFamily
      unit: root.fontSize * 2.4
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
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
}
