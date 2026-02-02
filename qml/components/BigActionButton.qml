import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: root
    property string subtitle: ""
    property string emoji: ""

    implicitHeight: 84
    font.pixelSize: 20

    contentItem: Item {
        anchors.fill: parent
        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Label {
                visible: root.emoji.length > 0
                text: root.emoji
                font.pixelSize: 28
                verticalAlignment: Text.AlignVCenter
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
