pragma Singleton
import QtQuick
QtObject {
  function isVideoPath(p) { return /\.(mp4|webm|mkv|mov)$/i.test(String(p || "")) }
  function fileUrl(p) { return "file://" + p }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
}
