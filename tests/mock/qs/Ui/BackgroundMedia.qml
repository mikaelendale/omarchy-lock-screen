import QtQuick
// Stand-in for Omarchy's BackgroundMedia: a plain image.
Item {
  id: root
  property string path: ""
  property int version: 0
  property bool cached: true
  property bool constrainDecode: false
  property size decodeSize: Qt.size(0, 0)
  readonly property bool ready: img.status === Image.Ready
  readonly property bool failed: img.status === Image.Error
  Image { id: img; anchors.fill: parent; source: root.path ? "file://" + root.path : ""; fillMode: Image.PreserveAspectCrop; asynchronous: false }
}
