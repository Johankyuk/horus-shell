import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

ShellRoot {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string ledPath: "/sys/class/leds/asus::kbd_backlight"

  // ── Estado del OSD (un solo componente multiplexado) ─────────
  // Todas las fuentes escriben aqui: nunca puede haber dos capsulas
  // encimadas porque solo existe una.
  property string icon: ""
  property string label: ""
  property real fraction: 0
  property bool showBar: true
  property int iconSize: 15
  property bool showing: false
  property bool windowVisible: false

  // Las propiedades se asientan al arrancar (Pipewire enumera, sysfs lee):
  // hasta que esto no sea true, ningun cambio dispara la capsula.
  property bool armed: false

  function show(ic, lb, fr, bar) {
    if (!armed) return;
    icon = ic; label = lb; fraction = fr; showBar = bar;
    iconSize = (ic === "\uf11c") ? 18 : 15;   // el teclado tiene caja mas chica
    showing = true;
    hideTimer.restart();
  }

  onShowingChanged: {
    if (showing) { windowVisible = true; fadeOutTimer.stop(); }
    else { fadeOutTimer.restart(); }
  }

  Timer { interval: 1500; running: true; onTriggered: root.armed = true }
  Timer { id: hideTimer; interval: 1400; onTriggered: root.showing = false }
  Timer { id: fadeOutTimer; interval: 220; onTriggered: root.windowVisible = false }

  // ── Paleta del tema (horus-theme regenera palette.json) ──────
  property color cPrimary: "#8b45f7"
  property color cSurface: "#18092b"
  property color cOnSurface: "#b88cf2"
  property color cOutline: "#5031a0"

  function refreshPalette() {
    try {
      var p = JSON.parse(paletteFile.text());
      if (p.mPrimary)   cPrimary   = p.mPrimary;
      if (p.mSurface)   cSurface   = p.mSurface;
      if (p.mOnSurface) cOnSurface = p.mOnSurface;
      if (p.mOutline)   cOutline   = p.mOutline;
    } catch (e) {
      // JSON a medio escribir: se conserva la paleta anterior.
    }
  }

  FileView {
    id: paletteFile
    path: root.home + "/.config/horus/palette.json"
    onLoaded: root.refreshPalette()
  }
  Timer { interval: 2000; running: true; repeat: true; onTriggered: paletteFile.reload() }

  // ── Fuente 1: brillo del teclado ─────────────────────────────
  // sysfs no emite inotify, asi que se sondea.
  property int kbdMax: 3
  property int kbdValue: -1

  FileView {
    id: kbdMaxFile
    path: root.ledPath + "/max_brightness"
    onLoaded: {
      var n = parseInt(text().trim());
      if (!isNaN(n) && n > 0) root.kbdMax = n;
    }
  }
  FileView { id: kbdFile; path: root.ledPath + "/brightness" }

  Timer {
    interval: 120
    running: true
    repeat: true
    onTriggered: {
      var n = parseInt(kbdFile.text().trim());
      if (!isNaN(n) && n !== root.kbdValue) {
        root.kbdValue = n;
        var f = n / root.kbdMax;
        root.show("\uf11c", Math.round(f * 100) + "%", f, true);
      }
      kbdFile.reload();
    }
  }

  // ── Fuente 2: volumen ────────────────────────────────────────
  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property var sinkAudio: sink ? sink.audio : null

  // Sin el tracker, las propiedades del nodo no se actualizan.
  PwObjectTracker { objects: root.sink ? [root.sink] : [] }

  function onVolume() {
    if (!sinkAudio) return;
    if (sinkAudio.muted) {
      root.show("\uf026", "Silencio", 0, true);
      return;
    }
    var v = Math.max(0, Math.min(1, sinkAudio.volume));
    root.show(v <= 0.5 ? "\uf027" : "\uf028", Math.round(v * 100) + "%", v, true);
  }

  Connections {
    target: root.sinkAudio
    function onVolumeChanged() { root.onVolume(); }
    function onMutedChanged() { root.onVolume(); }
  }

  // ── Fuente 3: perfil de energia — PARKED ─────────────────────
  // Noctalia lo anuncia con ToastService.showNotice sin gate de settings:
  // no es apagable por config. Duplicarlo es peor que dejar el suyo, asi que
  // este modo vuelve cuando la barra (y el toggle) sean de horus-shell.

  // ── La capsula ───────────────────────────────────────────────
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      visible: root.windowVisible
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      anchors.bottom: true
      margins.bottom: 31
      implicitWidth: 292
      implicitHeight: 44

      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(root.cSurface.r, root.cSurface.g, root.cSurface.b, 0.9)
        border.width: 1
        border.color: Qt.rgba(root.cOutline.r, root.cOutline.g, root.cOutline.b, 0.6)

        opacity: root.showing ? 1 : 0
        scale: root.showing ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
          id: icon
          anchors.left: parent.left
          anchors.leftMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          width: 20
          horizontalAlignment: Text.AlignHCenter
          text: root.icon
          color: root.cPrimary
          font.family: "MesloLGS Nerd Font Mono"
          font.pixelSize: root.iconSize
        }

        Text {
          id: pct
          visible: root.showBar
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          width: 56
          horizontalAlignment: Text.AlignRight
          text: root.label
          color: root.cOnSurface
          font.family: "MesloLGS Nerd Font Mono"
          font.pixelSize: 12
        }

        Rectangle {
          visible: root.showBar
          anchors.left: icon.right
          anchors.leftMargin: 14
          anchors.right: pct.left
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          height: 5
          radius: 2.5
          color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.22)

          Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.fraction))
            color: root.cPrimary
            Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
          }
        }

        // Modo sin barra (perfil de energia): etiqueta centrada.
        Text {
          visible: !root.showBar
          anchors.left: icon.right
          anchors.leftMargin: 14
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignHCenter
          text: root.label
          color: root.cOnSurface
          font.family: "MesloLGS Nerd Font Mono"
          font.pixelSize: 12
        }
      }
    }
  }
}
