import QtQuick
import QtQuick.Controls

ToolBar {
    id: control
    property string title: ""
    property bool backVisible: true
    property bool addVisible: false
    signal backRequested()
    signal addRequested()
    implicitHeight: 68
    background: Rectangle { color: "transparent" }

    ReturnButton {
        visible: control.backVisible
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        onBackRequested: control.backRequested()
    }
    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: control.backVisible ? 64 : 24
        anchors.rightMargin: control.addVisible ? 64 : control.backVisible ? 64 : 24
        anchors.verticalCenter: parent.verticalCenter
        text: control.title
        color: control.backVisible ? Theme.text : Theme.dark ? Theme.text : "#172ABA"
        font.pixelSize: control.backVisible ? 20 : 25
        font.weight: Font.Bold
        horizontalAlignment: control.backVisible ? Text.AlignHCenter : Text.AlignLeft
        elide: Text.ElideRight
    }
    IconAction {
        visible: control.addVisible
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "+"
        font.pixelSize: 30
        Accessible.name: "Добавить"
        onClicked: control.addRequested()
    }
}
