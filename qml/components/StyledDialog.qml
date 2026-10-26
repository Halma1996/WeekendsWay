import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Dialog {
    id: control
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(440, parent ? parent.width - 24 : 440)
    height: Math.min(implicitHeight, parent ? parent.height - 24 : implicitHeight)
    padding: 16
    Material.theme: Theme.dark ? Material.Dark : Material.Light
    Material.accent: Theme.accent
    Material.foreground: Theme.text
    Material.background: Theme.surface

    background: Rectangle {
        antialiasing: true
        radius: 24
        color: Theme.surface
        border.color: Theme.border
    }
    header: Label {
        text: control.title
        color: Theme.text
        font.pixelSize: 21
        font.weight: Font.Bold
        wrapMode: Text.Wrap
        leftPadding: 20
        rightPadding: 20
        topPadding: 22
        bottomPadding: 8
    }
    footer: DialogButtonBox {
        padding: 12
        spacing: 8
        standardButtons: control.standardButtons
        background: Item {}
        delegate: ActionButton {
            tone: DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole ? "primary" : "secondary"
        }
    }
}
