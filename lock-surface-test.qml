import QtQuick
import Quickshell
import "Modules/Lock"

// Banco de pruebas: bloquea 3s tras arrancar, con salida de emergencia y los
// botones de sesión en seco.
ShellRoot {
    Lock {
        id: lock
        escapeHatch: true
        dryRun: true
        Component.onCompleted: armar.start()
        Timer {
            id: armar
            interval: 3000
            onTriggered: lock.lock()
        }
    }
}
