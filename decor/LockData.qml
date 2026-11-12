import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// What the lock screen shows, gathered only while it's showing:
//
//   sessions  every coding agent's sessions, from the notch's agents.py
//   agents    each signed-in agent's plan limits, from usage.py
//   today     prompts, tokens and sessions so far today, from usage.py
//   system    CPU, memory, temperature and uptime, from system.py
//   battery   from UPower
//   player    what's playing, from MPRIS, with play/pause and skip
//
// It also tints Theme from the current Omarchy theme, as the notch does.
Item {
  id: root

  property bool active: false

  property var sessions: []
  property var agents: []
  property var today: ({ prompts: 0, tokens: 0, sessions: 0 })
  property var system: ({})
  readonly property var battery: {
    var d = UPower.displayDevice
    if (!d || !d.isPresent) return { present: false }
    var level = Number(d.percentage || 0)
    if (level > 1) level = level / 100
    var charging = d.state === UPowerDeviceState.Charging || (d.state === UPowerDeviceState.FullyCharged && !UPower.onBattery)
    return { present: true, level: level, charging: charging }
  }

  // ---- what's playing: the player that's playing, else the last with a track
  readonly property var mprisPlayer: {
    var list = Mpris.players ? Mpris.players.values : []
    var fallback = null
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      if (!p) continue
      if (p.isPlaying) return p
      if (!fallback && p.trackTitle) fallback = p
    }
    return fallback
  }
  readonly property var player: mprisPlayer ? {
    title: String(mprisPlayer.trackTitle || ""),
    artist: String(mprisPlayer.trackArtist || ""),
    art: String(mprisPlayer.trackArtUrl || ""),
    playing: !!mprisPlayer.isPlaying,
    canNext: !!mprisPlayer.canGoNext,
    canPrevious: !!mprisPlayer.canGoPrevious
  } : null
  function mediaAction(action) {
    var p = mprisPlayer
    if (!p) return
    if (action === "toggle" && p.canTogglePlaying) p.togglePlaying()
    else if (action === "next" && p.canGoNext) p.next()
    else if (action === "previous" && p.canGoPrevious) p.previous()
  }

  readonly property string home: Quickshell.env("HOME")
  readonly property string here: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

  // ---- colours from the current theme, re-read whenever a theme is set
  readonly property string themeDir: home + "/.local/state/omarchy/current"
  FileView {
    id: themeColors
    path: root.themeDir + "/theme/colors.toml"
    printErrors: false
    onLoaded: {
      var values = ({})
      var lines = text().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var m = lines[i].match(/^\s*([a-z_]+)\s*=\s*"([^"]*)"/)
        if (m) values[m[1]] = m[2]
      }
      Theme.apply(values)
    }
  }
  FileView {
    path: root.themeDir + "/theme.generation"
    watchChanges: true
    printErrors: false
    onFileChanged: { reload(); themeColors.reload() }
  }

  // ---- sessions: the notch's collector, wherever the notch is installed
  Process {
    id: sessionsProc
    running: root.active
    command: ["sh", "-c",
      'for d in "$HOME/.config/omarchy/plugins/notch" "$HOME/.config/omarchy/plugins/mike.notch"; do ' +
      '[ -f "$d/agents.py" ] && exec python3 -I -B "$d/agents.py"; done; exit 3']
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(line)
          if (data && Array.isArray(data.sessions)) root.sessions = root.sorted(data.sessions)
        } catch (e) {}
      }
    }
    onExited: function(code) { if (root.active && code !== 3) sessionsRestart.start() }
  }
  Timer { id: sessionsRestart; interval: 5000; onTriggered: if (root.active) sessionsProc.running = true }
  onActiveChanged: if (!active) sessions = []

  function sorted(list) {
    var order = { needs: 0, done: 1, working: 2, watching: 3, idle: 4 }
    var out = list.slice()
    out.sort(function(a, b) {
      return (a.state in order ? order[a.state] : 9) - (b.state in order ? order[b.state] : 9)
    })
    return out
  }

  // ---- plan limits and today's activity, every minute while showing
  Process {
    id: usageProc
    command: ["python3", "-I", "-B", root.here + "usage.py"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(line)
          if (data && Array.isArray(data.agents)) root.agents = data.agents
          if (data && data.today) root.today = data.today
        } catch (e) {}
      }
    }
  }
  Timer {
    interval: 60000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!usageProc.running) usageProc.running = true
  }

  // ---- the machine, every five seconds while showing
  Process {
    id: systemProc
    command: ["python3", "-I", "-B", root.here + "system.py"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(line)
          if (data) root.system = data
        } catch (e) {}
      }
    }
  }
  Timer {
    interval: 5000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!systemProc.running) systemProc.running = true
  }
}
