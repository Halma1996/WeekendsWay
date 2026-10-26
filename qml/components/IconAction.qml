import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ToolButton {
    id: control
    property bool filled: false
    property bool destructive: false
    implicitWidth: 48
    implicitHeight: 48
    topInset: 0
    bottomInset: 0
    padding: 10
    font.pixelSize: 24
    Material.foreground: destructive ? Theme.danger
                         : filled && Theme.dark ? Theme.accentText : Theme.accent
    icon.color: Material.foreground
    opacity: enabled ? 1 : 0.4

    background: Rectangle {
        antialiasing: true
        radius: 15
        color: control.destructive ? (control.down ? Theme.dangerPressed : Theme.dangerSurface)
             : control.filled ? (control.down ? Theme.routePressed : Theme.route)
             : control.down ? Theme.secondaryPressed : "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
    }
}
