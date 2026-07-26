import QtQuick
import Quickshell
import "Modules/Lock"

// Banco de pruebas de la superficie. Bloquea 3s después de arrancar, con el
// botón de emergencia activo.
ShellRoot {
    Lock {
        id: lock
        escapeHatch: true
        Component.onCompleted: armar.start()
        Timer {
            id: armar
            interval: 3000
            onTriggered: lock.lock()
        }
    }
}
