import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string ledPath: "/sys/class/leds/asus::kbd_backlight"

  property int maxValue: 3
  property int value: 0
  property int prevValue: -1
  property color primary: "#8b45f7"
  property bool showing: false
  property bool windowVisible: false

  // Color del tema activo (mismo archivo que alimentaba al wob).
  function refreshColor() {
    var c = colorFile.text().trim().replace("#", "");
    if (/^[0-9a-fA-F]{6}$/.test(c))
      primary = "#" + c;
  }

  onShowingChanged: {
    if (showing) {
      windowVisible = true;
      fadeOutTimer.stop();
    } else {
      fadeOutTimer.restart();
    }
  }

  FileView {
    id: maxFile
    path: root.ledPath + "/max_brightness"
    blockLoadingUntilLoaded: true
    onLoaded: {
      var n = parseInt(text().trim());
      if (!isNaN(n) && n > 0)
        root.maxValue = n;
    }
  }

  FileView {
    id: curFile
    path: root.ledPath + "/brightness"
    printErrors: false
  }

  FileView {
    id: colorFile
    path: root.home + "/.config/horus/kbd-color"
    printErrors: false
    onLoaded: root.refreshColor()
  }

  // sysfs no emite inotify: se sondea. La primera lectura no dispara el OSD.
  Timer {
    interval: 120
    running: true
    repeat: true
    onTriggered: {
      var n = parseInt(curFile.text().trim());
      if (!isNaN(n) && n !== root.value) {
        root.value = n;
        if (root.prevValue >= 0) {
          root.showing = true;
          hideTimer.restart();
        }
        root.prevValue = n;
      }
      curFile.reload();
    }
  }

  Timer { interval: 2000; running: true; repeat: true; onTriggered: colorFile.reload() }
  Timer { id: hideTimer; interval: 1400; onTriggered: root.showing = false }
  Timer { id: fadeOutTimer; interval: 220; onTriggered: root.windowVisible = false }

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
      margins.bottom: 140
      implicitWidth: 340
      implicitHeight: 52

      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#e618092b"
        border.width: 1
        border.color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.35)

        opacity: root.showing ? 1 : 0
        scale: root.showing ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Item {
          id: icon
          width: 20
          height: 20
          anchors.left: parent.left
          anchors.leftMargin: 18
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            radius: 3
            color: "transparent"
            border.width: 1.4
            border.color: root.primary
          }
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 7
            spacing: 2
            Repeater {
              model: 4
              Rectangle { width: 2; height: 2; color: root.primary }
            }
          }
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 7
            width: 9
            height: 2
            color: root.primary
          }
        }

        Text {
          id: pct
          anchors.right: parent.right
          anchors.rightMargin: 18
          anchors.verticalCenter: parent.verticalCenter
          width: 40
          horizontalAlignment: Text.AlignRight
          text: Math.round(root.value / root.maxValue * 100) + "%"
          color: "#b88cf2"
          font.family: "MesloLGS Nerd Font Mono"
          font.pixelSize: 13
        }

        Rectangle {
          anchors.left: icon.right
          anchors.leftMargin: 14
          anchors.right: pct.left
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          height: 6
          radius: 3
          color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.22)

          Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.value / root.maxValue))
            color: root.primary
            Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
          }
        }
      }
    }
  }
}
