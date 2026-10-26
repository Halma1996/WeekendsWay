import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string subtitle: ""
    property string emoji: ""
    property bool purple: false

    implicitHeight: 120
    padding: 18
    topInset: 0
    bottomInset: 0
    Accessible.description: subtitle

    contentItem: RowLayout {
        spacing: 16
        Rectangle {
            Layout.preferredWidth: 74
            Layout.minimumWidth: 74
            Layout.maximumWidth: 74
            Layout.preferredHeight: 74
            Layout.alignment: Qt.AlignVCenter
            radius: 22
            color: "#FFFEFA"
            visible: root.icon.source.toString().length > 0
            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: root.icon.source
                sourceSize: Qt.size(256, 256)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 5
            Label {
                Layout.fillWidth: true
                text: root.text
                color: Theme.dark ? Theme.accentText : Theme.text
                font.pixelSize: 20
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: Theme.dark ? "#E4E8FF" : Theme.muted
                font.pixelSize: 13
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
        Text {
            text: "›"
            color: Theme.dark ? "#D4DCFF" : Theme.accent
            font.pixelSize: 30
            Layout.alignment: Qt.AlignVCenter
            Accessible.ignored: true
        }
    }

    background: Rectangle {
        antialiasing: true
        radius: 24
        border.width: root.visualFocus ? 2 : 1
        border.color: root.visualFocus ? Theme.accent : Theme.dark ? "#5371EB" : "#E8EAFB"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.dark ? (root.purple ? "#7839EB" : "#345FF0")
                                 : root.down ? "#E3E7FB" : "#F0F1FD"
            }
            GradientStop {
                position: 1
                color: Theme.dark ? (root.purple ? "#36158E" : "#132E91")
                                 : root.down ? "#DDE1F7" : "#EDEFFC"
            }
        }
        opacity: root.down && Theme.dark ? 0.8 : 1
    }
}
