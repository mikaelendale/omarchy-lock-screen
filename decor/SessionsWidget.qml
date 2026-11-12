import QtQuick
import "Palette.js" as P

// The open coding-agent sessions, most pressing first: two at most, each
// with its agent's mark, the project folder (never the conversation's title:
// anyone can read a lock screen), and what it's doing and for how long.
Glass {
  id: root

  property var sessions: []
  property real now: Date.now()
  property real motion: 1

  title: "Sessions"
  note: sessions.length === 0 ? "" : sessions.length + " open"
  width: 236

  function nameOf(s) {
    if (s.agentName) return s.agentName
    var id = String(s.agent || "agent")
    return id.charAt(0).toUpperCase() + id.slice(1)
  }
  function stateColor(state) {
    if (state === "needs") return Theme.yellow
    if (state === "done") return Theme.green
    if (state === "working") return Theme.orange
    if (state === "watching") return Theme.teal
    return Theme.secondary
  }
  function stateWord(state) {
    if (state === "needs") return "needs you"
    if (state === "done") return "your turn"
    if (state === "working") return "working"
    if (state === "watching") return "watching"
    return "idle"
  }
  function elapsed(since) {
    var t = Number(since)
    if (!(t > 0)) return ""
    var mins = Math.floor((root.now - t) / 60000)
    if (mins < 1) return "now"
    if (mins < 60) return mins + "m"
    if (mins < 24 * 60) return Math.floor(mins / 60) + "h"
    return Math.floor(mins / 1440) + "d"
  }

  Text {
    visible: root.sessions.length === 0
    y: 8
    text: "No sessions open"
    textFormat: Text.PlainText
    color: Theme.secondary
    font.family: P.sans
    font.pixelSize: 12
  }

  Column {
    width: parent.width
    spacing: 4
    Repeater {
      model: root.sessions.slice(0, 2)
      Item {
        id: row
        width: parent.width
        height: 24
        readonly property string state: String(modelData.state || "idle")
        AgentMark {
          id: mark
          anchors.verticalCenter: parent.verticalCenter
          size: 14
          agent: modelData.agent || "claude"
          working: row.state === "working" || row.state === "watching"
          needs: row.state === "needs"
          motion: root.motion
        }
        Text {
          anchors.left: mark.right
          anchors.leftMargin: 8
          anchors.right: right.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          text: (modelData.project || root.nameOf(modelData))
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: Theme.text
          font.family: P.sans
          font.pixelSize: 12
          font.weight: Font.Medium
        }
        Row {
          id: right
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6
          Text {
            text: root.stateWord(row.state)
            textFormat: Text.PlainText
            color: root.stateColor(row.state)
            font.family: P.sans
            font.pixelSize: 11
            font.weight: Font.Medium
          }
          Text {
            visible: text.length > 0
            text: root.elapsed(modelData.since)
            textFormat: Text.PlainText
            color: Theme.tertiary
            font.family: P.sans
            font.pixelSize: 11
            font.features: { "tnum": 1 }
          }
        }
      }
    }
  }
}
