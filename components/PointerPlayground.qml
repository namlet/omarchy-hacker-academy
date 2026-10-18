pragma ComponentBehavior: Bound

import QtQuick
import "../Theme.js" as Theme

// Mission 1's play area: things to hover, click, drag, scroll to, and right-click.
// `play` picks the layout; caught targets (`hits`) disappear; `highlight` makes
// the targets glow when the learner needs help. Drawn with the sprites in Sprites.js.
Item {
  id: root

  property string play: ""
  property var hits: []
  property bool highlight: false
  property var theme: Theme.DEFAULT_PALETTE
  // The character colors setting: "classic" or "theme".
  property string mode: "classic"
  property string fontFamily: "monospace"
  property int fontSize: 16
  property string keepScrollingText: "Keep scrolling down."
  // How long a crawling bug takes to reach its next spot. Slow, for beginners.
  property int crawlMs: 1800

  signal pointerEvent(var event)

  readonly property real bugSize: root.fontSize * 3.2
  // Hovering Bolt only counts after the arrow has been somewhere else first, so an
  // arrow that happens to rest where Bolt appears doesn't finish the step by itself.
  property bool armed: false

  function caught(id) { return root.hits.indexOf(id) !== -1 }
  function send(action, id, target) { root.pointerEvent({ type: "pointer", action: action, id: id, target: target }) }

  onPlayChanged: {
    root.armed = false
    bigBug.goHome()
    scroller.contentY = 0
  }

  // A sprite that pulses while the learner needs help.
  component Art: PixelSprite {
    id: art
    property bool glowing: root.highlight
    theme: root.theme
    mode: root.mode

    SequentialAnimation on opacity {
      running: art.glowing
      loops: Animation.Infinite
      onStopped: art.opacity = 1
      NumberAnimation { to: 0.35; duration: 400 }
      NumberAnimation { to: 1; duration: 400 }
    }
  }

  component Bug: Item {
    id: bug
    property string bugId: ""
    property string look: "bug"
    property real size: root.bugSize
    width: bug.size
    height: bug.size

    Art { anchors.fill: parent; sprite: bug.look }
  }

  MouseArea {
    anchors.fill: parent
    visible: root.play === "bolt"
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onPositionChanged: root.armed = true
  }

  // Step: move the arrow onto Bolt, who wiggles with delight.
  Item {
    objectName: "target-bolt"
    visible: root.play === "bolt"
    anchors.centerIn: parent
    width: root.fontSize * 7
    height: root.fontSize * 7

    Art {
      anchors.fill: parent
      sprite: "bolt"
      rotation: boltArea.containsMouse ? 8 : 0
      scale: boltArea.containsMouse ? 1.1 : 1
      Behavior on rotation { NumberAnimation { duration: 120 } }
      Behavior on scale { NumberAnimation { duration: 120 } }
    }

    MouseArea {
      id: boltArea
      anchors.fill: parent
      hoverEnabled: true
      enabled: root.play === "bolt"
      onEntered: if (root.armed) root.send("hover", "bolt")
    }
  }

  // Step: click five escaped bugs.
  Repeater {
    model: root.play === "bugs"
      ? [["bug1", 0.08, 0.15], ["bug2", 0.28, 0.62], ["bug3", 0.47, 0.18], ["bug4", 0.68, 0.6], ["bug5", 0.86, 0.2]]
      : []

    // Escaped bugs crawl to a new spot every few seconds, and freeze while the
    // arrow is on them so a beginner can still catch them.
    Bug {
      id: clickBug
      required property var modelData
      required property int index
      bugId: clickBug.modelData[0]
      objectName: "target-" + clickBug.bugId
      visible: !root.caught(clickBug.bugId)
      readonly property bool hovered: bugArea.containsMouse

      function crawl() {
        if (clickBug.hovered || !clickBug.visible) return
        const maxX = root.width - clickBug.width, maxY = root.height - clickBug.height
        crawlAnim.stop()
        crawlX.to = Math.random() * maxX
        crawlY.to = root.fontSize + Math.random() * (maxY - root.fontSize)
        crawlAnim.start()
      }

      Component.onCompleted: {
        clickBug.x = clickBug.modelData[1] * (root.width - clickBug.width)
        clickBug.y = clickBug.modelData[2] * (root.height - clickBug.height) + root.fontSize
      }
      onHoveredChanged: if (clickBug.hovered) crawlAnim.stop()

      ParallelAnimation {
        id: crawlAnim
        NumberAnimation { id: crawlX; target: clickBug; property: "x"; duration: root.crawlMs; easing.type: Easing.InOutQuad }
        NumberAnimation { id: crawlY; target: clickBug; property: "y"; duration: root.crawlMs; easing.type: Easing.InOutQuad }
      }

      Timer {
        // Each bug keeps its own rhythm so they don't move in step.
        interval: root.crawlMs + 400 + clickBug.index * 170
        running: root.play === "bugs" && root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: clickBug.crawl()
      }

      MouseArea {
        id: bugArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.send("click", clickBug.bugId)
      }
    }
  }

  // Step: drag the big bug into the jar.
  Item {
    id: jar
    objectName: "target-jar"
    visible: root.play === "drag"
    x: root.width * 0.68
    y: (root.height - height) / 2
    width: root.bugSize * 2.4
    height: root.bugSize * 2.4

    Art { anchors.fill: parent; sprite: "jar" }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.bottom
      anchors.topMargin: root.fontSize / 4
      text: "JAR"
      color: root.theme.rank
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      font.bold: true
    }
  }

  Bug {
    id: bigBug
    bugId: "bigbug"
    objectName: "target-bigbug"
    visible: root.play === "drag"
    size: root.bugSize * 1.4
    readonly property real homeX: root.width * 0.12
    readonly property real homeY: (root.height - height) / 2
    // Placed by assignment, not binding: a bound position would fight the drag.
    function goHome() { bigBug.x = bigBug.homeX; bigBug.y = bigBug.homeY }
    Component.onCompleted: bigBug.goHome()
    onHomeXChanged: bigBug.goHome()
    onHomeYChanged: bigBug.goHome()
    z: 1

    // Moves the bug with the pointer while the button is held, from where it was grabbed.
    MouseArea {
      id: grabArea
      property point grab: Qt.point(0, 0)
      anchors.fill: parent
      cursorShape: grabArea.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      onPressed: (mouse) => { grabArea.grab = Qt.point(mouse.x, mouse.y) }
      onPositionChanged: (mouse) => {
        if (!grabArea.pressed) return
        const p = grabArea.mapToItem(root, mouse.x, mouse.y)
        bigBug.x = p.x - grabArea.grab.x
        bigBug.y = p.y - grabArea.grab.y
      }
      onReleased: {
        const cx = bigBug.x + bigBug.width / 2, cy = bigBug.y + bigBug.height / 2
        const inJar = cx > jar.x && cx < jar.x + jar.width && cy > jar.y && cy < jar.y + jar.height
        if (inJar) {
          // Settle neatly inside the jar instead of hanging over its edge.
          bigBug.x = jar.x + (jar.width - bigBug.width) / 2
          bigBug.y = jar.y + (jar.height - bigBug.height) / 2
        } else {
          bigBug.goHome()
        }
        root.send("drop", "bigbug", inJar ? "jar" : "floor")
      }
    }
  }

  // Step: scroll down to find the hidden bug.
  Flickable {
    id: scroller
    objectName: "scroller"
    visible: root.play === "scroll"
    anchors.fill: parent
    clip: true
    contentWidth: width
    contentHeight: height * 3
    boundsBehavior: Flickable.StopAtBounds

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.fontSize
      text: "↓  " + root.keepScrollingText + "  ↓"
      color: root.theme.quiet
      font.family: root.fontFamily
      font.pixelSize: root.fontSize * 1.2
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: scroller.height * 1.4
      text: "↓  " + root.keepScrollingText + "  ↓"
      color: root.theme.quiet
      font.family: root.fontFamily
      font.pixelSize: root.fontSize * 1.2
    }

    Bug {
      id: hiddenBug
      bugId: "hidden"
      objectName: "target-hidden"
      x: (scroller.width - width) / 2
      y: scroller.contentHeight - height - root.fontSize * 2

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.send("click", "hidden")
      }
    }
  }

  // Step: right-click the sneaky bug.
  Bug {
    id: sneakyBug
    bugId: "sneaky"
    objectName: "target-sneaky"
    look: "sneakyBug"
    visible: root.play === "sneaky"
    anchors.centerIn: parent
    size: root.bugSize * 1.3

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: (mouse) => { if (mouse.button === Qt.RightButton) root.send("rightclick", "sneaky") }
    }
  }
}
