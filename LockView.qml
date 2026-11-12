import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The lock screen, restyled in the notch's language (Omarchy's LockView is
// the starting point; Service.qml, which does the unlocking, is unchanged).
//
// This file keeps only what unlocking needs: the wallpaper, blurred, and the
// password field. Everything else (the notch, the time, the agents' limits
// and sessions) lives in decor/ and comes in through Loaders, so if anything
// there ever fails to load, the field still works and the screen still
// unlocks; it just looks plainer.
Item {
  id: root

  property string backgroundPath: ""
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintUnavailable: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: Commons.I18n.t("lock.enterPassword")
  readonly property string sans: "Adwaita Sans"
  readonly property string glyphs: "JetBrainsMono Nerd Font"
  readonly property int fieldFontSize: 15
  readonly property int passwordDotFontSize: 17
  readonly property int passwordDotLetterSpacing: 5
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0

  // A video wallpaper shows its still poster: nothing plays behind the lock.
  readonly property bool video: Util.isVideoPath(root.backgroundPath)

  // ---- the look, when decor/ loaded; plain fallbacks when it didn't
  readonly property var decor: decorLoader.status === Loader.Ready ? decorLoader.item : null
  readonly property var theme: decor ? decor.theme : null
  readonly property bool darkFallback: {
    var c = Commons.Color.background
    return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b < 0.5
  }
  readonly property bool dark: theme ? theme.dark : darkFallback
  readonly property color glass: theme ? theme.body : Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, 0.86)
  readonly property color glassTop: theme ? theme.bodyTop : glass
  readonly property color rim: theme ? theme.edge : (dark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.09))
  readonly property color ink: theme ? theme.text : Commons.Color.lock.text
  readonly property color inkSoft: theme ? theme.secondary : Commons.Color.lock.placeholder
  readonly property color inkError: theme ? theme.red : Commons.Color.lock.textError
  readonly property color inkOn: theme ? theme.onText : Commons.Color.background
  readonly property real motion: Style.duration(100) > 0 ? 1 : 0

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  // Waking a DPMS-blanked display can stall the compositor for seconds while
  // the monitor modesets, so the wake key's release arrives late and client-side
  // key repeat floods the field with that character. A held key has no business
  // typing a password; only holding Backspace/Delete to clear stays useful.
  function dropsAutoRepeat(key) {
    return key !== Qt.Key_Backspace && key !== Qt.Key_Delete
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  // The field loses focus while a password is checked (it is disabled then),
  // and forcing focus onto it would not stick until the check ends.
  function restorePasswordFocus() {
    if (inputEnabled && passwordInput.enabled && !passwordInput.activeFocus) forcePasswordFocus()
  }

  function submit() {
    var submitted = root.passwordText
    root.passwordTextEdited("")
    if (submitted.length > 0) root.submitPassword(submitted)
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  // A wrong password shakes the field, the way a phone does.
  onFailedAttemptsChanged: if (failedAttempts > 0 && motion > 0) shake.restart()

  // A VT switch, which the NVIDIA driver forces around every suspend, takes the
  // keyboard away and Qt drops the field's focus with it. Nothing gives it back
  // when the keyboard returns, so typing went nowhere until the field was clicked.
  Window.onActiveFocusItemChanged: Qt.callLater(restorePasswordFocus)
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: root.sans
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background

    BackgroundMedia {
      id: wallpaper
      objectName: "lockWallpaper"
      anchors.fill: parent
      path: root.loadBackground ? (root.video ? root.videoPosterPath : root.backgroundPath) : ""
      version: root.backgroundVersion
      // Decode only once sized, at the lock's own size: an unsized first
      // request decoded the file at its native resolution, then again once
      // sized. That size is what the lock service keeps decoded ahead of the
      // lock, so the first frame has the wallpaper.
      cached: true
      constrainDecode: true
      decodeSize: Qt.size(width, height)
    }

    // The wallpaper, blurred until it's only its colours, a little richer.
    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.4
      saturation: 0.12
      contrast: -0.06
    }

    // A wash in the theme's own background colour, so the time and the glass
    // read on any wallpaper, light themes as well as dark.
    Rectangle {
      anchors.fill: parent
      color: Commons.Color.background
      opacity: root.dark ? 0.34 : 0.26
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }
  }

  // ---- what LockDecor shows, gathered only while the lock is up
  Loader {
    id: dataLoader
    source: "decor/LockData.qml"
    onLoaded: item.active = Qt.binding(function() { return root.loadBackground })
  }

  Loader {
    id: decorLoader
    anchors.fill: parent
    source: "decor/LockDecor.qml"
    onLoaded: {
      item.active = Qt.binding(function() { return root.loadBackground })
      item.motion = Qt.binding(function() { return root.motion })
      item.sessions = Qt.binding(function() { return dataLoader.item ? dataLoader.item.sessions : [] })
      item.agents = Qt.binding(function() { return dataLoader.item ? dataLoader.item.agents : [] })
      item.battery = Qt.binding(function() { return dataLoader.item ? dataLoader.item.battery : ({ present: false }) })
      item.today = Qt.binding(function() { return dataLoader.item ? dataLoader.item.today : ({ prompts: 0, tokens: 0, sessions: 0 }) })
      item.system = Qt.binding(function() { return dataLoader.item ? dataLoader.item.system : ({}) })
      item.player = Qt.binding(function() { return dataLoader.item ? dataLoader.item.player : null })
      item.mediaAction.connect(function(name) { if (dataLoader.item) dataLoader.item.mediaAction(name) })
    }
  }

  // ---- the password field: a pill of the notch's glass
  Item {
    id: pill
    width: root.decor ? root.decor.pillWidth : 360
    height: root.decor ? root.decor.pillHeight : 54
    x: Math.round((parent.width - width) / 2)
    y: Math.round(root.decor ? root.decor.pillY : (parent.height - height) / 2)
    opacity: root.decor ? root.decor.contentT : 1
    transform: [
      Translate { y: root.decor ? 14 * (1 - root.decor.contentT) : 0 },
      Translate { id: shakeShift; x: 0 }
    ]

    SequentialAnimation {
      id: shake
      NumberAnimation { target: shakeShift; property: "x"; to: 12; duration: 50; easing.type: Easing.OutQuad }
      NumberAnimation { target: shakeShift; property: "x"; to: -10; duration: 80; easing.type: Easing.InOutQuad }
      NumberAnimation { target: shakeShift; property: "x"; to: 7; duration: 70; easing.type: Easing.InOutQuad }
      NumberAnimation { target: shakeShift; property: "x"; to: -4; duration: 60; easing.type: Easing.InOutQuad }
      NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 60; easing.type: Easing.OutQuad }
    }

    Rectangle {
      id: field
      anchors.fill: parent
      radius: height / 2
      border.width: 1
      border.color: root.errorState ? Qt.rgba(root.inkError.r, root.inkError.g, root.inkError.b, 0.55) : root.rim
      Behavior on border.color { ColorAnimation { duration: 160 } }
      gradient: Gradient {
        GradientStop { position: 0; color: root.glassTop }
        GradientStop { position: 1; color: root.glass }
      }
    }

    TextInput {
      id: passwordInput
      anchors.fill: parent
      anchors.leftMargin: 56
      anchors.rightMargin: 56
      verticalAlignment: TextInput.AlignVCenter
      horizontalAlignment: TextInput.AlignHCenter
      activeFocusOnPress: true
      clip: true
      enabled: root.inputEnabled && !root.authenticatingPassword
      readOnly: root.authenticatingPassword
      echoMode: TextInput.Password
      passwordCharacter: "●"
      passwordMaskDelay: 0
      color: root.ink
      selectionColor: Commons.Color.lock.selection
      selectedTextColor: root.ink
      font.family: root.sans
      font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
      font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
      cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
      cursorDelegate: Rectangle {
        width: 2
        color: root.ink
        visible: passwordInput.cursorVisible
      }

      onTextChanged: {
        if (!root.syncingPasswordText) root.passwordTextEdited(text)
        if (text.length > 0) {
          root.wakeRequested()
        }
        if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
      }

      onAccepted: root.submit()

      Keys.onPressed: function(event) {
        root.wakeRequested()
        if (event.isAutoRepeat && root.dropsAutoRepeat(event.key)) {
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
          root.passwordTextEdited("")
          event.accepted = true
        }
      }
    }

    Text {
      textFormat: Text.PlainText
      anchors.fill: passwordInput
      // Omarchy's failure text is "Authentication failed (2)"; say it plainly.
      text: root.authenticatingPassword ? Commons.I18n.t("lock.checking") : (root.errorState ? "Wrong password" : root.placeholderText)
      visible: passwordInput.text.length === 0
      color: root.authenticatingPassword ? root.ink : (root.errorState ? root.inkError : root.inkSoft)
      font.family: root.sans
      font.pixelSize: root.fieldFontSize
      font.weight: root.errorState ? Font.Medium : Font.Normal
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }

    // The fingerprint hint, while nothing's typed: touch to unlock instead.
    // A reader the shell cannot reach crosses out rather than disappears, so
    // it stops inviting touches that can never unlock.
    Text {
      id: fingerprintIcon
      objectName: "fingerprintIndicator"
      textFormat: Text.PlainText
      anchors.right: parent.right
      anchors.rightMargin: 20
      anchors.verticalCenter: parent.verticalCenter
      visible: root.fingerprintConfigured && passwordInput.text.length === 0
      text: root.fingerprintUnavailable ? "󰺱" : "󰈷"
      color: root.fingerprintUnavailable ? root.inkError : root.inkSoft
      font.family: root.glyphs
      font.pixelSize: 20
    }

    // Once something's typed, a round button to unlock with (Enter works too).
    Rectangle {
      id: go
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: parent.height - 16
      height: width
      radius: width / 2
      color: root.ink
      opacity: passwordInput.text.length > 0 ? (goHover.hovered ? 1 : 0.9) : 0
      scale: passwordInput.text.length > 0 ? 1 : 0.6
      visible: opacity > 0.01
      Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 1
        text: String.fromCodePoint(0xF0054)   // nf-md-arrow_right
        textFormat: Text.PlainText
        color: root.inkOn
        font.family: root.glyphs
        font.pixelSize: 18
      }
      HoverHandler { id: goHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: { root.submit(); root.forcePasswordFocus() } }
    }
  }

  // The crossed-out icon has no meaning to a user who has never seen it, so
  // the words carry the explanation and the icon only reinforces it.
  Text {
    objectName: "fingerprintUnavailableNotice"
    textFormat: Text.PlainText
    anchors.top: pill.bottom
    anchors.topMargin: 14
    anchors.horizontalCenter: pill.horizontalCenter
    visible: root.fingerprintConfigured && root.fingerprintUnavailable
    text: Commons.I18n.t("lock.fingerprintUnavailable")
    color: root.inkError
    font.family: root.sans
    font.pixelSize: 13
    horizontalAlignment: Text.AlignHCenter
  }
}
