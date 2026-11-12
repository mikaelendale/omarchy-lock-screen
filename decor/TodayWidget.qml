import QtQuick
import "Palette.js" as P

// Today's coding, every agent added up: prompts, large, then tokens and
// sessions. Counts only, nothing anyone said.
Glass {
  id: root

  property var today: ({ prompts: 0, tokens: 0, sessions: 0 })

  title: "Today"
  width: Math.max(150, stats.implicitWidth + 2 * pad)

  function compact(n) {
    n = Number(n) || 0
    if (n >= 1e9) return (n / 1e9).toFixed(n >= 1e10 ? 0 : 1).replace(/\.0$/, "") + "B"
    if (n >= 1e6) return (n / 1e6).toFixed(n >= 1e7 ? 0 : 1).replace(/\.0$/, "") + "M"
    if (n >= 1e3) return (n / 1e3).toFixed(n >= 1e4 ? 0 : 1).replace(/\.0$/, "") + "K"
    return String(n)
  }

  Column {
    id: stats
    spacing: 2
    Row {
      spacing: 6
      Text {
        id: big
        text: root.compact(root.today.prompts)
        textFormat: Text.PlainText
        color: Theme.text
        font.family: P.sans
        font.pixelSize: 28
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
      }
      Text {
        anchors.baseline: big.baseline
        text: Number(root.today.prompts) === 1 ? "prompt" : "prompts"
        textFormat: Text.PlainText
        color: Theme.secondary
        font.family: P.sans
        font.pixelSize: 12
      }
    }
    Text {
      text: root.compact(root.today.tokens) + " tokens  ·  " + (Number(root.today.sessions) || 0) + (Number(root.today.sessions) === 1 ? " session" : " sessions")
      textFormat: Text.PlainText
      color: Theme.secondary
      font.family: P.sans
      font.pixelSize: 11
      font.features: { "tnum": 1 }
    }
  }
}
