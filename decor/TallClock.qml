import QtQuick
import "Glyphs.js" as G

// The time in tall, rounded digits: plain white, a little see-through (the
// theme's text colour on light themes, where white would vanish).
Item {
  id: root

  property string text: "0:00"
  property real glyphHeight: 440          // pixels
  property real gapUnits: 16
  property real motion: 1
  property real rollOverride: -1

  readonly property real k: glyphHeight / G.glyphHeight
  // Solid here; the see-through comes from the layer below. A stroke that
  // crosses itself (the 8's waist, where the 5 and 9 join) would otherwise
  // be drawn twice there and show brighter where it overlaps.
  readonly property color ink: Theme.dark ? "white" : Theme.text
  readonly property real inkOpacity: Theme.dark ? 0.88 : 0.84

  implicitWidth: row.width
  implicitHeight: glyphHeight
  width: implicitWidth
  height: implicitHeight

  // Slots, not characters: a Repeater over the characters would rebuild every
  // digit each minute and lose the roll. Only the count changes the slots
  // (9:59 → 10:00).
  Row {
    id: row
    spacing: root.gapUnits * root.k
    layer.enabled: true
    layer.smooth: true
    opacity: root.inkOpacity
    Repeater {
      model: root.text.length
      ClockGlyph {
        ch: root.text.charAt(index)
        k: root.k
        color: root.ink
        motion: root.motion
        rollOverride: root.rollOverride
      }
    }
  }
}
