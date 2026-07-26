import QtQuick
import Quickshell
import Quickshell.Io

// Botones de sesión. dryRun=true solo registra la acción en consola: sirve para
// probar el layout sin apagar el equipo.
Row {
    id: root

    property var pal
    property bool dryRun: true
    property int baseSize: 44

    signal acted(string accion)

    Process { id: runner }

    function ejecutar(accion, cmd) {
        root.acted(accion)
        if (root.dryRun) {
            console.log("[LockSession] dryRun:", accion, "->", cmd.join(" "))
            return
        }
        runner.command = cmd
        runner.running = true
    }

    spacing: 14

    Repeater {
        model: [
            { glifo: "\uf186", nombre: "suspender", cmd: ["systemctl", "suspend"] },
            { glifo: "\uf4d2", nombre: "hibernar",  cmd: ["systemctl", "hibernate"] },
            { glifo: "\uf021", nombre: "reiniciar", cmd: ["systemctl", "reboot"] },
            { glifo: "\uf011", nombre: "apagar",    cmd: ["systemctl", "poweroff"] },
            { glifo: "\uf2f5", nombre: "salir",     cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] }
        ]

        Rectangle {
            required property var modelData
            width: root.baseSize; height: root.baseSize
            radius: width / 2
            color: zona.containsMouse
                 ? (modelData.nombre === "apagar" ? root.pal.mError : root.pal.mPrimary)
                 : root.pal.mSurfaceVariant
            border.width: 1
            border.color: root.pal.mOutline

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: parent.modelData.glifo
                color: zona.containsMouse ? root.pal.mOnPrimary : root.pal.mOnSurface
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 17
            }

            MouseArea {
                id: zona
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.ejecutar(parent.modelData.nombre, parent.modelData.cmd)
            }
        }
    }
}
