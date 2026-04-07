import QtQuick 2.15
import QtQuick.Controls 2.15

ToolButton {
    id: control

    implicitWidth: 44
    implicitHeight: 44

    text: "\u2190"

    signal backRequested

    onClicked: backRequested()
    contentItem: Text{
        text:control.text
        color:"#fff"
        font.pixelSize: 40
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignBottom
    }

}
