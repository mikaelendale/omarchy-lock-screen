import QtQuick
import QtQuick.Window
import "../decor"

// The clock alone, at several times and lights, into <outdir>/clock-<mode>.png.
//   QT_QPA_PLATFORM=offscreen qml6 tests/ClockHarness.qml -- <outdir> dark|light
Window {
  id: win
  width: 1920
  height: 1080
  visible: true
  readonly property var args: Qt.application.arguments
  readonly property string outdir: args[args.length - 2]
  readonly property string mode: args[args.length - 1]
  readonly property bool light: mode.indexOf("light") === 0
  readonly property string here: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

  Image { anchors.fill: parent; source: "file://" + win.here + (win.light ? "blurred-light.jpg" : "blurred-dark.jpg"); fillMode: Image.PreserveAspectCrop }
  Rectangle { anchors.fill: parent; color: Theme.background; opacity: Theme.dark ? 0.34 : 0.26 }

  Grid {
    anchors.centerIn: parent
    columns: 2
    spacing: 60
    TallClock { text: "8:32"; glyphHeight: 400 }
    TallClock { text: "10:47"; glyphHeight: 400 }
    TallClock { text: "12:09"; glyphHeight: 400 }
    TallClock { text: "6:58"; glyphHeight: 400 }
  }

  Component.onCompleted: {
    Theme.apply(light ? { mode: "light", background: "#eff1f5", foreground: "#4c4f69", accent: "#1e66f5" }
                      : { mode: "dark", background: "#282828", foreground: "#d4be98", bright_foreground: "#d4be98", accent: "#7daea3" })
  }
  Timer {
    interval: 400; running: true
    onTriggered: win.contentItem.grabToImage(function(r) { r.saveToFile(win.outdir + "/clock-" + win.mode + ".png"); Qt.quit() })
  }
}
