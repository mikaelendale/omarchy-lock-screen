import QtQuick
import "Palette.js" as P

// One lock screen widget: a small slab of the notch's frosted glass floating
// over the wallpaper, with a title in its top-left corner. Every widget is
// the same height so the row reads as one.
Rectangle {
  id: root

  property string title: ""
  property string note: ""          // grey, after the title
  default property alias content: body.data
  readonly property real pad: 15

  height: 112
  radius: 24
  border.width: 1
  border.color: Theme.edge
  gradient: Gradient {
    GradientStop { position: 0; color: Theme.bodyTop }
    GradientStop { position: 1; color: Theme.body }
  }

  Row {
    id: heading
    x: root.pad
    y: root.pad - 1
    spacing: 7
    visible: root.title.length > 0
    Text {
      text: root.title
      textFormat: Text.PlainText
      color: Theme.text
      font.family: P.sans
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }
    Text {
      visible: text.length > 0
      text: root.note
      textFormat: Text.PlainText
      color: Theme.secondary
      font.family: P.sans
      font.pixelSize: 12
    }
  }

  // Under the title, inside the padding.
  Item {
    id: body
    x: root.pad
    y: root.title.length > 0 ? heading.y + heading.height + 9 : root.pad
    width: root.width - 2 * root.pad
    height: root.height - y - root.pad + 2
  }
}
