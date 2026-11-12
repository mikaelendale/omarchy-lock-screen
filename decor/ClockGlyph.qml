import QtQuick
import QtQuick.Shapes
import "Glyphs.js" as G
import "Palette.js" as P

// One character of the lock screen clock: a tall, rounded digit (Glyphs.js)
// in plain white, a little see-through. When it changes it rolls like a
// slot: the old digit slides up out of its slot as the new one slides in
// from below, clipped so the two never overlap.
Item {
  id: root

  property string ch: "0"
  property real k: 1                     // pixels per unit
  property color color: "white"
  property real motion: 1
  property real rollOverride: -1         // tests: the roll frozen at this point

  property string shown: ch
  property string previous: ""
  property real roll: 1
  readonly property real t: rollOverride >= 0 ? rollOverride : roll

  width: G.widthOf(shown) * k
  height: G.glyphHeight * k
  clip: previous !== "" && t < 1
  readonly property real travel: height * 1.3

  onChChanged: {
    if (ch === shown) return
    previous = shown
    shown = ch
    rollAnim.stop()
    if (motion > 0) { roll = 0; rollAnim.start() } else roll = 1
  }
  NumberAnimation {
    id: rollAnim
    target: root
    property: "roll"
    to: 1
    duration: 560
    easing.type: Easing.BezierSpline
    easing.bezierCurve: P.ease
  }

  component Digit: Shape {
    id: digit
    property string glyph: ""
    width: G.boxWidth + G.stroke
    height: G.glyphHeight
    scale: root.k
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.color
      strokeWidth: G.stroke
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: digit.glyph === ":" ? "" : G.pathOf(digit.glyph) }
    }
    // The colon's two dots.
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillColor: root.color
      PathSvg { path: digit.glyph === ":" ? G.dotsPath(G.stroke / 2) : "" }
    }
  }

  // The paths are written from (0,0) of their 74 × 274 box and the stroke
  // spills half its width round it, so the digits sit half a stroke in.
  Item {
    x: G.stroke / 2 * root.k
    y: G.stroke / 2 * root.k
    // A gap between the two, and each fading as it leaves or arrives, so
    // they never touch mid-roll.
    Digit {
      visible: root.previous !== "" && root.t < 1
      glyph: root.previous
      y: -root.t * root.travel
      opacity: 1 - root.t
    }
    Digit {
      glyph: root.shown
      y: root.previous !== "" ? (1 - root.t) * root.travel : 0
      opacity: root.previous !== "" ? root.t : 1
    }
  }
}
