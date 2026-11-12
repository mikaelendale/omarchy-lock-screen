pragma Singleton
import QtQuick
// Stand-in for Omarchy's qs.Commons Color: the harness sets these per theme.
QtObject {
  property color background: "#282828"
  property color foreground: "#d4be98"
  property color accent: "#7daea3"
  readonly property QtObject lock: QtObject {
    property color text: foreground
    property color placeholder: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.66)
    property color textError: "#ea6962"
    property color selection: Qt.rgba(accent.r, accent.g, accent.b, 0.45)
  }
}
