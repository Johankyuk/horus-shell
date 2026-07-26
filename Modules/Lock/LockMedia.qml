import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Controles de música. Se oculta solo si no hay reproductor activo.
Item {
    id: root

    property var pal

    // El singleton expone una lista de objetos; se toma el primero que reproduzca,
    // y si ninguno reproduce, el primero que exista.
    readonly property var lista: {
        const p = Mpris.players
        if (!p) return []
        return p.values !== undefined ? p.values : p
    }
    readonly property var player: {
        const l = root.lista
        if (!l || l.length === 0) return null
        for (var i = 0; i < l.length; i++)
            if (l[i].isPlaying) return l[i]
        return l[0]
    }

    visible: player !== null
    implicitHeight: visible ? fila.implicitHeight : 0
    implicitWidth: 420

    Row {
        id: fila
        anchors.centerIn: parent
        spacing: 14

        Rectangle {
            width: 54; height: 54; radius: 8
            color: root.pal.mSurfaceVariant
            clip: true

            Image {
                anchors.fill: parent
                source: root.player ? (root.player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !parent.children[0].visible
                text: "\uf001"
                color: root.pal.mOutline
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 20
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            width: 220

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.player ? (root.player.trackTitle || "—") : ""
                color: root.pal.mOnSurface
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 13
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.player ? (root.player.trackArtist || "") : ""
                color: root.pal.mOnSurfaceVariant
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 11
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: [
                    { glifo: "\uf048", accion: "prev" },
                    { glifo: "",       accion: "toggle" },
                    { glifo: "\uf051", accion: "next" }
                ]

                Rectangle {
                    required property var modelData
                    width: 32; height: 32; radius: 16
                    color: zonaM.containsMouse ? root.pal.mPrimary : "transparent"
                    border.width: 1
                    border.color: root.pal.mOutline
                    opacity: habilitado ? 1.0 : 0.35

                    readonly property bool habilitado: {
                        if (!root.player) return false
                        if (modelData.accion === "prev")   return root.player.canGoPrevious
                        if (modelData.accion === "next")   return root.player.canGoNext
                        return root.player.canTogglePlaying
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.accion === "toggle"
                            ? (root.player && root.player.isPlaying ? "\uf04c" : "\uf04b")
                            : parent.modelData.glifo
                        color: zonaM.containsMouse ? root.pal.mOnPrimary : root.pal.mOnSurface
                        font.family: "MesloLGS Nerd Font Mono"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: zonaM
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: parent.habilitado
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.player) return
                            if (parent.modelData.accion === "prev") root.player.previous()
                            else if (parent.modelData.accion === "next") root.player.next()
                            else root.player.togglePlaying()
                        }
                    }
                }
            }
        }
    }
}
