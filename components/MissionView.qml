pragma ComponentBehavior: Bound

import QtQuick
import "../Engine.js" as Engine
import "../Missions.js" as Missions
import "../Model.js" as Model
import "../Theme.js" as Theme
import "../Sprites.js" as Sprites

// Plays missions in a terminal-style window: a title bar, the progress strip, the
// mission header, who's talking, the task, and a key bar. Rank-ups get their own
// moment, settings and the campaign map take the body's place. No Quickshell
// imports; the panel passes in the theme, saves progress, and forwards Hyprland's
// window events.
//
// The size is fixed and every area keeps its space, so nothing jumps when hints
// or the keyboard appear. Desktop missions use a smaller window in a corner.
FocusScope {
  id: root

  property var missions: Missions.MISSIONS
  property var progress: Engine.newProgress()
  property bool hintClock: true
  property int celebrationMs: 2000

  property var theme: Theme.DEFAULT_PALETTE
  property string fontFamily: "monospace"
  property int fontSize: 16

  signal progressSaved(var progress)
  signal exitRequested()

  property var session: Engine.startMission(0)
  // Workspaces are rooms: home is where the Academy plays, the secret room an empty
  // one nearby. The panel picks them when it opens; 0 until then.
  property int homeRoom: 0
  property int secretRoom: 0
  // This login session (XDG_SESSION_ID), so a step can tell the learner logged out and back in.
  property string loginSession: ""
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
  // The blinking cursor after what's being said.
  property bool caretOn: true

  readonly property bool finishedAll: root.session.mission >= root.missions.length
  readonly property var mission: root.finishedAll ? null : root.missions[root.session.mission]
  readonly property var step: root.finishedAll ? null : Engine.currentStep(root.missions, root.session)
  readonly property string stage: root.mission ? root.mission.stage : "center"
  // How the window takes the keyboard: held, so Enter and the keys of keyboard tasks
  // always reach it; but never during a step done in the learner's own windows, so
  // the pointer resting on this window can't pull focus away from them.
  readonly property string keyboardFocus: root.desktopTask ? "none" : "exclusive"
  // Steps done on the real desktop with Omarchy's shortcuts.
  readonly property bool desktopTask: ["window", "focus", "fullscreen", "swap", "float", "move", "resize", "workspace", "carry", "menu", "lock", "login"].indexOf(root.expectType) !== -1
  // Which step is being played, as text that changes whenever the step does.
  readonly property string stepKey: root.session.mission + ":" + root.session.step
  // Steps whose action sends no event: the panel reports window positions meanwhile.
  readonly property bool watchesLayout: ["swap", "move", "resize"].indexOf(root.expectType) !== -1
  // The screen locking sends no event either: the panel asks while a step needs it.
  readonly property bool watchesLock: root.expectType === "lock"
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
  // Tasks done several times (bugs to catch, letters to tap) show a meter.
  readonly property bool counted: root.countGoal > 1
  readonly property int countDone: root.expectType === "pointer" ? root.session.hits.length : root.session.count
  readonly property int countGoal: root.expectType === "pointer" ? root.step.expect.ids.length
    : root.expectType === "anykey" || root.expectType === "window" ? (root.step.expect.times || 1) : 0
  readonly property string countLabel: root.expectType === "pointer" ? Missions.UI.caught
    : root.expectType === "anykey" ? Missions.UI.tapped
    : root.step && root.step.expect.action === "close" ? Missions.UI.closed : Missions.UI.opened
  // Who's talking: their name, picture, and the color of their name.
  readonly property var speakers: ({
    mentor: { name: "The Mentor", sprite: "mentor", color: root.theme.text },
    bolt: { name: "Bolt", sprite: "bolt", color: root.theme.cyan },
    glitch: { name: "The Glitch", sprite: "glitch", color: root.theme.magenta }
  })
  readonly property string characterColors: Engine.settingsOf(root.progress).characterColors

  // Ranks and missions, for the progress strip, title bar, and map.
  readonly property var campaign: Engine.campaignView(Missions.CAMPAIGN, root.progress, root.finishedAll ? -1 : root.session.mission)
  readonly property int rankIndex: Engine.rankIndex(Missions.CAMPAIGN, root.progress)
  readonly property string rank: root.rankIndex >= 0 ? Missions.CAMPAIGN.ranks[root.rankIndex].name : ""
  // A step that awards a rank is shown as the rank-up moment.
  readonly property bool rankUp: root.step !== null && root.step.badge !== undefined && !root.showingSettings
  readonly property string speaker: root.step ? (root.celebrating ? root.step.success.speaker : root.step.speaker) : "mentor"

  readonly property real f: root.fontSize
  readonly property real pad: root.f * (root.onDesktop ? 0.9 : 1.3)
  readonly property real windowWidth: root.f * (root.onDesktop ? 28 : 46)
  readonly property real bodyHeight: root.f * (root.onDesktop ? 15.5 : 32)

  // Start (or continue) at the first mission not yet completed.
  function begin() {
    root.session = Engine.resume(root.missions, root.progress, root.session)
    codenameInput.text = ""
    root.showingSettings = false
    root.confirmingReset = false
    root.focusTask()
  }

  function handle(event) {
    root.session = Engine.handle(root.missions, root.session, event)
    root.focusTask()
  }

  // A raw Hyprland event ({name, data}); windows opening, closing, taking the keyboard,
  // or going full screen can finish a step.
  function windowEvent(event) {
    const w = Model.windowEvent(event)
    const room = w && w.workspace !== undefined
      ? (w.workspace === root.homeRoom ? "home" : w.workspace === root.secretRoom ? "room" : "other") : undefined
    if (w) root.handle({ type: "window", action: w.action, address: w.address, app: w.app, on: w.on, room: room })
  }

  // The Academy opened: in another login than the remembered step, a log-out step is done.
  function arrive() {
    root.handle({ type: "login", id: root.loginSession })
  }

  // Whether the screen is locked, asked while a step needs it.
  function lockState(on) {
    root.handle({ type: "lock", on: on })
  }

  // Where a window is: {address, at: [x, y], size: [w, h], floating}, from Hyprland.
  // The numbers are copied: Quickshell's lists change in place when it refreshes, which
  // would move a step's starting point along with the window.
  function windowGeometry(place) {
    root.handle({
      type: "window", action: "geometry", address: Model.windowAddress(place.address),
      at: [Number(place.at[0]), Number(place.at[1])], size: [Number(place.size[0]), Number(place.size[1])],
      floating: place.floating === true
    })
  }

  // Given the addresses of the windows on the current workspace: should the Academy
  // move to an empty one before the learner starts?
  function needsOwnWorkspace(addresses) {
    return Model.needsOwnWorkspace(addresses, root.session.windows.map(function(w) { return w.address }))
  }

  // Called after the success moment; finishing the last step completes the mission.
  function finishCelebration() {
    root.session = Engine.finishCelebration(root.missions, root.session)
    if (root.session.done) {
      root.progress = Engine.completeMission(root.progress, root.session.mission, root.codename)
      root.progressSaved(root.progress)
      root.begin()
    } else {
      root.progress = Engine.rememberStep(root.progress, root.session, root.loginSession)
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
    root.progress = Engine.resetProgress(root.progress)
    root.progressSaved(root.progress)
    root.begin()
  }

  function toggleCharacterColors() {
    root.progress = Engine.withSettings(root.progress, { characterColors: root.characterColors === "theme" ? "classic" : "theme" })
    root.progressSaved(root.progress)
  }

  // Mission text with the codename and room numbers filled in.
  function say(text) {
    return Engine.render(text, root.codename)
      .replace(/\{home\}/g, root.homeRoom > 0 ? root.homeRoom : "?")
      .replace(/\{room\}/g, root.secretRoom > 0 ? root.secretRoom : "?")
  }

  // Lines as rich text, with the blinking cursor at the end.
  function withCaret(text) {
    const safe = String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\n/g, "<br>")
    return safe + " <font color=\"" + (root.caretOn ? root.theme.accent : root.theme.ground) + "\">█</font>"
  }

  implicitWidth: root.windowWidth
  implicitHeight: layout.height

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

  Timer {
    interval: 530
    repeat: true
    running: root.hintClock
    onTriggered: root.caretOn = !root.caretOn
  }

  // The window, with a gold edge while a rank is being awarded.
  Rectangle {
    anchors.fill: parent
    color: root.theme.ground
    border.width: 1
    border.color: root.rankUp ? root.theme.rank : root.onDesktop ? root.theme.accent : root.theme.line
  }

  // A key cap in the key bar, with what it does; clickable too.
  component KeyHint: Item {
    id: hint
    property string key: ""
    property string action: ""
    signal clicked()
    implicitWidth: hintRow.implicitWidth
    implicitHeight: hintRow.implicitHeight

    Row {
      id: hintRow
      spacing: root.f * 0.4

      Rectangle {
        width: keyText.implicitWidth + root.f * 0.6
        height: keyText.implicitHeight + root.f * 0.1
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.width: 1
        border.color: root.theme.faint

        Text {
          id: keyText
          anchors.centerIn: parent
          text: hint.key
          color: root.theme.text
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.7
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: hint.action
        color: root.theme.quiet
        font.family: root.fontFamily
        font.pixelSize: root.f * 0.72
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: hint.clicked()
    }
  }

  Column {
    id: layout
    width: root.windowWidth

    // Title bar: the Academy, the part, and the learner (or, on the desktop, where they are).
    Rectangle {
      width: parent.width
      height: root.f * (root.onDesktop ? 2 : 2.4)
      color: root.theme.bars
      border.width: 1
      border.color: root.theme.line

      Row {
        anchors.left: parent.left
        anchors.leftMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.f * 0.9

        Text {
          text: "▌HACKER ACADEMY"
          color: root.theme.accent
          font.family: root.fontFamily
          font.pixelSize: root.f * (root.onDesktop ? 0.75 : 0.9)
          font.weight: Font.Black
          font.letterSpacing: root.f * 0.12
        }

        Text {
          visible: !root.onDesktop
          text: "// " + Missions.CAMPAIGN.part.toLowerCase()
          color: root.theme.quiet
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.9
        }
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.f * 0.9

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.onDesktop && root.mission !== null
          text: root.mission ? "M" + Engine.missionNumber(root.session.mission) + " · step " + (root.session.step + 1) + " / " + root.mission.steps.length : ""
          color: root.theme.quiet
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.72
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: !root.onDesktop && root.codename !== ""
          text: root.codename
          color: root.theme.text
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.8
          font.bold: true
        }

        Rectangle {
          objectName: "rankChip"
          anchors.verticalCenter: parent.verticalCenter
          visible: !root.onDesktop && root.rank !== ""
          width: chipRow.implicitWidth + root.f * 0.9
          height: Math.max(root.f * 1.5, 25)
          color: "transparent"
          border.width: 1
          border.color: root.theme.done

          Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: root.f * 0.35

            PixelSprite {
              anchors.verticalCenter: parent.verticalCenter
              width: 20
              height: 21
              sprite: Sprites.BADGES[root.rank] || ""
              theme: root.theme
              mode: root.characterColors
            }

            Text {
              objectName: "rankChipText"
              anchors.verticalCenter: parent.verticalCenter
              text: root.rank.toUpperCase()
              color: root.theme.done
              font.family: root.fontFamily
              font.pixelSize: root.f * 0.72
              font.bold: true
              font.letterSpacing: root.f * 0.08
            }
          }
        }
      }
    }

    // Progress strip: every mission of the part, grouped by rank.
    Item {
      width: parent.width
      height: strip.height + root.f * (root.onDesktop ? 1.1 : 1.6)

      ProgressStrip {
        id: strip
        objectName: "progressStrip"
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - root.pad * 2 - (root.onDesktop ? stripRank.width + root.f : 0)
        height: implicitHeight
        ranks: root.campaign
        compact: root.onDesktop
        theme: root.theme
        fontFamily: root.fontFamily
        fontSize: root.f
      }

      Text {
        id: stripRank
        visible: root.onDesktop
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        text: root.rank.toUpperCase()
        color: root.theme.done
        font.family: root.fontFamily
        font.pixelSize: root.f * 0.65
        font.bold: true
        font.letterSpacing: root.f * 0.1
      }

      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.theme.line }
    }

    // Mission header: number, title, and the steps.
    Item {
      visible: !root.onDesktop
      width: parent.width
      height: visible ? root.f * 4 : 0

      Column {
        x: root.pad
        anchors.bottom: parent.bottom
        spacing: root.f * 0.15

        Text {
          text: root.mission ? "MISSION " + Engine.missionNumber(root.session.mission) : "CAMPAIGN"
          color: root.theme.quiet
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.72
          font.letterSpacing: root.f * 0.18
        }

        Text {
          objectName: "missionTitle"
          text: root.mission ? root.mission.title : Missions.CAMPAIGN.part
          color: root.theme.text
          font.family: root.fontFamily
          font.pixelSize: root.f * 1.7
          font.weight: Font.Black
        }
      }

      Row {
        visible: root.mission !== null
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.f * 0.45
        spacing: root.f * 0.7

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.mission ? "STEP " + (root.session.step + 1) + " / " + root.mission.steps.length : ""
          color: root.theme.quiet
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.72
          font.letterSpacing: root.f * 0.16
        }

        Row {
          objectName: "stepPips"
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.f * 0.25

          Repeater {
            model: root.mission ? Engine.stepStates(root.mission.steps.length, root.session.step, root.celebrating) : []

            Rectangle {
              required property string modelData
              width: root.f * 1.3
              height: root.f * 0.45
              color: modelData === "done" ? root.theme.done : modelData === "now" ? root.theme.accent : root.theme.line
            }
          }
        }
      }
    }

    // The body: who's talking and the task, or the rank-up, the map, or settings.
    Item {
      id: body
      width: parent.width
      height: root.bodyHeight + root.pad * 2

      Item {
        id: bodyArea
        x: root.pad
        y: root.pad
        width: parent.width - root.pad * 2
        height: root.bodyHeight

        // Who's talking, and what they say.
        Row {
          id: speakerRow
          visible: !root.showingSettings && root.step !== null && !root.rankUp
          width: parent.width
          height: root.f * (root.onDesktop ? 4.8 : 6.6)
          spacing: root.f * (root.onDesktop ? 0.7 : 1)

          Box {
            objectName: "portrait"
            width: root.f * (root.onDesktop ? 4.8 : 8.2)
            height: parent.height
            label: root.onDesktop ? "" : root.speakers[root.speaker].name
            labelColor: root.speakers[root.speaker].color
            lineColor: root.theme.line
            ground: root.theme.ground
            boldLabel: true
            fontFamily: root.fontFamily
            fontSize: root.f

            PixelSprite {
              objectName: "portraitSprite"
              anchors.centerIn: parent
              width: Math.min(parent.width, parent.height) * (root.onDesktop ? 1.35 : 1.15)
              height: width
              sprite: root.speakers[root.speaker].sprite
              theme: root.theme
              mode: root.characterColors
            }
          }

          Box {
            width: parent.width - x
            height: parent.height
            label: root.onDesktop ? "" : Missions.UI.transmission
            labelColor: root.theme.quiet
            lineColor: root.onDesktop ? "transparent" : root.theme.line
            ground: root.theme.ground
            fontFamily: root.fontFamily
            fontSize: root.f

            Text {
              objectName: "lines"
              visible: !root.celebrating
              width: parent.width
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.StyledText
              text: root.step ? root.withCaret(root.say(root.step.lines.join("\n"))) : ""
              color: root.theme.text
              font.family: root.fontFamily
              font.pixelSize: root.f * (root.onDesktop ? 0.95 : 1.25)
              lineHeight: 1.15
              wrapMode: Text.Wrap
            }

            Text {
              objectName: "success"
              visible: root.celebrating
              width: parent.width
              anchors.verticalCenter: parent.verticalCenter
              text: root.step && root.celebrating ? root.say(root.step.success.line) : ""
              color: root.theme.done
              font.family: root.fontFamily
              font.pixelSize: root.f * (root.onDesktop ? 0.95 : 1.25)
              font.bold: true
              wrapMode: Text.Wrap
            }
          }
        }

        // The task: the one box that's alive.
        Box {
          id: taskBox
          visible: !root.showingSettings && root.step !== null && !root.rankUp
          y: speakerRow.height + root.f * (root.onDesktop ? 0.8 : 1.1)
          width: parent.width
          height: parent.height - y
          label: Missions.UI.yourTask
          labelColor: root.theme.accent
          lineColor: root.theme.accent
          ground: root.theme.ground
          fill: root.theme.field
          boldLabel: true
          fontFamily: root.fontFamily
          fontSize: root.f

          Column {
            width: parent.width
            spacing: root.f * 0.5

            Item {
              id: taskArea
              width: parent.width
              height: root.f * (root.onDesktop ? 4.6 : 5)

              Column {
                visible: root.expectType === "button"
                anchors.centerIn: parent
                spacing: root.f / 2

                Rectangle {
                  // The rank-up has its own button with this name.
                  objectName: root.expectType === "button" && !root.rankUp ? "button-" + root.step.expect.id : "taskButton"
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: buttonLabel.implicitWidth + root.f * 3
                  height: Math.max(44, root.f * 2.6)
                  color: buttonArea.containsMouse || root.celebrating ? root.theme.accent : "transparent"
                  border.color: root.theme.accent
                  border.width: 2

                  Text {
                    id: buttonLabel
                    anchors.centerIn: parent
                    text: root.step && root.step.expect.label ? root.step.expect.label.toUpperCase() : ""
                    color: buttonArea.containsMouse || root.celebrating ? root.theme.bars : root.theme.accent
                    font.family: root.fontFamily
                    font.pixelSize: root.f
                    font.bold: true
                    font.letterSpacing: root.f * 0.08
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
                  color: root.theme.quiet
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 0.8
                }
              }

              // Labelled tasks: what to do, a tally, and what the step shows (typed letters,
              // the force-field bar, or Bolt's shouting and alarm).
              Column {
                visible: root.expectType !== "button" && root.step !== null && root.step.expect.label !== undefined
                anchors.centerIn: parent
                width: parent.width
                spacing: root.f / 3

                // The order, like a command at a prompt, with a meter for tasks done several times.
                Item {
                  width: parent.width
                  height: instruction.implicitHeight

                  Row {
                    spacing: root.f * 0.6

                    Text {
                      text: ">"
                      color: root.theme.done
                      font.family: root.fontFamily
                      font.pixelSize: root.f * 1.1
                      font.bold: true
                    }

                    Text {
                      id: instruction
                      objectName: "instruction"
                      text: root.step && root.step.expect.label ? root.say(root.step.expect.label) : ""
                      color: root.theme.text
                      font.family: root.fontFamily
                      font.pixelSize: root.f * 1.1
                      font.bold: true
                    }
                  }

                  Row {
                    objectName: "meter"
                    visible: root.counted
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.f * 0.5

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: root.countLabel.toUpperCase()
                      color: root.theme.quiet
                      font.family: root.fontFamily
                      font.pixelSize: root.f * 0.72
                      font.letterSpacing: root.f * 0.12
                    }

                    Row {
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: root.f * 0.18

                      Repeater {
                        model: root.counted ? root.countGoal : 0

                        Rectangle {
                          required property int index
                          width: root.f * 0.62
                          height: root.f * 0.9
                          color: index < root.countDone ? root.theme.done : root.theme.line
                        }
                      }
                    }

                    Text {
                      objectName: "tally"
                      anchors.verticalCenter: parent.verticalCenter
                      text: root.countDone + "/" + root.countGoal
                      color: root.theme.text
                      font.family: root.fontFamily
                      font.pixelSize: root.f * 0.85
                      font.bold: true
                    }
                  }
                }

                // The shortcut to press, since Omarchy's shortcuts never reach the Academy's keyboard.
                Row {
                  objectName: "combo"
                  visible: root.step !== null && root.step.combo !== undefined
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: root.f / 2

                  Repeater {
                    model: root.step && root.step.combo ? root.step.combo : []

                    Row {
                      id: comboKey
                      required property string modelData
                      required property int index
                      spacing: root.f / 2

                      Text {
                        visible: comboKey.index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                        color: root.theme.quiet
                        font.family: root.fontFamily
                        font.pixelSize: root.f * 1.2
                      }

                      Rectangle {
                        id: comboCap
                        objectName: "combo-" + root.say(comboKey.modelData)
                        property bool lit: root.celebrating || root.session.hint >= 2
                        width: Math.max(comboLabel.implicitWidth + root.f * 1.2, root.f * 3)
                        height: root.f * 2.3
                        color: comboCap.lit ? root.theme.accent : "transparent"
                        border.color: comboCap.lit ? root.theme.accent : root.theme.faint
                        border.width: 1

                        // A key's lower edge, so the cap looks pressable.
                        Rectangle {
                          anchors.top: parent.bottom
                          width: parent.width
                          height: root.f * 0.18
                          color: comboCap.lit ? Theme.shade(String(root.theme.accent), -0.45) : root.theme.line
                        }

                        Text {
                          id: comboLabel
                          anchors.centerIn: parent
                          text: root.say(comboKey.modelData).toUpperCase()
                          color: comboCap.lit ? root.theme.bars : root.theme.text
                          font.family: root.fontFamily
                          font.pixelSize: root.f * 0.85
                          font.weight: Font.Black
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
                  color: root.celebrating ? root.theme.done : root.theme.cyan
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 2
                  font.bold: true
                }

                Item {
                  objectName: "shield"
                  visible: root.step !== null && root.step.display === "shield"
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: root.f * 20
                  height: root.f * 1.6

                  Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.theme.accent
                    border.width: 1
                  }

                  Rectangle {
                    objectName: "shieldFill"
                    height: parent.height
                    color: root.theme.accent
                    width: root.celebrating ? parent.width
                      : root.expectType === "hold" ? parent.width * Math.min(1, root.shiftHeldMs / root.step.expect.ms) : 0
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: root.letGoEarly && !root.celebrating
                    text: Missions.UI.keepHolding
                    color: root.theme.text
                    font.family: root.fontFamily
                    font.pixelSize: root.f
                    font.bold: true
                  }
                }

                Text {
                  id: loudText
                  objectName: "loud"
                  visible: root.step !== null && root.step.display === "loud"
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: root.step && root.step.loud ? (root.celebrating ? root.step.quiet : root.step.loud) : ""
                  color: root.celebrating ? root.theme.text : root.theme.danger
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 1.6
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
                spacing: root.f * 0.1

                Text {
                  id: fieldText
                  objectName: "field"
                  text: root.step && root.step.field ? root.step.field.slice(0, root.step.field.length - root.session.count) : ""
                  color: root.celebrating ? root.theme.done : root.theme.cyan
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 2.4
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
                  width: root.f * 0.6
                  height: fieldText.height * 0.75
                  anchors.verticalCenter: fieldText.verticalCenter
                  color: root.theme.cyan

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
                width: root.f * 18
                height: root.f * 2.6
                color: root.theme.ground
                border.color: codenameInput.activeFocus || root.celebrating ? root.theme.accent : root.theme.faint
                border.width: 1

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: root.f / 2
                  anchors.verticalCenter: parent.verticalCenter
                  text: ">"
                  color: root.theme.done
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 1.3
                  font.bold: true
                }

                TextInput {
                  id: codenameInput
                  objectName: "codenameInput"
                  anchors.fill: parent
                  anchors.margins: root.f / 2
                  anchors.leftMargin: root.f * 1.6
                  verticalAlignment: TextInput.AlignVCenter
                  maximumLength: 16
                  readOnly: root.celebrating
                  color: root.celebrating ? root.theme.done : root.theme.text
                  selectionColor: root.theme.accent
                  font.family: root.fontFamily
                  font.pixelSize: root.f * 1.3
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
                    color: root.theme.faint
                    font: codenameInput.font
                  }
                }
              }
            }

            // Help that grows while the learner is stuck: Bolt's hint, then the Mentor's demo.
            Column {
              width: parent.width
              height: root.f * (root.onDesktop ? 3.6 : 3.2)
              spacing: root.f * 0.3

              Text {
                objectName: "boltHint"
                width: parent.width
                visible: root.step !== null && !root.celebrating && root.session.hint >= 1
                text: root.step ? "Bolt: " + root.say(root.step.hint.bolt) : ""
                color: root.theme.cyan
                font.family: root.fontFamily
                font.pixelSize: root.f * (root.onDesktop ? 0.8 : 0.95)
                wrapMode: Text.Wrap
              }

              Text {
                objectName: "demoHint"
                width: parent.width
                visible: root.step !== null && !root.celebrating && root.session.hint >= 3
                text: root.step ? "Mentor: " + root.say(root.step.hint.demo) : ""
                color: root.theme.text
                font.family: root.fontFamily
                font.pixelSize: root.f * (root.onDesktop ? 0.8 : 0.95)
                wrapMode: Text.Wrap
              }
            }

            // The keyboard keeps its space even when hidden; pointer steps play in the same space.
            // Desktop missions have neither.
            Item {
              visible: !root.onDesktop
              width: parent.width
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
                theme: root.theme
                mode: root.characterColors
                fontFamily: root.fontFamily
                fontSize: root.f
                keepScrollingText: Missions.UI.keepScrolling
                onPointerEvent: (event) => root.handle(event)
              }

              OnScreenKeyboard {
                id: keyboard
                objectName: "keyboard"
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: root.keyboardShown ? 1 : 0
                pressed: Model.pressedLabels(root.keys)
                lit: root.step && root.session.hint >= 2 ? root.step.hint.keys : []
                textColor: root.theme.text
                dimColor: root.theme.faint
                accentColor: root.theme.accent
                pressedTextColor: root.theme.bars
                fontFamily: root.fontFamily
                unit: root.f * 2.4

                Behavior on opacity { NumberAnimation { duration: 200 } }
              }
            }
          }
        }

        RankUp {
          id: rankUpView
          objectName: "rankUp"
          visible: root.rankUp
          anchors.fill: parent
          rank: root.step && root.step.badge ? root.step.badge : ""
          level: Missions.CAMPAIGN.ranks.findIndex(function(r) { return r.name === rankUpView.rank }) + 1
          previousRank: rankUpView.level > 1 ? Missions.CAMPAIGN.ranks[rankUpView.level - 2].name : ""
          rankNames: Missions.CAMPAIGN.ranks.map(function(r) { return r.name })
          line: root.step ? (root.celebrating ? root.say(root.step.success.line) : root.say(root.step.lines.join(" "))) : ""
          unlocks: [Missions.UI.accessLevel.replace("{level}", rankUpView.level), Missions.UI.badgeAdded.replace("{rank}", rankUpView.rank)]
          buttonId: root.step && root.step.expect.id ? root.step.expect.id : ""
          buttonLabel: root.step && root.step.expect.label ? root.step.expect.label : ""
          celebrating: root.celebrating
          compact: root.onDesktop
          rankUpLabel: Missions.UI.rankUp
          unlockedLabel: Missions.UI.unlocked
          theme: root.theme
          mode: root.characterColors
          fontFamily: root.fontFamily
          fontSize: root.f
          onPressed: root.handle({ type: "button", id: root.step.expect.id })
        }

        CampaignMap {
          objectName: "campaignMap"
          visible: root.finishedAll && !root.showingSettings
          anchors.fill: parent
          ranks: root.campaign
          part: Missions.CAMPAIGN.part
          nextPart: Missions.CAMPAIGN.nextPart
          nextPartText: Missions.UI.nextPartLocked
          message: Missions.UI.comingSoon
          badgesLabel: Missions.UI.badges
          lockedLabel: Missions.UI.locked
          theme: root.theme
          mode: root.characterColors
          fontFamily: root.fontFamily
          fontSize: root.f
        }

        // Settings, for grown-ups: in the body's place, same window size.
        SettingsView {
          objectName: "settings"
          visible: root.showingSettings
          anchors.fill: parent
          missionName: root.mission ? "Mission " + Engine.missionNumber(root.session.mission) + ": " + root.mission.title : ""
          characterColors: root.characterColors
          confirmingReset: root.confirmingReset
          compact: root.onDesktop
          theme: root.theme
          fontFamily: root.fontFamily
          fontSize: root.f
          onSkip: root.skipMission()
          onToggleColors: root.toggleCharacterColors()
          onReset: root.resetProgress()
          onBack: { root.showingSettings = false; root.focusTask() }
        }
      }
    }

    // Key bar: what works right now.
    Rectangle {
      width: parent.width
      height: root.f * (root.onDesktop ? 1.9 : 2.2)
      color: root.theme.bars
      border.width: 1
      border.color: root.theme.line

      Row {
        anchors.left: parent.left
        anchors.leftMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.f * 1.3

        KeyHint {
          objectName: "closeButton"
          anchors.verticalCenter: parent.verticalCenter
          key: "ESC"
          action: "close"
          onClicked: root.exitRequested()
        }

        Text {
          objectName: "settingsButton"
          visible: !root.showingSettings
          anchors.verticalCenter: parent.verticalCenter
          text: Missions.UI.settings.toLowerCase()
          color: root.theme.quiet
          font.family: root.fontFamily
          font.pixelSize: root.f * 0.72
          font.underline: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.showingSettings = true; root.confirmingReset = false; root.forceActiveFocus() }
          }
        }
      }

      Text {
        visible: !root.onDesktop
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        text: Missions.UI.progressSaved.toLowerCase()
        color: root.theme.quiet
        font.family: root.fontFamily
        font.pixelSize: root.f * 0.72
      }
    }
  }
}
