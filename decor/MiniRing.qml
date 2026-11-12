import QtQuick
import QtQuick.Shapes
import "Palette.js" as P

// A plan limit as a small ring (green, orange past 75%, red past 90%, the
// notch's colours) with the share used inside and the limit's name under it;
// while the widget is hovered, the name gives way to when it resets.
Item {
  id: root

  property real percent: 0          // 0..1
  property string label: ""
  property string resets: ""
  property bool showResets: false
  property real ringSize: 42
  property real reveal: 1

  readonly property real used: Math.max(0, Math.min(1, percent))
  readonly property color tint: used >= 0.9 ? Theme.red : (used >= 0.75 ? Theme.orange : Theme.green)
  readonly property real stroke: 4
  readonly property real r: (ringSize - stroke) / 2

  width: Math.max(ringSize, nameText.implicitWidth, resetText.implicitWidth)
  height: ringSize + 5 + 14

  Item {
    id: ring
    width: root.ringSize
    height: root.ringSize
    anchors.horizontalCenter: parent.horizontalCenter
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.hairline
        strokeWidth: root.stroke
        PathAngleArc { centerX: root.ringSize / 2; centerY: root.ringSize / 2; radiusX: root.r; radiusY: root.r; startAngle: 0; sweepAngle: 360 }
      }
      ShapePath {
        fillColor: "transparent"
        strokeColor: root.tint
        strokeWidth: root.stroke
        capStyle: ShapePath.RoundCap
        PathAngleArc {
          centerX: root.ringSize / 2; centerY: root.ringSize / 2; radiusX: root.r; radiusY: root.r
          startAngle: -90
          sweepAngle: Math.max(0.5, root.used * 360 * root.reveal)
        }
      }
    }
    Text {
      anchors.centerIn: parent
      text: Math.round(root.used * 100)
      textFormat: Text.PlainText
      color: Theme.text
      font.family: P.sans
      font.pixelSize: 13
      font.weight: Font.DemiBold
      font.features: { "tnum": 1 }
    }
  }

  Item {
    anchors.top: ring.bottom
    anchors.topMargin: 5
    width: parent.width
    height: 14
    Text {
      id: nameText
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.label
      textFormat: Text.PlainText
      color: Theme.secondary
      font.family: P.sans
      font.pixelSize: 11
      font.weight: Font.Medium
      opacity: root.showResets && root.resets ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }
    Text {
      id: resetText
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.resets
      textFormat: Text.PlainText
      color: Theme.text
      font.family: P.sans
      font.pixelSize: 11
      font.weight: Font.Medium
      font.features: { "tnum": 1 }
      opacity: root.showResets && root.resets ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }
  }
}
