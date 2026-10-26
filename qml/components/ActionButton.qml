import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    // These are visual treatments of existing actions, not new action types.
    property string tone: "secondary"
    readonly property bool filled: tone === "primary" || tone === "purple"

    implicitHeight: 52
    font.pixelSize: 15
    font.weight: Font.DemiBold
    padding: 12
    leftPadding: 18
    rightPadding: 18
    topInset: 0
    bottomInset: 0
    Material.foreground: !enabled ? Theme.muted : filled ? Theme.accentText
                         : tone === "danger" ? Theme.danger : Theme.text
    icon.color: Material.foreground
    opacity: enabled ? 1 : 0.75

    background: Rectangle {
        antialiasing: true
        radius: 20
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: !control.enabled ? Theme.disabled : control.tone === "primary" ? (control.down ? "#3158DB" : "#4774FF")
                     : control.tone === "purple" ? (control.down ? "#7432CF" : "#9851FF")
                     : control.tone === "danger" ? (control.down ? Theme.dangerPressed : Theme.dangerSurface)
                     : control.down ? Theme.secondaryPressed : Theme.secondary
            }
            GradientStop {
                position: 1
                color: !control.enabled ? Theme.disabled : control.tone === "primary" ? (control.down ? "#1738BD" : "#2049ED")
                     : control.tone === "purple" ? (control.down ? "#4E1EA8" : "#6525D9")
                     : control.tone === "danger" ? (control.down ? Theme.dangerPressed : Theme.dangerSurface)
                     : control.down ? Theme.secondaryPressed : Theme.secondary
            }
        }
    }
}
