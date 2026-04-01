import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../components"

Page {
    id: root
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

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        BigActionButton {
            Layout.fillWidth: true
            Layout.preferredHeight: contentColumn.height / 6

            text: "Домой"
            subtitle: "Один адрес • открыть маршрут"

            icon.source: "qrc:/icons/home.svg"

            onClicked: root.goHome()
        }

        BigActionButton {
            Layout.fillWidth: true
            Layout.preferredHeight: contentColumn.height / 6

            text: "К друзьям"
            subtitle: "Список • карточка • маршрут"

            icon.source: "qrc:/icons/friends.svg"

            onClicked: root.goFriends()
        }

        BigActionButton {
            Layout.fillWidth: true
            Layout.preferredHeight: contentColumn.height / 6

            text: "Кушать"
            subtitle: "Список мест • открыть маршрут"

            icon.source: "qrc:/icons/eat.svg"

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
            text: "Halma_app: я стараюсь, все будет работать, но это не точно"
            wrapMode: Text.Wrap
            opacity: 0.75
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
