import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

// Fondo: wallpaper de la pantalla + blur + tinte. La ruta sale del estado de
// Noctalia (~/.cache/noctalia/wallpapers.json), que es donde vive el wallpaper
// activo por monitor. Deuda consciente: cuando la barra traiga su propio gestor
// de wallpaper, esta ruta se muda a ~/.config/horus/.
Item {
    id: root

    property var pal
    property string screenName: ""
    property real blurAmount: 0.85
    property real tint: 0.42

    property string wallpaper: ""

    function refresh() {
        try {
            var d = JSON.parse(wpFile.text());
            var w = d.wallpapers ? d.wallpapers[root.screenName] : null;
            var p = w ? (w.dark || w.light) : (d.defaultWallpaper || "");
            if (p) root.wallpaper = p;
        } catch (e) {
            // Sin JSON legible: se queda el color sólido de abajo.
        }
    }

    FileView {
        id: wpFile
        path: Quickshell.env("HOME") + "/.cache/noctalia/wallpapers.json"
        onLoaded: root.refresh()
    }

    // Piso: si no hay wallpaper, esto es todo el fondo.
    Rectangle {
        anchors.fill: parent
        color: root.pal.mSurface
    }

    // El origen no se dibuja: se renderiza a textura y lo pinta MultiEffect.
    Image {
        id: img
        anchors.fill: parent
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: img.status === Image.Ready
        blurEnabled: true
        blur: root.blurAmount
        blurMax: 48
    }

    // Tinte: baja el wallpaper para que el texto tenga contraste.
    Rectangle {
        anchors.fill: parent
        color: root.pal.mSurface
        opacity: img.status === Image.Ready ? root.tint : 0.0
    }
}
