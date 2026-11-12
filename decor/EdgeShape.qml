import QtQuick
import QtQuick.Shapes

// The notch's body, hanging from the top edge of the screen or rising from the
// bottom one. Where it meets the edge it flares out in two concave curves, so
// it reads as part of the screen's frame rather than a card floating on it.
//
//   edge "top"                              edge "bottom"
//   ─────────────────────────               ╭───────────────╮
//    ╲_                     _╱              │               │
//      │                   │              _╱                 ╲_
//      ╰───────────────────╯              ─────────────────────
//
// The bottom one is drawn with mirrored points, not a negative scale:
// CurveRenderer fills the wrong side of a mirrored path.
Item {
  id: root

  property string edge: "top"
  property real bodyWidth: 200
  property real bodyHeight: 34
  property real radius: 17
  property real flare: 12

  readonly property real r: Math.max(0, Math.min(radius, bodyHeight - flare, bodyWidth / 2))
  readonly property real f: flare
  readonly property bool atBottom: edge === "bottom"
  readonly property real w: bodyWidth + 2 * flare
  readonly property real h: bodyHeight

  // y for a point measured from the screen edge.
  function ey(d) { return atBottom ? h - d : d }

  width: w
  height: h

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: 1
      strokeColor: Theme.edge
      fillGradient: LinearGradient {
        // A little light on the side away from the screen edge on the bottom
        // panel would read as a lit card; keep the light where glass meets
        // the edge, as on the top notch.
        x1: 0; y1: root.ey(0)
        x2: 0; y2: root.ey(root.h)
        GradientStop { position: 0; color: Theme.bodyTop }
        GradientStop { position: 1; color: Theme.body }
      }

      startX: 0
      startY: root.ey(0)

      PathLine { x: root.w; y: root.ey(0) }
      PathArc {
        x: root.bodyWidth + root.f; y: root.ey(root.f)
        radiusX: root.f; radiusY: root.f
        direction: root.atBottom ? PathArc.Clockwise : PathArc.Counterclockwise
      }
      PathLine { x: root.bodyWidth + root.f; y: root.ey(root.h - root.r) }
      PathArc {
        x: root.bodyWidth + root.f - root.r; y: root.ey(root.h)
        radiusX: root.r; radiusY: root.r
        direction: root.atBottom ? PathArc.Counterclockwise : PathArc.Clockwise
      }
      PathLine { x: root.f + root.r; y: root.ey(root.h) }
      PathArc {
        x: root.f; y: root.ey(root.h - root.r)
        radiusX: root.r; radiusY: root.r
        direction: root.atBottom ? PathArc.Counterclockwise : PathArc.Clockwise
      }
      PathLine { x: root.f; y: root.ey(root.f) }
      PathArc {
        x: 0; y: root.ey(0)
        radiusX: root.f; radiusY: root.f
        direction: root.atBottom ? PathArc.Clockwise : PathArc.Counterclockwise
      }
    }
  }
}
