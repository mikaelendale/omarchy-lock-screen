.pragma library

// Fonts, the motion curve and a colour helper. Colours come from Theme.qml,
// which follows the current Omarchy theme.

var sans = "Adwaita Sans"
var glyphs = "JetBrainsMono Nerd Font"
var symbols = "Noto Sans Symbols 2"   // ✳ without the colour-emoji fallback

// Motion: an ease-out with a long tail. No bounce, no ease-in (Omarchy's rules).
var ease = [0.22, 0.9, 0.24, 1.0, 1.0, 1.0]

function alpha(color, a) {
  var c = Qt.color(color)
  return Qt.rgba(c.r, c.g, c.b, a)
}

// The ease above at progress p (0..1): a cubic Bézier from (0,0) to (1,1)
// with control points (0.22, 0.9) and (0.24, 1.0), solved for x by Newton's
// method with a bisection fallback. For motion driven by one clock (the lock
// screen's intro), where a NumberAnimation's own easing can't be used.
function easeAt(p) {
  if (p <= 0) return 0
  if (p >= 1) return 1
  var x1 = ease[0], y1 = ease[1], x2 = ease[2], y2 = ease[3]
  function bx(t) { return 3 * x1 * t * (1 - t) * (1 - t) + 3 * x2 * t * t * (1 - t) + t * t * t }
  function by(t) { return 3 * y1 * t * (1 - t) * (1 - t) + 3 * y2 * t * t * (1 - t) + t * t * t }
  function dx(t) { return 3 * x1 * (1 - t) * (1 - t) + 6 * (x2 - x1) * t * (1 - t) + 3 * (1 - x2) * t * t }
  var t = p
  for (var i = 0; i < 8; i++) {
    var err = bx(t) - p
    if (Math.abs(err) < 1e-5) return by(t)
    var d = dx(t)
    if (Math.abs(d) < 1e-6) break
    t -= err / d
  }
  var lo = 0, hi = 1
  t = p
  for (var j = 0; j < 30; j++) {
    var v = bx(t)
    if (Math.abs(v - p) < 1e-5) break
    if (v < p) lo = t; else hi = t
    t = (lo + hi) / 2
  }
  return by(t)
}
