import QtQuick
import Quickshell
import "Modules/Lock"

// Banco de pruebas de LockContext en ventana normal: misma lógica que tendrá el
// lock real, pero cerrable con el ratón.
FloatingWindow {
    id: win
    implicitWidth: 560
    implicitHeight: 300
    color: "#18092b"

    property int intentos: 0
    property int exitos: 0

    LockContext {
        id: ctx
        onUnlocked: {
            win.exitos++
            win.intentos++
            campo.text = ""
        }
        onFailed: {
            win.intentos++
            campo.text = ""
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 14
        width: parent.width - 60

        Text {
            width: parent.width
            font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 12
            color: "#b88cf2"
            text: "waiting=" + ctx.waitingForPassword
                + "  inProgress=" + ctx.unlockInProgress
                + "  intentos=" + win.intentos + "  exitos=" + win.exitos
        }

        Rectangle {
            width: parent.width; height: 40; radius: 8
            color: "#1c0e33"
            border.width: 2
            border.color: ctx.showFailure ? "#fb5c7e"
                        : (campo.activeFocus ? "#8b45f7" : "#4a2a82")

            TextInput {
                id: campo
                anchors.fill: parent; anchors.margins: 12
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordMaskDelay: 0
                enabled: !ctx.unlockInProgress
                color: "#e0d0ff"
                font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 14
                focus: true

                // Sincronía bidireccional a mano: el binding declarativo se rompe
                // al escribir (comprobado por upstream).
                onTextChanged: if (ctx.currentText !== text) ctx.currentText = text
                Connections {
                    target: ctx
                    function onCurrentTextChanged() {
                        if (campo.text !== ctx.currentText)
                            campo.text = ctx.currentText
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
        }

        Text {
            width: parent.width; wrapMode: Text.Wrap
            font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 12
            color: ctx.showFailure ? "#fb5c7e" : "#a784dd"
            text: ctx.showFailure ? ctx.errorMessage
                : (ctx.showInfo ? ctx.infoMessage : "listo")
        }

        Text {
            width: parent.width; wrapMode: Text.Wrap
            font.family: "MesloLGS Nerd Font Mono"; font.pixelSize: 11
            color: win.exitos > 0 ? "#8b45f7" : "#5031a0"
            text: win.exitos > 0
                ? "unlocked() emitido — aquí el lock real llamaría unlock()"
                : "prueba: contraseña mala, luego buena, luego mala otra vez"
        }
    }
}
