import QtQuick
import "Palette.js" as P

// The machine at a glance: how busy the processors are, memory in use, the
// CPU's temperature (when a sensor reports one) and how long it's been up.
Glass {
  id: root

  property var system: ({})

  title: "System"
  note: uptimeText(system.uptime)
  width: Math.max(170, cols.implicitWidth + 2 * pad)

  function uptimeText(s) {
    s = Number(s)
    if (!(s > 0)) return ""
    var mins = Math.floor(s / 60)
    if (mins < 60) return "up " + mins + "m"
    var h = Math.floor(mins / 60)
    if (h < 48) return "up " + h + "h " + (mins % 60) + "m"
    return "up " + Math.floor(h / 24) + "d"
  }
  function tone(value, warm, hot) {
    if (value >= hot) return Theme.red
    if (value >= warm) return Theme.orange
    return Theme.text
  }

  Row {
    id: cols
    spacing: 18
    Repeater {
      model: [
        { label: "CPU", value: root.system.cpu, unit: "%", warm: 75, hot: 90 },
        { label: "Memory", value: root.system.memory, unit: "%", warm: 80, hot: 92 },
        { label: "Temp", value: root.system.temp, unit: "°", warm: 80, hot: 92 }
      ]
      Column {
        visible: modelData.value !== null && modelData.value !== undefined
        spacing: 1
        Row {
          Text {
            id: num
            text: Math.round(Number(modelData.value) || 0)
            textFormat: Text.PlainText
            color: root.tone(Number(modelData.value) || 0, modelData.warm, modelData.hot)
            font.family: P.sans
            font.pixelSize: 24
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
          }
          Text {
            anchors.baseline: num.baseline
            text: modelData.unit
            textFormat: Text.PlainText
            color: Theme.secondary
            font.family: P.sans
            font.pixelSize: 13
            font.weight: Font.Medium
          }
        }
        Text {
          text: modelData.label
          textFormat: Text.PlainText
          color: Theme.secondary
          font.family: P.sans
          font.pixelSize: 11
        }
      }
    }
  }
}
