import QtQuick
import Quickshell
import Quickshell.Io

// Paleta viva: horus-theme regenera palette.json y esto la reexpone.
// Mismo patrón que el OSD: FileView + reload() sondeado (watchChanges no existe
// en esta versión de quickshell).
Item {
    id: root

    property color mPrimary: "#8b45f7"
    property color mSecondary: "#c44fe6"
    property color mTertiary: "#e85fb0"
    property color mError: "#fb5c7e"
    property color mSurface: "#18092b"
    property color mSurfaceVariant: "#1c0e33"
    property color mOnSurface: "#b88cf2"
    property color mOnSurfaceVariant: "#a784dd"
    property color mOutline: "#5031a0"
    property color mOnPrimary: "#f2e8ff"
    property color mHover: "#4a2a82"
    property color mShadow: "#0d0418"

    function refresh() {
        try {
            var p = JSON.parse(paletteFile.text());
            if (p.mPrimary)          mPrimary          = p.mPrimary;
            if (p.mSecondary)        mSecondary        = p.mSecondary;
            if (p.mTertiary)         mTertiary         = p.mTertiary;
            if (p.mError)            mError            = p.mError;
            if (p.mSurface)          mSurface          = p.mSurface;
            if (p.mSurfaceVariant)   mSurfaceVariant   = p.mSurfaceVariant;
            if (p.mOnSurface)        mOnSurface        = p.mOnSurface;
            if (p.mOnSurfaceVariant) mOnSurfaceVariant = p.mOnSurfaceVariant;
            if (p.mOutline)          mOutline          = p.mOutline;
            if (p.mOnPrimary)        mOnPrimary        = p.mOnPrimary;
            if (p.mHover)            mHover            = p.mHover;
            if (p.mShadow)           mShadow           = p.mShadow;
        } catch (e) {
            // JSON a medio escribir: se conserva la paleta anterior.
        }
    }

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/horus/palette.json"
        onLoaded: root.refresh()
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: paletteFile.reload() }
}
