import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Supplied PNG tiles include a flat outer margin. Display the visible tile at
// the same 56 x 56 size as the navigation button without editing the asset.
IconAction {
    id: control
    property rect imageClipRect: Qt.rect(0, 0, 0, 0)
    implicitWidth: 56
    implicitHeight: 56
    Layout.preferredWidth: 56
    Layout.minimumWidth: 56
    Layout.maximumWidth: 56
    Layout.preferredHeight: 56
    Layout.minimumHeight: 56
    Layout.maximumHeight: 56
    display: AbstractButton.IconOnly
    icon.color: "transparent"
    icon.width: 56
    icon.height: 56
    padding: 0

    contentItem: Image {
        source: control.icon.source
        sourceClipRect: control.imageClipRect
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
