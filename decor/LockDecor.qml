import QtQuick
import "Palette.js" as P

// Everything on the lock screen except the wallpaper and the password field,
// in the notch's language:
//
//   a closed notch hanging from the top edge: what the agents are doing, and
//     the battery
//   the date, and the time in tall white digits; each rolls over as the
//     minute changes
//   (the password field, which LockView draws at pillY)
//   a row of small glass widgets floating above the bottom edge: plan
//     limits, sessions, today's coding, the machine, and what's playing
//
// Pure visuals: LockData feeds it, and tests/Harness.qml draws it off screen.
Item {
  id: root

  // ---- fed by LockView from LockData
  property var sessions: []
  property var agents: []            // [{ id, name, tier, limits: [...] }]
  property var today: ({ prompts: 0, tokens: 0, sessions: 0 })
  property var system: ({})
  property var player: null
  property var battery: ({ present: false })
  property bool use24h: false
  property bool active: false        // the lock is showing; plays the intro
  property real motion: 1
  property real now: Date.now()
  property real fixedTime: 0         // tests: show this time instead of now
  property real rollOverride: -1     // tests: the digits' roll frozen here

  signal mediaAction(string name)

  // ---- for LockView: the colours, where the password field goes, and how
  // far in it is
  readonly property var theme: Theme
  readonly property real pillWidth: 340
  readonly property real pillHeight: 50
  readonly property real pillY: region.y + stack.y + pillSlot.y
  readonly property real contentT: clockT

  // ---- the intro: one clock, introMs, and each part's progress (0 → 1)
  // read off it with its own delay, length and curve. One clock means the
  // harness can stop it at any moment and see exactly what the screen shows.
  readonly property real introLength: 1100
  property real introMs: introLength
  readonly property real notchT: P.easeAt(phase(0, 440))
  readonly property real clockT: P.easeAt(phase(40, 620))
  readonly property real widgetsT: P.easeAt(phase(160, 560))
  readonly property real ringT: 1 - Math.pow(1 - phase(360, 740), 3)

  function phase(delay, length) {
    return Math.max(0, Math.min(1, (introMs - delay) / length))
  }
  function playIntro() {
    introAnim.stop()
    if (root.motion <= 0) { introMs = introLength; return }
    introMs = 0
    introAnim.start()
  }
  // For tests/Harness.qml: the intro frozen at a moment, in milliseconds.
  function scrubIntro(ms) {
    introAnim.stop()
    introMs = Math.min(introLength, ms)
  }
  onActiveChanged: if (active) playIntro()
  Component.onCompleted: if (active) playIntro()

  NumberAnimation {
    id: introAnim
    target: root
    property: "introMs"
    to: root.introLength
    duration: root.introLength
  }

  // ---- the clock ticks on the minute, checked every second
  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }
  readonly property real shownTime: fixedTime > 0 ? fixedTime : now
  readonly property date stamp: new Date(shownTime - shownTime % 60000)
  // "h" is only 12-hour when the format has AP in it, so format with it and
  // drop it: a lock screen's time doesn't need its AM/PM.
  readonly property string timeText: use24h ? Qt.formatTime(stamp, "HH:mm")
    : Qt.formatTime(stamp, "h:mm AP").replace(/\s*[AaPp]\.?[Mm]\.?$/, "")

  // ---- the agents, summed up
  function count(state) {
    var n = 0
    for (var i = 0; i < sessions.length; i++) if (sessions[i].state === state) n++
    return n
  }
  function firstIn(states) {
    for (var s = 0; s < states.length; s++)
      for (var i = 0; i < sessions.length; i++) if (sessions[i].state === states[s]) return sessions[i]
    return null
  }
  function nameOf(s) {
    if (!s) return ""
    if (s.agentName) return s.agentName
    var id = String(s.agent || "agent")
    return id.charAt(0).toUpperCase() + id.slice(1)
  }
  readonly property var lead: firstIn(["needs", "working", "watching", "done"])
  readonly property string summary: {
    var needs = count("needs"), busy = count("working") + count("watching"), done = count("done")
    if (needs > 0) return needs === 1 ? nameOf(firstIn(["needs"])) + " needs you" : needs + " sessions need you"
    if (busy > 0) return busy === 1 ? nameOf(firstIn(["working", "watching"])) + " is working" : busy + " sessions working"
    if (done > 0) return done === 1 ? nameOf(firstIn(["done"])) + " is done" : done + " sessions done"
    return "Locked"
  }

  // A soft grain over the blurred wallpaper: large smooth blurs band into
  // steps on 8-bit screens, and the grain hides the steps.
  Image {
    anchors.fill: parent
    source: "grain.png"
    fillMode: Image.Tile
    smooth: false
    opacity: Theme.dark ? 0.14 : 0.1
  }

  // ================================================================ top notch
  Item {
    id: notch
    readonly property real bodyW: Math.max(184, notchRow.width + 2 * 18)
    width: notchShape.width
    height: 34
    anchors.horizontalCenter: parent.horizontalCenter
    y: -height * (1 - root.notchT)

    EdgeShape {
      id: notchShape
      edge: "top"
      bodyWidth: notch.bodyW
      bodyHeight: 34
      radius: 17
      flare: 12
    }

    Row {
      id: notchRow
      anchors.centerIn: parent
      spacing: 9
      Item {
        width: 16
        height: 16
        anchors.verticalCenter: parent.verticalCenter
        AgentMark {
          anchors.fill: parent
          visible: !!root.lead
          size: 16
          agent: root.lead ? (root.lead.agent || "claude") : "claude"
          working: !!root.lead && (root.lead.state === "working" || root.lead.state === "watching")
          needs: !!root.lead && root.lead.state === "needs"
          motion: root.motion
        }
        Text {
          anchors.centerIn: parent
          visible: !root.lead
          text: String.fromCodePoint(0xF033E)   // nf-md-lock
          textFormat: Text.PlainText
          color: Theme.text
          font.family: P.glyphs
          font.pixelSize: 15
        }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.summary
        textFormat: Text.PlainText
        color: Theme.text
        font.family: P.sans
        font.pixelSize: 13
        font.weight: Font.Medium
      }
      Item { width: 6; height: 1; visible: root.battery.present }
      BatteryIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.battery.present === true
        size: 25
        level: Number(root.battery.level) || 0
        charging: root.battery.charging === true
      }
    }
  }

  // ======================================================= date and time
  // The room between the notch and the widgets; the date, the time and the
  // password field sit centred in it.
  Item {
    id: region
    y: notch.height
    width: parent.width
    height: (root.hasWidgets ? widgets.restY : root.height) - y

    Column {
      id: stack
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round((parent.height - height) / 2)

      // The date, small, over the time.
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        opacity: root.clockT
        Text {
          text: Qt.formatDate(root.stamp, "dddd")
          textFormat: Text.PlainText
          color: Theme.text
          font.family: P.sans
          font.pixelSize: 19
          font.weight: Font.DemiBold
        }
        Text {
          text: Qt.formatDate(root.stamp, "d MMMM")
          textFormat: Text.PlainText
          color: Theme.secondary
          font.family: P.sans
          font.pixelSize: 19
        }
      }

      Item { width: 1; height: 18 }

      // The time. It rises into place as it fades in.
      Item {
        id: clockBox
        anchors.horizontalCenter: parent.horizontalCenter
        width: clock.width
        height: clock.height
        TallClock {
          id: clock
          text: root.timeText
          glyphHeight: Math.round(Math.min(470, root.height * 0.43))
          motion: root.motion
          rollOverride: root.rollOverride
          opacity: root.clockT
          y: 22 * (1 - root.clockT)
        }
      }

      Item { width: 1; height: 40 }

      // LockView draws the password field here.
      Item {
        id: pillSlot
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.pillWidth
        height: root.pillHeight
      }
    }
  }

  // ===================================================== the widget row
  readonly property bool hasWidgets: agents.length > 0 || sessions.length > 0 || hasPlayer || hasSystem
  readonly property bool hasPlayer: !!player && String(player.title || "").length > 0
  readonly property bool hasSystem: system && system.cpu !== undefined && system.cpu !== null
  Row {
    id: widgets
    readonly property real margin: 30
    readonly property real restY: root.height - height - margin
    anchors.horizontalCenter: parent.horizontalCenter
    y: restY + 26 * (1 - root.widgetsT)
    opacity: root.widgetsT
    spacing: 12
    visible: root.hasWidgets

    LimitsWidget {
      visible: root.agents.length > 0
      agents: root.agents
      sessions: root.sessions
      now: root.now
      reveal: root.ringT
      motion: root.motion
    }
    SessionsWidget {
      sessions: root.sessions
      now: root.now
      motion: root.motion
    }
    TodayWidget {
      visible: Number(root.today.prompts) > 0 || Number(root.today.tokens) > 0
      today: root.today
    }
    SystemWidget {
      visible: root.hasSystem
      system: root.system
    }
    MusicWidget {
      visible: root.hasPlayer
      player: root.player
      onAction: function(name) { root.mediaAction(name) }
    }
  }
}
