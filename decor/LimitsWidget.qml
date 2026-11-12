import QtQuick
import "Palette.js" as P

// Every signed-in agent's plan limits, side by side: each agent's mark and
// name over a small ring per limit. Hover to see when each one resets.
Glass {
  id: root

  property var agents: []           // [{ id, name, tier, limits: [...] }]
  property var sessions: []         // for each agent's mark (working, needs you)
  property real now: Date.now()
  property real reveal: 1
  property real motion: 1

  readonly property bool hovered: hover.hovered

  // Through a Repeater these arrive as maps and sequences, so copy them into
  // plain lists rather than trusting Array.isArray().
  function listOf(l, max) {
    var out = []
    if (l) for (var i = 0; i < l.length && out.length < max; i++) out.push(l[i])
    return out
  }
  function shortLabel(label) {
    var l = String(label || "")
    if (l === "5-hour") return "5h"
    if (l === "Weekly") return "Week"
    return l.replace(/\s+weekly$/i, "")
  }
  // "2h 15m" within a day, the weekday after that.
  function resetText(iso) {
    var t = Date.parse(iso)
    if (!isFinite(t)) return ""
    var mins = Math.max(0, Math.round((t - root.now) / 60000))
    if (mins < 60) return mins + "m"
    if (mins < 24 * 60) {
      var h = Math.floor(mins / 60), m = mins % 60
      return h + "h" + (m > 0 ? " " + m + "m" : "")
    }
    return Qt.formatDate(new Date(t), "ddd")
  }
  function sessionFor(agentId) {
    var order = ["needs", "working", "watching", "done", "idle"]
    for (var s = 0; s < order.length; s++)
      for (var i = 0; i < sessions.length; i++)
        if (sessions[i].agent === agentId && sessions[i].state === order[s]) return sessions[i]
    return null
  }

  width: groups.width + 2 * pad
  HoverHandler { id: hover }

  Row {
    id: groups
    spacing: 18
    Repeater {
      model: root.listOf(root.agents, 3)
      Row {
        spacing: 18
        // A hairline between agents.
        Rectangle {
          visible: index > 0
          width: 1
          height: 82
          color: Theme.hairline
        }
        Column {
          spacing: 8
          readonly property var agent: modelData
          readonly property var lead: root.sessionFor(modelData.id)
          Row {
            spacing: 7
            AgentMark {
              anchors.verticalCenter: parent.verticalCenter
              size: 14
              agent: modelData.id || "claude"
              working: !!parent.parent.lead && (parent.parent.lead.state === "working" || parent.parent.lead.state === "watching")
              needs: !!parent.parent.lead && parent.parent.lead.state === "needs"
              motion: root.motion
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: String(modelData.name || "").replace(/ Code$/, "")
              textFormat: Text.PlainText
              color: Theme.text
              font.family: P.sans
              font.pixelSize: 13
              font.weight: Font.DemiBold
            }
          }
          Row {
            spacing: 12
            Repeater {
              model: root.listOf(modelData.limits, 3)
              MiniRing {
                percent: Number(modelData.percent) || 0
                label: root.shortLabel(modelData.label)
                resets: root.resetText(modelData.resetsAt)
                showResets: root.hovered
                reveal: root.reveal
              }
            }
          }
        }
      }
    }
  }
}
