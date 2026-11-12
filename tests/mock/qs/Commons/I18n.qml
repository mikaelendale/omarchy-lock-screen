pragma Singleton
import QtQuick
QtObject {
  property bool rightToLeft: false
  readonly property var strings: ({ "lock.enterPassword": "Enter Password", "lock.checking": "Checking…",
    "lock.fingerprintUnavailable": "Fingerprint reader unavailable", "lock.authenticationFailed": "Authentication failed (%1)" })
  function t(key) { return strings[key] || key }
}
