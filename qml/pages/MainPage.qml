import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../components"

Page {
    id: root
    implicitWidth: 360
    signal goHome()
    signal goFriends()
    signal goEat()

    header: ToolBar {
        Label {
            anchors.centerIn: parent
            text: "WeekendsWay"
            font.pixelSize: 18
            font.bold: true
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        padding: 12
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentColumn
            width: scrollView.availableWidth
            spacing: 12

        BigActionButton {
            Layout.fillWidth: true
            text: "Домой"
            subtitle: "Один адрес • открыть маршрут"
            icon.source: "qrc:/icons/home.png"
            onClicked: root.goHome()
        }

        BigActionButton {
            Layout.fillWidth: true
            text: "К друзьям"
            subtitle: "Список • карточка • маршрут"
            icon.source: "qrc:/icons/friends.png"
            onClicked: root.goFriends()
        }

        BigActionButton {
            Layout.fillWidth: true
            text: "Кушать"
            subtitle: "Список мест • открыть маршрут"
            icon.source: "qrc:/icons/eat.png"
            onClicked: root.goEat()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#DDDDDD"
            radius: 1
            opacity: 0.8
        }

        Label {
            Layout.fillWidth: true
            text: "Выбери место — и построй маршрут в пару касаний."
            wrapMode: Text.Wrap
            opacity: 0.75
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
}
