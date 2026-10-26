import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Button {
    id: root
    property string subtitle: ""
    property string emoji: ""

    implicitHeight: 110
    font.pixelSize: 20
    padding: 16
    topInset: 0
    bottomInset: 0

    contentItem: RowLayout {
        spacing: 14
        Image {
            source: root.icon.source
            Layout.preferredWidth: 64
            Layout.minimumWidth: 64
            Layout.maximumWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignVCenter
            sourceSize: Qt.size(256, 256)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            visible: root.icon.source.toString().length > 0
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            Label {
                Layout.fillWidth: true
                text: root.text
                font.pixelSize: 20
                font.bold: true
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                font.pixelSize: 14
                opacity: 0.75
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        radius: 14
        color: root.down ? "#E0E0E0" : "#F3F3F3"
        border.color: "#D0D0D0"
    }
}
