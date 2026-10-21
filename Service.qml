import QtQuick
import Quickshell

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginDir: decodeURIComponent(Qt.resolvedUrl(".").toString().replace("file://", ""))
  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") + "/browser-boost"
  readonly property string script: runtimeDir + "/bin/browser-boost"
  readonly property int updateCheckInterval: 60 * 1000

  function run(action) {
    Quickshell.execDetached(["bash", root.script, action])
  }

  // `omarchy plugin remove` moves the plugin folder away before this service
  // is destroyed, so release has to run from a copy outside it.
  Component.onCompleted: Quickshell.execDetached(["sh", "-c",
    'mkdir -p "$2/bin" && cp "$1/manifest.json" "$2/" && cp "$1/bin/browser-boost" "$2/bin/" && exec bash "$2/bin/browser-boost" start',
    "sh", root.pluginDir, root.runtimeDir])
  Component.onDestruction: run("release")

  Timer {
    interval: root.updateCheckInterval
    running: true
    repeat: true
    onTriggered: root.run("check")
  }
}
