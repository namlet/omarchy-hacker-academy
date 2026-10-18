import QtQuick

// A terminal-style box: a thin border with its name set into the top edge.
// Children go inside, clear of the border and the name.
Item {
  id: root

  property string label: ""
  property color labelColor: "white"
  property color lineColor: "gray"
  // Behind the name, so the border looks cut where the name sits.
  property color ground: "black"
  property color fill: "transparent"
  property bool boldLabel: false
  property string fontFamily: "monospace"
  property real fontSize: 16
  default property alias content: inner.data

  Rectangle {
    anchors.fill: parent
    color: root.fill
    border.color: root.lineColor
    border.width: 1
  }

  Rectangle {
    visible: root.label !== ""
    x: root.fontSize * 0.7
    y: -height / 2
    width: name.implicitWidth + root.fontSize * 0.7
    height: name.implicitHeight
    color: root.ground

    Text {
      id: name
      objectName: "boxLabel"
      anchors.centerIn: parent
      text: root.label.toUpperCase()
      color: root.labelColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize * 0.72
      font.letterSpacing: root.fontSize * 0.12
      font.bold: root.boldLabel
    }
  }

  Item {
    id: inner
    anchors.fill: parent
    anchors.margins: root.fontSize * 0.8
    anchors.topMargin: root.fontSize * 1.1
  }
}
