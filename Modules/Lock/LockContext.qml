import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Máquina de estados de autenticación. No sabe nada de ventanas ni de
// WlSessionLock: solo emite unlocked/failed. Eso permite probarla en una
// ventana normal antes de dejarle bloquear la sesión.
Scope {
    id: root

    signal unlocked
    signal failed

    property string currentText: ""
    property bool waitingForPassword: false
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool showInfo: false
    property string errorMessage: ""
    property string infoMessage: ""

    // Arranca PAM al aparecer, para que el prompt ya esté esperando la respuesta
    // cuando el usuario termine de escribir.
    property bool autoStart: true

    Component.onCompleted: if (autoStart) pam.start()

    // Info y error son mutuamente excluyentes.
    onShowInfoChanged: if (showInfo) showFailure = false
    onShowFailureChanged: if (showFailure) showInfo = false

    onCurrentTextChanged: {
        if (currentText !== "") {
            showInfo = false
            showFailure = false
            // Si PAM todavía no pidió la contraseña, la conversación en curso no
            // sirve para este intento: se aborta y tryUnlock arrancará una nueva.
            if (!waitingForPassword)
                pam.abort()
        } else if (autoStart) {
            pam.start()
        }
    }

    function tryUnlock() {
        if (waitingForPassword) {
            pam.respond(currentText)
            unlockInProgress = true
            waitingForPassword = false
            showInfo = false
            return
        }
        pam.start()
    }

    PamContext {
        id: pam
        configDirectory: "/etc/pam.d"
        config: "horus-lock"
        user: Quickshell.env("USER")

        onPamMessage: {
            if (responseRequired) {
                if (root.currentText !== "") {
                    respond(root.currentText)
                    root.unlockInProgress = true
                } else {
                    // PAM pide contraseña antes de que haya uno escrita: se queda
                    // esperando y tryUnlock responderá.
                    root.waitingForPassword = true
                    root.infoMessage = "Contraseña"
                    root.showInfo = true
                }
            } else if (messageIsError) {
                root.errorMessage = message
                root.showFailure = true
            } else {
                root.infoMessage = message
                root.showInfo = true
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.errorMessage = "Autenticación fallida"
                root.showFailure = true
                root.failed()
            }
            root.unlockInProgress = false
        }

        onError: err => {
            root.errorMessage = PamError.toString(err)
            root.showFailure = true
            root.unlockInProgress = false
            root.failed()
        }
    }
}
