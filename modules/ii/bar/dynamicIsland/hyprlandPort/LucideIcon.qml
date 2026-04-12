import QtQuick
import Quickshell

Image {
    id: root

    required property string iconName

    source: Quickshell.shellPath("assets/icons/lucide-" + iconName + ".svg")
    fillMode: Image.PreserveAspectFit
    sourceSize: Qt.size(Math.max(1, Math.round(width * 2)), Math.max(1, Math.round(height * 2)))
    smooth: true
    mipmap: true
}
