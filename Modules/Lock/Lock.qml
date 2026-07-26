import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Commons"

// Pantalla de bloqueo. El WlSessionLock vive dentro de un Loader: al desbloquear
// se pone locked=false PRIMERO y la descarga se difiere 250ms, porque destruir la
// superficie antes de que el compositor la suelte deja la pantalla colgada.
Loader {
    id: root
    active: false

    // Botón de emergencia visible. Solo para pruebas: en producción va en false.
    property bool escapeHatch: false

    function lock() { root.active = true }

    Timer {
        id: unloadTimer
        interval: 250
        onTriggered: root.active = false
    }

    sourceComponent: Component {
        Item {
            id: container

            Palette { id: pal }

            LockContext {
                id: ctx
                onUnlocked: {
                    session.locked = false
                    unloadTimer.start()
                    ctx.currentText = ""
                }
                onFailed: ctx.currentText = ""
            }

            WlSessionLock {
                id: session
                locked: root.active

                WlSessionLockSurface {
                    id: surface
                    color: pal.mSurface

                    // Cada superficie necesita su propio input con foco: en
                    // multi-monitor el teclado va a la que tenga el cursor.
                    TextInput {
                        id: input
                        width: 0; height: 0; visible: false
                        enabled: !ctx.unlockInProgress
                        echoMode: TextInput.Password
                        passwordMaskDelay: 0

                        onTextChanged: if (ctx.currentText !== text) ctx.currentText = text
                        Connections {
                            target: ctx
                            function onCurrentTextChanged() {
                                if (input.text !== ctx.currentText)
                                    input.text = ctx.currentText
                            }
                        }
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                ctx.tryUnlock()
                                e.accepted = true
                            }
                        }
                        Component.onCompleted: forceActiveFocus()
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        onEntered: if (!input.activeFocus) input.forceActiveFocus()
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 28
                        width: 420

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.now, "hh:mm")
                            color: pal.mOnSurface
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 84
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.now, "dddd d 'de' MMMM")
                            color: pal.mOnSurfaceVariant
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 15
                        }

                        Rectangle {
                            width: parent.width; height: 46
                            radius: height / 2
                            color: pal.mSurfaceVariant
                            border.width: 2
                            border.color: ctx.showFailure ? pal.mError
                                        : (ctx.unlockInProgress ? pal.mSecondary : pal.mOutline)

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 10
                                visible: ctx.currentText.length > 0

                                Repeater {
                                    model: Math.min(ctx.currentText.length, 16)
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: pal.mPrimary
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: ctx.currentText.length === 0
                                text: "contraseña"
                                color: pal.mOutline
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 13
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: ctx.showFailure ? ctx.errorMessage : ""
                            color: pal.mError
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 12
                        }

                        LockMedia {
                            anchors.horizontalCenter: parent.horizontalCenter
                            pal: pal
                        }

                        LockSession {
                            anchors.horizontalCenter: parent.horizontalCenter
                            pal: pal
                            dryRun: root.escapeHatch
                        }

                        Rectangle {
                            visible: root.escapeHatch
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 200; height: 34; radius: 17
                            color: pal.mError

                            Text {
                                anchors.centerIn: parent
                                text: "SALIDA DE EMERGENCIA"
                                color: pal.mSurface
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    session.locked = false
                                    unloadTimer.start()
                                }
                            }
                        }
                    }

                    Timer {
                        id: clock
                        property date now: new Date()
                        interval: 1000; running: true; repeat: true
                        onTriggered: now = new Date()
                    }
                }
            }
        }
    }
}
