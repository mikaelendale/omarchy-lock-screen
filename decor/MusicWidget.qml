import QtQuick
import QtQuick.Shapes
import "Palette.js" as P

// What's playing: the cover, the track and artist, and back / play-pause /
// skip. Shown only while a player has a track.
Glass {
  id: root

  property var player: null         // { title, artist, art, playing, canNext, canPrevious }
  signal action(string name)

  width: 280

  readonly property real coverSize: height - 2 * pad

  Image {
    id: art
    visible: false
    source: root.player && root.player.art ? root.player.art : ""
    sourceSize.width: 192
    sourceSize.height: 192
    fillMode: Image.PreserveAspectCrop
    width: root.coverSize
    height: root.coverSize
    asynchronous: true
  }

  // The cover, rounded: the path is filled with the image itself.
  Shape {
    id: cover
    width: root.coverSize
    height: root.coverSize
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillColor: art.status === Image.Ready ? "transparent" : Theme.card
      fillItem: art.status === Image.Ready ? art : null
      PathRectangle { width: cover.width; height: cover.height; radius: 16 }
    }
    Text {
      anchors.centerIn: parent
      visible: art.status !== Image.Ready
      text: String.fromCodePoint(0xF075A)   // nf-md-music_note
      textFormat: Text.PlainText
      color: Theme.secondary
      font.family: P.glyphs
      font.pixelSize: 28
    }
  }

  Column {
    anchors.left: cover.right
    anchors.leftMargin: 13
    anchors.right: parent.right
    y: 2
    spacing: 1
    Text {
      width: parent.width
      text: root.player ? root.player.title : ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.text
      font.family: P.sans
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width
      visible: text.length > 0
      text: root.player ? root.player.artist : ""
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: Theme.secondary
      font.family: P.sans
      font.pixelSize: 12
    }
  }

  Row {
    anchors.left: cover.right
    anchors.leftMargin: 6
    anchors.bottom: cover.bottom
    spacing: 4
    Repeater {
      model: [
        { name: "previous", glyph: 0xF04AE, on: root.player && root.player.canPrevious },
        { name: "toggle", glyph: root.player && root.player.playing ? 0xF03E4 : 0xF040A, on: true },
        { name: "next", glyph: 0xF04AD, on: root.player && root.player.canNext }
      ]
      Rectangle {
        width: 32
        height: 32
        radius: 16
        color: tap.hovered ? Theme.cardHover : "transparent"
        opacity: modelData.on ? 1 : 0.35
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
          anchors.centerIn: parent
          text: String.fromCodePoint(modelData.glyph)
          textFormat: Text.PlainText
          color: Theme.text
          font.family: P.glyphs
          font.pixelSize: modelData.name === "toggle" ? 22 : 18
        }
        HoverHandler { id: tap; cursorShape: Qt.PointingHandCursor }
        TapHandler { enabled: !!modelData.on; onTapped: root.action(modelData.name) }
      }
    }
  }
}
