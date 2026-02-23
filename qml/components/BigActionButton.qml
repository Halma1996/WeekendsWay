import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: root
    property string subtitle: ""
    property string emoji: ""

    implicitWidth: 360
    implicitHeight: 84
    font.pixelSize: 20

    contentItem: Item {
        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14
            Image {
                source: root.icon.source
                width: root.icon.width > 0 ? root.icon.width : 24
                height: root.icon.height > 0 ? root.icon.height : 24
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                visible: root.icon.source.toString().length > 0
                anchors.verticalCenter:  parent.verticalCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Label {
                    text: root.text
                    font.pixelSize: 20
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    visible: root.subtitle.length > 0
                    text: root.subtitle
                    font.pixelSize: 14
                    opacity: 0.75
                    elide: Text.ElideRight
                }
            }
        }
    }

    background: Rectangle {
        radius: 14
        color: root.down ? "#E0E0E0" : "#F3F3F3"
        border.color: "#D0D0D0"
    }
}
