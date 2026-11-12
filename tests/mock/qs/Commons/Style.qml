pragma Singleton
import QtQuick
QtObject {
  property bool animations: true
  function duration(ms) { return animations ? ms : 0 }
  readonly property QtObject font: QtObject { property string family: "Adwaita Sans"; property int heading: 16 }
}
