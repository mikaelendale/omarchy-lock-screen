.pragma library

// The lock screen clock's digits: tall, rounded, single-stroke shapes, drawn
// as the centre line of a 26-unit stroke so GlassGlyph can draw each one as a
// glass tube (a bright rim, a frosted body, a sheen along the middle).
//
// Units: a digit's centre line lives in a 74 × 274 box; with the stroke round
// it, the glyph is 100 × 300. Every curve is a line, a circular arc or a
// gentle Bézier, so the stroke stays even all the way round.
//
//   0  a stadium              5  flag, stem, bowl ending in a curl
//   1  flag and stem          6  hook, stem, closed bowl
//   2  cap, sweep, base       7  bar and a falling curve
//   3  two bowls, a prong     8  a small bowl on a large one
//   4  stem, diagonal, bar    9  a 6 turned round

var stroke = 26
var boxWidth = 74
var boxHeight = 274
var glyphHeight = boxHeight + stroke     // 300
var digitWidth = boxWidth + stroke       // 100
var colonWidth = 46

var paths = {
  "0": "M0,37 L0,237 A37,37 0 0 0 74,237 L74,37 A37,37 0 0 0 0,37 Z",
  "1": "M10,46 L46,4 L46,274",
  "2": "M0,37 A37,37 0 0 1 74,37 C74,104 0,160 0,274 L74,274",
  "3": "M0,37 A37,37 0 0 1 74,37 L74,92 C74,116 56,132 30,132 C56,132 74,150 74,176 L74,237 A37,37 0 0 1 0,237",
  "4": "M54,274 L54,2 L0,186 L74,186",
  "5": "M70,0 L2,0 L2,124 C12,108 24,100 37,100 A37,37 0 0 1 74,137 L74,237 A37,37 0 0 1 0,237",
  "6": "M70,22 C62,8 50,0 37,0 A37,37 0 0 0 0,37 L0,237 A37,37 0 0 0 74,237 L74,163 A37,37 0 0 0 0,163",
  "7": "M0,0 L74,0 C56,70 36,160 30,274",
  "8": "M5,32 A32,32 0 0 1 69,32 L69,92 A32,32 0 0 1 5,92 Z M0,161 A37,37 0 0 1 74,161 L74,237 A37,37 0 0 1 0,237 Z",
  "9": "M74,114 A37,37 0 0 1 0,114 L0,37 A37,37 0 0 1 74,37 L74,237 A37,37 0 0 1 37,274 C24,274 12,266 4,252",
  // The colon has no stroke path: GlassGlyph fills dotsPath() instead.
  ":": ""
}

function widthOf(ch) {
  return ch === ":" ? colonWidth : digitWidth
}

// The colon's two dots as filled circles of radius r, centred in its width at
// 38% and 70% of the height (in centre-line units, like the paths).
function dotsPath(r) {
  var cx = colonWidth / 2 - stroke / 2
  var ys = [104, 192]
  var out = ""
  for (var i = 0; i < ys.length; i++)
    out += "M" + (cx - r) + "," + ys[i] + " a" + r + "," + r + " 0 1 0 " + (2 * r) + ",0 a" + r + "," + r + " 0 1 0 " + (-2 * r) + ",0 "
  return out
}

function pathOf(ch) {
  return paths[ch] || ""
}
