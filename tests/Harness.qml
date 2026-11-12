import QtQuick
import QtQuick.Window
import qs.Commons as Commons
import ".."

// Draws the lock screen off screen, one scenario per run, into <outdir>.
//   QT_QPA_PLATFORM=offscreen qml6 -I tests/mock tests/Harness.qml -- <outdir> <scenario>
// tests/mock stands in for Omarchy's qs.Commons and qs.Ui; LockData (which
// needs Quickshell) doesn't load here, so the scenario feeds LockDecor itself.
// The wallpaper is pre-blurred (blurred-*.jpg): MultiEffect doesn't draw off
// screen.
Window {
  id: win
  width: 1920
  height: 1080
  visible: true
  color: "black"

  readonly property var args: Qt.application.arguments
  readonly property string outdir: args[args.length - 2]
  readonly property string scenario: args[args.length - 1]
  readonly property bool light: scenario.indexOf("light") !== -1
  readonly property string here: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

  readonly property var themeDark: ({ mode: "dark", background: "#282828", foreground: "#d4be98", bright_foreground: "#d4be98", accent: "#7daea3" })
  readonly property var themeLight: ({ mode: "light", background: "#eff1f5", foreground: "#4c4f69", bright_foreground: "#4c4f69", accent: "#1e66f5" })

  readonly property var agents: [
    { id: "claude", name: "Claude Code", tier: "Team 5x", limits: [
      { label: "5-hour", percent: 0.62, resetsAt: new Date(Date.now() + 8100000).toISOString() },
      { label: "Weekly", percent: 0.15, resetsAt: new Date(Date.now() + 5 * 86400000).toISOString() },
      { label: "Fable weekly", percent: 0.93, resetsAt: new Date(Date.now() + 5 * 86400000).toISOString() } ] },
    { id: "codex", name: "Codex", tier: "Business", limits: [
      { label: "5-hour", percent: 0.81, resetsAt: new Date(Date.now() + 2700000).toISOString() },
      { label: "Weekly", percent: 0.04, resetsAt: new Date(Date.now() + 6 * 86400000).toISOString() } ] }
  ]
  readonly property var sessions: [
    { agent: "claude", agentName: "Claude", project: "website", state: "needs", since: Date.now() - 12 * 60000 },
    { agent: "claude", agentName: "Claude", project: "api", state: "working", since: Date.now() - 3 * 60000 },
    { agent: "codex", agentName: "Codex", project: "mobile-app", state: "done", since: Date.now() - 40 * 60000 },
    { agent: "claude", agentName: "Claude", project: "docs", state: "idle", since: Date.now() - 3 * 3600000 }
  ]
  readonly property var crowd: {
    var out = []
    var states = ["needs", "needs", "done", "working", "working", "watching", "idle", "idle", "idle", "idle"]
    var projects = ["website", "api", "mobile-app", "docs", "dashboard", "infra", "a-project-with-a-very-long-folder-name", "design", "cli", "billing"]
    for (var i = 0; i < 10; i++) out.push({ agent: i % 3 === 1 ? "codex" : "claude", agentName: i % 3 === 1 ? "Codex" : "Claude", project: projects[i], state: states[i] })
    return out
  }

  LockView {
    id: view
    anchors.fill: parent
    backgroundPath: win.here + (win.light ? "blurred-light.jpg" : "blurred-dark.jpg")
    loadBackground: false
    inputEnabled: true
    fingerprintConfigured: win.scenario.indexOf("finger") !== -1
  }

  Timer {
    id: shoot
    interval: 250
    onTriggered: {
      win.contentItem.grabToImage(function(result) {
        result.saveToFile(win.outdir + "/" + win.scenario + (win.frameTag ? "-" + win.frameTag : "") + ".png")
        win.next()
      })
    }
  }

  property string frameTag: ""
  property var frames: []
  function next() {
    if (frames.length === 0) { Qt.quit(); return }
    var f = frames.shift()
    frameTag = f.tag
    f.run()
    shoot.restart()
  }

  Component.onCompleted: {
    var light = win.light
    var c = light ? themeLight : themeDark
    Commons.Color.background = c.background
    Commons.Color.foreground = c.foreground
    Commons.Color.accent = c.accent
    var d = view.decor
    d.theme.apply(c)
    view.loadBackground = true
    var s = win.scenario.replace("-light", "")
    d.agents = (s === "empty" || s === "sessions-only") ? [] : win.agents
    d.sessions = s === "empty" ? [] : (s === "many" ? win.crowd : (s === "limits-only" ? [] : (s === "two" ? win.sessions.slice(0, 2) : win.sessions)))
    d.battery = { present: true, level: 0.64, charging: s === "charging" }
    d.today = s === "empty" ? { prompts: 0, tokens: 0, sessions: 0 } : { prompts: 61, tokens: 553197446, sessions: 11 }
    d.system = s === "empty" ? ({}) : { cpu: 23, memory: 53, temp: 60, uptime: 70212 }
    d.player = (s === "empty" || s === "nomusic") ? null
      : { title: "A Song With A Fairly Long Title", artist: "Some Artist", art: "file://" + win.here + "blurred-light.jpg", playing: true, canNext: true, canPrevious: true }
    // A fixed time, so every run shows the same digits.
    d.fixedTime = new Date(2026, 10, 12, light ? 8 : 10, light ? 32 : 47).getTime()
    // Switching to that time rolls the digits; static shots show the end.
    d.rollOverride = 1
    if (s === "typing" || s === "finger-typing") view.passwordText = "hunter22"
    if (s === "error") { view.failureMessage = "Authentication failed (1)"; view.failedAttempts = 1 }
    if (s === "checking") view.authenticatingPassword = true

    if (s === "roll") {
      // 8:59 → 9:00: every digit rolls; frozen at points through the roll.
      d.fixedTime = new Date(2026, 10, 12, 8, 59).getTime()
      win.frames.push({ tag: "set", run: function() { d.scrubIntro(5000); d.fixedTime = new Date(2026, 10, 12, 9, 0).getTime(); d.rollOverride = 0 } })
      var rolls = [0, 0.15, 0.3, 0.5, 0.7, 0.85, 1]
      for (var r = 0; r < rolls.length; r++) (function(t) {
        win.frames.push({ tag: "t" + Math.round(t * 100), run: function() { d.rollOverride = t } })
      })(rolls[r])
    } else if (s === "intro") {
      var times = [0, 60, 120, 200, 280, 360, 460, 560, 700, 900, 1100]
      for (var i = 0; i < times.length; i++) (function(t) {
        win.frames.push({ tag: ("000" + t).slice(-4), run: function() { view.decor.scrubIntro(t) } })
      })(times[i])
    } else if (s === "shake") {
      // The shake is driven by its own animation; step it by hand.
      var steps = [0, 25, 50, 90, 130, 170, 200, 240, 280, 320]
      view.failureMessage = "Authentication failed (1)"
      for (var j = 0; j < steps.length; j++) (function(t) {
        win.frames.push({ tag: ("000" + t).slice(-4), run: function() { win.shakeAt(t) } })
      })(steps[j])
    } else {
      win.frames.push({ tag: "", run: function() { d.scrubIntro(5000) } })
    }
    win.next()
  }

  // The shake's offset at t ms, from its keyframes (mirrors LockView's).
  function shakeAt(t) {
    var keys = [[0, 0], [50, 12], [130, -10], [200, 7], [260, -4], [320, 0]]
    var x = 0
    for (var i = 1; i < keys.length; i++) {
      if (t <= keys[i][0]) {
        var a = keys[i - 1], b = keys[i]
        var p = (t - a[0]) / (b[0] - a[0])
        x = a[1] + (b[1] - a[1]) * p
        break
      }
    }
    view.decor.scrubIntro(5000)
    var pill = view.children[view.children.length - 2]
    pill.transform[1].x = x
  }
}
